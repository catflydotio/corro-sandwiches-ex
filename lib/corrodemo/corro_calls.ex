defmodule Corrodemo.CorroCalls do
  import Corrodemo.FlyDnsReq
  require Logger

  # e.g. Corrodemo.CorroCalls.corro_request("query","SELECT foo FROM TESTS")
  def corro_request(path, statement) do
    Corrodemo.FlyDnsReq.get_corro_instance()
    corro_db_url = "#{Application.fetch_env!(:corrodemo, :corro_baseurl)}/v1/"
    with {:ok, %Finch.Response{status: status_code, body: body, headers: headers}} <- Finch.build(:post,"#{corro_db_url}#{path}",[{"content-type", "application/json"}],Jason.encode!(statement))
      |> Finch.request(Corrodemo.Finch) do
        case status_code do
          200 -> extract_results(body)
          404 -> IO.inspect("got a 404")
          422 -> IO.puts("got a 422 -- check syntax and json formatting")
          unexpected_response -> inspect(unexpected_response) |> IO.inspect(label: "got a non-200, non-404 error code")
        end
    else
      {:ok, response} -> IO.inspect(response, label: "Got an unexpected response in query_corro")
      {:error, resp} -> {:error, resp}
      another_response -> inspect(another_response) |> IO.inspect(label: "corro_request: response has an unexpected format")
    end
  end

  def execute_corro(statement) do
    corro_request("transactions", statement)
  end

  def query_corro(statement) do
    corro_request("queries", statement)
  end

  defp extract_results(body) do
    # %{body: "{\"results\":[{\"rows_affected\":0,\"time\":0.00008258}],\"time\":0.000364641}", headers: [{"content-type", "application/json"}, {"content-length", "70"}, {"date", "Fri, 14 Jul 2023 22:00:35 GMT"}], status_code: 200}
    # IO.inspect(Jason.decode(body))
    with {:ok, %{"results" => [resultsmap],"time" => time}} <- Jason.decode(body) do
    inspect(resultsmap) |> IO.inspect(lanel: "in corrosion calls. resultsmap")
    {:ok, resultsmap}
    end
  end

  def start_watch(statement) do
    DynamicSupervisor.start_child(Corrodemo.WatchSupervisor, {Corrodemo.CorroWatch,statement})
  end

end
