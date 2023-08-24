defmodule Corrodemo.CorroCalls do
  require Logger

  # e.g. Corrodemo.CorroCalls.corro_request("query","SELECT foo FROM TESTS")
  def corro_request(path, statement) do
    Corrodemo.FlyDnsReq.get_corro_instance()
    corro_db_url = "#{Application.fetch_env!(:corrodemo, :corro_baseurl)}/v1/"
    with {:ok, %Finch.Response{status: status_code, body: body, headers: headers}} <- Finch.build(:post, "#{corro_db_url}#{path}",[{"content-type", "application/json"}], Jason.encode!(statement))
      |> Finch.request(Corrodemo.Finch) do
        extract_results(%{status: status_code, body: body, headers: headers})
    else
      {:ok, response} -> IO.inspect(response, label: "Got an unexpected response in query_corro")
      {:error, resp} -> {:error, resp}
      another_response -> inspect(another_response) |> IO.inspect(label: "corro_request: response has an unexpected format")
    end
  end

  def execute_corro(transactions) do
    corro_request("transactions", transactions)
  end

  def query_corro(statement) do
    corro_request("queries", statement)
  end

  @doc """
  This function gets a map from corro_request/2 with status
  """
  defp extract_results(response=%{status: status_code, body: body, headers: headers}) do
    # %{body: "{\"results\":[{\"rows_affected\":0,\"time\":0.00008258}],\"time\":0.000364641}", headers: [{"content-type", "application/json"}, {"content-length", "70"}, {"date", "Fri, 14 Jul 2023 22:00:35 GMT"}], status_code: 200}
    # IO.inspect(Jason.decode(body))

    IO.puts("So far we have a response map")

    bodylist = body |> String.split("\n", trim: true)
    |> IO.inspect(label: "!!88888 OOOOO !!!")
    |> Enum.map(fn x -> Jason.decode!(x, []) end)
    IO.inspect(bodylist, label: "NWO LOOOK")
      # Sometimes the body is a single JSON thing you can decode.
      # Sometimes it's more than one, separated by \n.
    #   # The most general thing to return would be that list.
    #   |> IO.inspect(label: "body")
    #   |> String.split("\n", trim: true)
    #   #
    #   # |> IO.inspect(label: "split string")
    #   |> Enum.each(fn str ->
    #     Jason.decode!(str)
    #     |> IO.inspect(label: "a decoded str")
    #     end)



    # with {:ok, %{"results" => [resultsmap],"time" => _time}} <- Jason.decode(body) do
    # inspect(resultsmap)
    # |> IO.inspect(label: "*** in corrosion calls. resultsmap")
    # {:ok, resultsmap}
    # end
  end

  def start_watch(statement) do
    DynamicSupervisor.start_child(Corrodemo.WatchSupervisor, {Corrodemo.CorroWatch,statement})
  end

end
