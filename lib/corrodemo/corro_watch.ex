defmodule Corrodemo.CorroWatch do
  @moduledoc false
  require Logger

  def start_watch(sql) do
    IO.inspect(sql, label: "In start_watch. sql is")
    path = "/v1/watches"
    json_sql = Jason.encode!(sql)
    stream(path, json_sql, %{}, fn
      region, sandwich, :watched_sandwich_update, acc ->
        IO.inspect("New sandwich in #{region}: #{sandwich}")
        # do something with these and return the accumulator
        Phoenix.PubSub.broadcast(Corrodemo.PubSub, "fromcorro", {:fromcorro, %{region: region, sandwich: sandwich}})
        acc
    end)
  end

  def stream(path, json_sql, acc, caller_acc) do
        # this function has to take the following options because it's being used as the
    # :finch_request option in Req.post!
    # https://hexdocs.pm/req/Req.Steps.html#run_finch/1-request-options
    finch_fun = fn request, finch_req, finch_name, finch_opts ->
      finch_acc = fn #the stream/1 accumulator function
        {:status, status}, response ->
          IO.inspect(response, label: "response")
          %Req.Response{response | status: status}
        {:headers, headers}, response ->
          # IO.inspect(headers, label: "headers")
          %Req.Response{response | headers: headers}
        {:data, data}, response ->
          #IO.inspect(data, label: "data")
          query_answered = false
          data
          |> String.split("\n", trim: true)
          # |> IO.inspect(label: "split string")
          |> Enum.each(fn str ->
            Jason.decode!(str)
            # |> IO.inspect(label: "stuff")
            |> case do
              %{"event" => "end_of_query"}
                -> query_answered = true
                IO.puts("end of query")
              %{"data" => %{"cells" => [region, sandwich], "change_type" => change_type, "rowid" => rowid}}
                -> caller_acc.(region, sandwich, :watched_sandwich_update, acc)
              %{"data" => [head | tail], "event" => id_kind} when query_answered == false
                -> IO.inspect("Watching changes in #{id_kind}: #{[head | tail]}") # could write this list nicely
              :ok -> IO.puts("got :ok from finch_acc")
              _ -> IO.puts("got something I didn't plan for in streaming response")
            end
          end)

          response

            # IO.inspect(stuff, label: "stuff in finch_acc")
            # if it gets "end_of_query" it puts that into caller_acc along with acc. If it gets json, it decodes that and passes the result and acc into caller_acc.
            # |> Enum.reduce(acc, fn
            #   #  data: "{\"event\":\"end_of_query\"}\n"
            #   "end_of_query", acc -> caller_acc.(:end_of_query, acc)
            #   json_str, acc -> caller_acc.(json_str, acc)
            # end)
      end

      # https://hexdocs.pm/finch/Finch.html#stream/5
      # stream(Finch.Request.t(), name(), acc, stream(acc), keyword())
      # So resp is the accumulator and finch_acc is the stream/1 accumulator
      case Finch.stream(finch_req, finch_name, Req.Response.new(), finch_acc, [finch_opts, receive_timeout: :infinity]) do
        {:ok, response} -> IO.inspect(response, label: "Finch.stream got an {:ok, response} tuple. response:")
          {request, response}
        {:error, exception} -> {request, exception}
      end
    end

    Req.post!(url(path), headers: [{"content-type", "application/json"}], body: json_sql, connect_options: [transport_opts: [inet6: true]], finch_request: finch_fun)
  end

  @doc """
  Returns the full configured URL given the API path.
  """
  def url(path) do
    base = Application.fetch_env!(:corrodemo, :corro_baseurl)
    Path.join(base, path) |> IO.inspect(label: "in url(path)")
  end

  @doc """
  The `fun` argument to Finch.stream/5
  """

end
