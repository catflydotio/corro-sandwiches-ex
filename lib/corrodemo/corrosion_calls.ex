defmodule Corrodemo.CorroCalls do
  require Logger

  # e.g. Corrodemo.CorroCalls.corro_request("query","SELECT foo FROM TESTS")
  def corro_request(path, statement) do
    corro_db_url = "#{System.get_env("CORRO_BASEURL")}/db/"
    with {:ok, resp} <- Finch.build(:post,"#{corro_db_url}#{path}",[{"content-type", "application/json"}],Jason.encode!(statement))
      |> Finch.request(Corrodemo.Finch) do
        {:ok, %{status_code: resp.status, body: resp.body, headers: resp.headers}}
        # {:error, resp} -> {:error, resp}
    end
  end

  def execute_corro(statement) do
    with {:ok, %{body: body, headers: headers, status_code: 200}} <- corro_request("execute", statement),
      {:ok, results} <- extract_results(body) do
          {:ok, results}
    end
  end

  def query_corro(statement) do
    with {:ok, %{body: body, headers: headers, status_code: 200}} <- corro_request("query", statement),
      {:ok, results} <- extract_results(body) do
          {:ok, results}
    end
  end

  defp extract_results(body) do
    results = body
    |> Jason.decode!()
    |> Map.get("results",[])
    |> List.first()
    |> IO.inspect()
    {:ok, results}
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
    execute_corro(statement)
    # case corro_request("execute", statement) do
    #   {:ok, somestuffback} -> {:ok, somestuffback}
    #   IO.puts("Uploaded sandwich to corrosion")
    #   {:error, somestuffback} -> inspect(somestuffback) |> Logger.debug()
    # # {:error, %{reason: %Mint.TransportError{reason: :timeout}}}
    # end
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
