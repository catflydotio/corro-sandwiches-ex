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

  @doc """
    Make sure there's a base url set for corrosion
  """
  def check_corro_url() do
      corro_baseurl = Application.fetch_env!(:corrodemo, :corro_baseurl) |> IO.inspect(label: ":corro_baseurl env")
      cond do
        corro_baseurl -> {:ok, []}
              # {:error, resp} -> {:error, resp}
        true -> {:error, "Looks like CORRO_BASEURL isn't set"}
      end
  end

  @doc """
    If we're not using Corrosion on the same node (VM or physical host not in a VM),
    make sure there's a Corrosion Fly.io app specified
    for corrosion
  """
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
