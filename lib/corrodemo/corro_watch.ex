defmodule Corrodemo.CorroWatch do
  @moduledoc false
  require Logger

  def start_watch(sql) do
    IO.inspect(sql, label: "In start_watch. sql = ")
    path = "/v1/watches"
    json_sql = Jason.encode!(sql)
    stream(path, json_sql, %{}, fn
      :end_of_query, acc ->
        # do something with end of query
        IO.puts("got end_of_query")
        acc

      json, acc ->
        inspect(json) |> IO.inspect(label: "json back in caller_acc")
        # do something with decoded json
        acc
    end)
  end

  def stream(path, json_sql, acc, caller_acc) do
        # this function has to take the following options because it's being used as the
    # :finch_request option in Req.post!
    # https://hexdocs.pm/req/Req.Steps.html#run_finch/1-request-options
    finch_fun = fn request, finch_req, finch_name, finch_opts ->
      # IO.puts("in stream finch_fun")
      # IO.inspect(finch_req, label: "finch_req")
      # IO.inspect(finch_name, label: "finch_name")
      IO.inspect(finch_opts, label: "finch_opts")
      finch_acc = fn #the stream/1 accumulator
      # When it gets a tuple starting with :status, it replaces status in response with the new value
      {:status, status}, response ->
        IO.puts("in finch_fun got something back! (status)")
        IO.inspect(status)
        %Req.Response{response | status: status}
      # When it gets a tuple starting with :headers, it replaces headers in response with the new value
        {:headers, headers}, response ->
          IO.puts("in finch_fun got something back! (headers)")
          IO.inspect(headers)
          %Req.Response{response | headers: headers}
      # When it gets a tuple starting with :data, it does an Enum.reduce to call the caller_acc fn
        {:data, data}, response ->
          IO.puts("in finch_fun got something back! (data)")
          # Looks like there are too many quotes and too many escapes in this data
          #inspect(data) |> IO.inspect()
          IO.inspect(data, label: "data")
          IO.puts("that was the end of that data")
          acc = Req.Response.get_private(response, :lfsc_acc)
          new_acc =
            data
            |> String.split("\n", trim: true)
            # if it gets "end_of_query" it puts that into caller_acc along with acc. If it gets json,
            # it decodes that first and passes the result and acc into caller_acc.
            |> Enum.reduce(acc, fn
              "end_of_query", acc -> caller_acc.(:end_of_query, acc)
              json_str, acc -> inspect(json_str) |> IO.inspect(label: "in Enum.reduce")
                caller_acc.(Jason.decode!(json_str), acc)
            end)
          Req.Response.put_private(response, :lfsc_acc, new_acc)
        _, _response ->
          IO.puts("got something different back in finch_acc")
      end

      resp = Req.Response.new() |> Req.Response.put_private(:lfsc_acc, acc)

      # https://hexdocs.pm/finch/Finch.html#stream/5
      # stream(Finch.Request.t(), name(), acc, stream(acc), keyword())
      # So resp is the accumulator and finch_acc is the stream/1 accumulator
      case Finch.stream(finch_req, finch_name, resp, finch_acc, [finch_opts, receive_timeout: :infinity]) do
        {:ok, response} -> {request, response}
        {:error, exception} -> {request, exception}
      end
    end

    # corro_url = Application.fetch_env!(:corrodemo, :corro_baseurl)
    # Finch.build(:post,"#{corro_url}#{path}",[{"content-type", "application/json"}], json_sql)
    # |> IO.inspect(label: "request")
    # |> Finch.request(Corrodemo.Finch)
    # |> IO.inspect()
    # path
    # |> url()
    # |> IO.inspect(label: "in stream, url")
    Req.post!(url(path), headers: [{"content-type", "application/json"}], body: json_sql, connect_options: [transport_opts: [inet6: true]], finch_request: finch_fun)
  end

  @doc """
  Returns the full configured URL given the API path.
  """
  def url(path) do
    base = Application.fetch_env!(:corrodemo, :corro_baseurl)
    Path.join(base, path) |> IO.inspect(label: "in url(path)")
  end



end
