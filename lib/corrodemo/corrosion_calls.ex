defmodule Corrodemo.CorroCalls do
  import Corrodemo.FlyDnsReq
  require Logger

  # e.g. Corrodemo.CorroCalls.corro_request("query","SELECT foo FROM TESTS")
  def corro_request(path, statement) do
    Corrodemo.FlyDnsReq.get_corro_instance()
    corro_db_url = "#{System.get_env("CORRO_BASEURL")}/v1/"
    with {:ok, %Finch.Response{status: status_code, body: body, headers: headers}} <- Finch.build(:post,"#{corro_db_url}#{path}",[{"content-type", "application/json"}],Jason.encode!(statement))
      |> Finch.request(Corrodemo.Finch) do
        {:ok, %{status_code: status_code, body: body, headers: headers}}
      else
        {:error, resp} -> {:error, resp}
        another_response -> IO.puts("corro_request: response has an unexpected format")
          inspect(another_response) |> IO.inspect(label: "Got response")
    end
  end


  def execute_corro(statement) do
    with {:ok, response} <- corro_request("transactions", statement) do
      # IO.puts("got an ok, response from corro_request")
      # inspect(response) |> IO.inspect(label: "the response")
      # IO.inspect(Map.get(response, :status_code), label: "status_code")
      case response[:status_code] do
        200 ->
          # inspect(response[:body]) |> IO.inspect()
          extract_results(response[:body])
        404 -> IO.inspect("got a 404")
        unexpected_response -> IO.inspect(unexpected_response, label: "in execute_corro else clause")
      end
    end
  end

  def query_corro(statement) do
    with {:ok, %{body: body, headers: headers, status_code: 200}} <- corro_request("query", statement),
      {:ok, results} <- extract_results(body) do
          {:ok, results}
    end
  end

  defp extract_results(body) do
    # %{body: "{\"results\":[{\"rows_affected\":0,\"time\":0.00008258}],\"time\":0.000364641}", headers: [{"content-type", "application/json"}, {"content-length", "70"}, {"date", "Fri, 14 Jul 2023 22:00:35 GMT"}], status_code: 200}
    # IO.puts("inside extract_results")
    # IO.inspect(Jason.decode(body))
    with {:ok, %{"results" => [resultsmap],"time" => time}} <- Jason.decode(body) do
    {:ok, resultsmap}
    end
    # IO.inspect("above: extract_results work so far")
  end

  def init_region_sandwich(region) do
    statement = ["INSERT OR IGNORE INTO sw (pk, sandwich) VALUES (\"#{region}\", \"empty\")"]
    # IO.inspect(statement)
    execute_corro(statement)
  end

  # "UPDATE tests SET foo = \"boffo\" WHERE id = 1021"
  def upload_region_sandwich(region, sandwich) do
    statement = ["UPDATE sw SET sandwich = \"#{sandwich}\" WHERE pk = \"#{region}\""]
    IO.inspect(statement)
    execute_corro(statement)
  end

  def get_region_sandwich(region) do
    statement = ["SELECT sandwich FROM sw WHERE pk = \"#{region}\""]
    query_corro(statement)
  end

  # def extract_query_results(body) do
  #   # this function may not work right but queries are going to change anyway...
  #   results = body
  #   |> Map.get("values",[])
  #   |> List.first() # this may be unnecessarily clunky? idk!
  #   |> List.first()
  #   |> IO.inspect()
  # end

  def get_sandwich_table() do
    statement = ["SELECT * FROM sw"]
    corro_request("query", statement)
    |> IO.inspect()
  end

# def format_value(body) do
  # body |> IO.inspect()
  # |> Jason.decode!()
  # |> Map.get("results",[])
  # |> List.first() # this may be unnecessarily clunky? idk!
  # |> Map.get("values",[])
  # |> List.first() # this may be unnecessarily clunky? idk!
  # |> List.first() # this may be unnecessarily clunky? idk!
  # |> IO.inspect()
  # end
end
