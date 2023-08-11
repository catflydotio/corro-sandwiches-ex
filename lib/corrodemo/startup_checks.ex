defmodule Corrodemo.StartupChecks do

  def do_corro_checks() do
    with {:ok, []} <- check_corro_url(),
    {:ok, []} <- check_corro_app()
    do
      {:ok, []}
    else
      _ -> {:error, {check_corro_url(), check_corro_app()}}
    end
  end

  @doc """
    Make sure there's a base url set for corrosion
  """
  def check_corro_url() do
      corro_baseurl = Application.fetch_env!(:corrodemo, :corro_baseurl)
      IO.inspect(corro_baseurl, label: "corro_baseurl env")
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
      IO.puts("I'm inside check_corro_app")
      corro_app = Application.fetch_env!(:corrodemo, :fly_corrosion_app)
      cond do
        corro_app -> {:ok, []}
              # {:error, resp} -> {:error, resp}
        true -> {:error, "Looks like FLY_CORROSION_APP isn't set"}
      end
    end
    {:ok, []}
  end

end
