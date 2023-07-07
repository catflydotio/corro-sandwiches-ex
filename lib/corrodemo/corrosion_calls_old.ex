defmodule Corrodemo.CorroCallsOld do
  require Logger


  # Corrosion wants JSON, Finch wants, I think, a list.
  # Example:
  # iex(85)> Corrodemo.CorroCalls.format_statement("SELECT * FROM TESTS")
  # "[\"SELECT * FROM TESTS\"]"
  def format_statement(statement) do
    "[\"" <> statement <> "\"]"
  end

  # e.g. Corrodemo.CorroCalls.corro_request("query","SELECT foo FROM TESTS")
  def corro_request(path, statement) do
    corro_baseurl = System.get_env("CORRO_BASEURL")
    cond do
      String.length(corro_baseurl) > 0 ->
        corro_db_url = "#{corro_baseurl}/db/"
        # IO.inspect("About to inspect corro db url")
        # IO.inspect(corro_db_url)
        with {:ok, resp} <- Finch.build(:post,"#{corro_db_url}#{path}",[{"content-type", "application/json"}],Jason.encode!(statement)) |> IO.inspect()
        |> Finch.request(Corrodemo.Finch) do
          {:ok, %{status_code: resp.status, results: extract_results(resp.body), headers: resp.headers}}
        end
      String.length(corro_baseurl) == 0 -> {:error, "Looks like CORRO_BASEURL isn't set"}
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
    |> IO.inspect()
  end

  # "UPDATE tests SET foo = \"boffo\" WHERE id = 1021"
  def upload_region_sandwich(region, sandwich) do
    statement = ["UPDATE sw SET sandwich = \"#{sandwich}\" WHERE pk = \"#{region}\""]
    case corro_request("execute", statement) do
      {:ok, somestuffback} -> {:ok, somestuffback}
      IO.puts("Uploaded sandwich to corrosion")
      {:error, somestuffback} -> inspect(somestuffback) |> Logger.debug()
    # {:error, %{reason: %Mint.TransportError{reason: :timeout}}}
    end
  end

  def init_region_sandwich(region) do
    statement = ["INSERT OR IGNORE INTO sw (pk, sandwich) VALUES (\"#{region}\", \"empty\")"]
    # IO.inspect(statement)
    case corro_request("execute", statement) do
      {:ok, somestuffback} -> inspect(somestuffback) |> Logger.debug()
      {:ok} ->{:ok, []}
    end
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
