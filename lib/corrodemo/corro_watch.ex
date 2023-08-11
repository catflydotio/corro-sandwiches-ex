defmodule Corrodemo.CorroWatch do
  @moduledoc """
  Watch/subscribe to changes in the results of a given query.

  This module gets started as a child of the dynamic supervisor
  Corrodemo.WatchSupervisor.
  """

  use GenServer
  require Logger

  def start_link(statement) do
    # This is the function that gets run by the supervisor when I run the server
    GenServer.start_link(Corrodemo.CorroWatch, statement)
  end

  def init(statement) do
    Process.send(self(), {:start_watcher, statement}, [])
    {:ok, statement}
  end

  def handle_info({:start_watcher, statement}, _opts) do
    do_watch(statement) #"SELECT sandwich FROM sw WHERE pk='mad'"
    IO.puts("Started watch")
    {:noreply, []}
  end

  # def handle_call(:set_watch_id, state) do
  #   {:reply, }

  # end

  def do_watch(sql) do
    IO.inspect(sql, label: "In do_watch. sql is")
    path = "/v1/watches"
    json_sql = Jason.encode!(sql)
    stream(path, json_sql, %{}, fn
      resp_data, :resp_data, acc ->
        # do something with response data and return the accumulator:
        watch_actions(resp_data)
        acc
    end)
    {:ok, []}
  end

  def watch_actions(resp_data) do
    # could still factor out some general corrosion stuff from specific sandwich stuff
    resp_data
    |> case do
      %{"event" => "end_of_query"}
        -> IO.puts("end of query")
      %{"data" => %{"cells" => [region, sandwich], "change_type" => _change_type, "rowid" => _rowid}}
        ->
        # IO.inspect("New sandwich in #{region}: #{sandwich}")
        Phoenix.PubSub.broadcast(Corrodemo.PubSub, "fromcorro", {:fromcorro, %{region: region, sandwich: sandwich}})
      # At this point in the possibilities, if "data" is a list, Corrosion is telling us
      # if the ids are rows or columns
      %{"data" => [head | tail], "event" => id_kind}
        -> IO.inspect("Watching changes in #{id_kind}: #{[head | tail]}") # could write this list nicely
      :ok -> IO.puts("got :ok from finch_acc")
      _ -> IO.puts("got something I didn't plan for in streaming response")
    end
  end

  @doc """
  Function to run Req.post!/2 with a streaming function in place
  of the default request/response one for the :finch_request option.

  https://hexdocs.pm/req/Req.Steps.html#run_finch/1-request-options

  This function, stream/4, calls Req.post!/2
    which calls finch_fun/4
      which calls Finch.stream/5
        which uses finch_acc as its stream/1 accumulator function
          which is what passes stuff to the function passed as its
          caller_acc argument to do something with
  """
  def stream(path, json_sql, acc, caller_acc) do
    # this function has to take the following options because it's being used as the
    # :finch_request option in Req.post!/2
    finch_fun = fn request, finch_req, finch_name, finch_opts ->
      finch_acc = fn #the stream/1 accumulator function
        {:status, status}, response ->
          # IO.inspect(response, label: "response")
          %Req.Response{response | status: status}
        {:headers, headers}, response ->
          # IO.inspect(response, label: "response")
          IO.inspect(headers, label: "headers")
          %Req.Response{response | headers: headers}
        {:data, data}, response ->
          IO.inspect(response, label: "response")
          # IO.inspect(data, label: "data")
          data
          |> String.split("\n", trim: true)
          # |> IO.inspect(label: "split string")
          |> Enum.each(fn str ->
            Jason.decode!(str)
            # |> IO.inspect(label: "stuff")
            |> caller_acc.(:resp_data, acc)
          end)
          response
      end

      # https://hexdocs.pm/finch/Finch.html#stream/5
      # stream(Finch.Request.t(), name(), acc, stream(acc), keyword())
      # So resp is the accumulator and finch_acc is the stream/1 accumulator
      case Finch.stream(finch_req, finch_name, Req.Response.new(), finch_acc, [finch_opts, receive_timeout: :infinity]) do
        {:ok, response} -> IO.inspect(response, label: "Finch.stream got an {:ok, response} tuple. response:")
          {request, response}
        {:error, exception} -> inspect(exception)
        |> IO.inspect(label: "Finch.stream got an exception")
          {request, exception}
      end
    end

    post_stream_req(path, finch_fun, json_sql)

  end

  @doc """
  Returns the full configured URL given the API path.
  """
  defp url(path) do
    base = Application.fetch_env!(:corrodemo, :corro_baseurl)
    IO.inspect(Path.join(base, path), label: "corrosion watch url")
    Path.join(base, path)
  end

  @doc """
  Make the Req streaming request
  """
  def post_stream_req(path, finch_fun, json_sql) do
    Req.post!(url(path), headers: [{"content-type", "application/json"}], body: json_sql, connect_options: [transport_opts: [inet6: true]], finch_request: finch_fun)
  end



end
