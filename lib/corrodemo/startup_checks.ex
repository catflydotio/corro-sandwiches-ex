defmodule Corrodemo.StartupChecks do
  use GenServer
  require Logger

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, [])
  end


  def init(_opts) do
    with {:ok, []} <- check_corro_url(),
    {:ok, []} <- check_corro_app()
     do
      {:ok, []}
    end
  end

  def check_corro_url() do
      corro_baseurl = System.get_env("CORRO_BASEURL") |> IO.inspect()
      cond do
        corro_baseurl -> {:ok, []}
              # {:error, resp} -> {:error, resp}
        true -> {:error, "Looks like CORRO_BASEURL isn't set"}
      end
  end

  def check_corro_app() do
    unless System.get_env("CORRO_BUILTIN") == "1" do
      corro_app = System.get_env("FLY_CORROSION_APP") |> IO.inspect()
      cond do
        corro_app -> {:ok, []}
              # {:error, resp} -> {:error, resp}
        true -> {:error, "Looks like FLY_CORROSION_APP isn't set"}
      end
    end
  end

end
