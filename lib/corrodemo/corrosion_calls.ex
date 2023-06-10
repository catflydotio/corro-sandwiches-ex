defmodule Corrodemo.CorroCalls do

  # set base_url as a module attribute (available throughout the module)
  # @corro_db_url "http://localhost:8080/db/"
  @corro_db_url "http://#{System.get_env("CORRO_BASEURL")}:8080/db/"

  # Corrosion wants JSON, Finch wants, I think, a list.
  # Example:
  # iex(85)> Corrodemo.CorroCalls.format_statement("SELECT * FROM TESTS")
  # "[\"SELECT * FROM TESTS\"]"
  def format_statement(statement) do
    "[\"" <> statement <> "\"]"
  end

  # e.g. Corrodemo.CorroCalls.corro_request("query","SELECT foo FROM TESTS")
  def corro_request(path, statement) do
    IO.inspect(@corro_db_url)
    with {:ok, resp} <- Finch.build(:post,"#{@corro_db_url}#{path}",[{"content-type", "application/json"}],Jason.encode!(statement))
    |> Finch.request(Corrodemo.Finch) do
      {:ok, %{status_code: resp.status, results: extract_results(resp.body), headers: resp.headers}}
    else
      {:error, reason} -> {:error, %{reason: reason}}
    end
  end

  def extract_results(body) do
    something = body
    |> Jason.decode!()
    |> Map.get("results",[])
    |> List.first()

    # IO.inspect(something)
    # IO.inspect("above: extract_results work so far")
  end


  def get_region_sandwich(region) do
    statement = ["SELECT sandwich FROM sw WHERE pk = \"#{region}\""]
    {:ok, somestuffback} = corro_request("query", statement)
    somestuffback.results
    |> Map.get("values",[])
    |> List.first() # this may be unnecessarily clunky? idk!
    |> List.first()
    # |> IO.inspect()
  end

  # "UPDATE tests SET foo = \"boffo\" WHERE id = 1021"
  def upload_region_sandwich(region, sandwich) do
    statement = ["UPDATE sw SET sandwich = \"#{sandwich}\" WHERE pk = \"#{region}\""]
    {:ok, somestuffback} = corro_request("execute", statement)
  end

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
