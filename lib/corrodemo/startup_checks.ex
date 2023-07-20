defmodule Corrodemo.StartupChecks do
  use GenServer
  require Logger
  import Corrodemo.CorroWatch

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
      corro_baseurl = Application.fetch_env!(:corrodemo, :corro_baseurl) |> IO.inspect(label: ":corro_baseurl env")
      cond do
        corro_baseurl -> {:ok, []}
              # {:error, resp} -> {:error, resp}
        true -> {:error, "Looks like CORRO_BASEURL isn't set"}
      end
  end

  def check_corro_app() do
    unless Application.fetch_env!(:corrodemo, :corro_builtin) == "1" do
      corro_app = Application.fetch_env!(:corrodemo, :fly_corrosion_app) |> IO.inspect()
      cond do
        corro_app -> {:ok, []}
              # {:error, resp} -> {:error, resp}
        true -> {:error, "Looks like FLY_CORROSION_APP isn't set"}
      end
    end
  end

end
