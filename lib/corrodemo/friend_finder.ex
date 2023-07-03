defmodule Corrodemo.FriendFinder do
  use GenServer

  # @name __MODULE__

  def start_link(_opts \\ []) do
    GenServer.start_link(Corrodemo.FriendFinder, [])
  end

  def broadcast_regions do
    Process.send_after(self(), :broadcast_regions, 20000)
  end

  def init(_opts) do
    broadcast_regions()
    {:ok, []}
  end

  def handle_info(:broadcast_regions, state) do
    {:ok, other_regions} = check_regions()
    #IO.inspect(IEx.Info.info(other_regions))
    Phoenix.PubSub.broadcast(Corrodemo.PubSub, "friend_regions", {:other_regions, other_regions})
    unless System.get_env("CORRO_BUILTIN") == "1" do
      IO.puts("Checking corrosion regions")
        {:ok, corro_regions} = check_corrosion_regions()
        Phoenix.PubSub.broadcast(Corrodemo.PubSub, "corro_regions", {:corro_regions, corro_regions})
    end
    broadcast_regions()
    {:noreply, state}
  end

  def handle_info({:sandwich, message}, state) do
     #IO.puts("Sandwich sender received #{message} by PubSub")
     fly_region = System.get_env("FLY_REGION")
    #  IO.inspect(fly_region)
    #  IO.inspect(message)
     Corrodemo.CorroCalls.upload_region_sandwich(fly_region, message)
    {:noreply, state}
  end

  def check_regions() do
    home_region = System.get_env("FLY_REGION")
    this_app = System.get_env("FLY_APP_NAME")
    IO.inspect("FLY_APP_NAME is #{this_app}")
    app_regions_resolver = ":inet_res.getbyname('regions.#{System.get_env("FLY_APP_NAME")}.internal', :txt)"
    {{:ok,  {_, _, _, _, _, region_list}}, []} = Code.eval_string(app_regions_resolver)
    #{:ok,  {_, _, _, _, _, region_list}} = :inet_res.getbyname('regions.corro-sandwiches-ex.internal', :txt)
    other_regions = List.first(region_list)
    |> List.to_string()
    |> String.split(",")
    # |> IO.inspect(label: "app regions")
    |> Enum.reject(& match?(^home_region, &1))
    |> IO.inspect(label: "other regions")
    {:ok, other_regions}
  end

  def check_corrosion_regions() do
    corro_regions_resolver = ":inet_res.getbyname('regions.#{System.get_env("FLY_CORROSION_APP")}.internal', :txt)"
    # IO.puts corro_regions_resolver
    {{:ok,  {_, _, _, _, _, region_list}}, []} = Code.eval_string(corro_regions_resolver)
    #{{:ok, {:hostent, 'regions.ctestcorro.internal', [], :txt, 1, [['mad,yyz']]}}, []}
    #{:ok,  {_, _, _, _, _, region_list}} = :inet_res.getbyname('regions.ctestcorro.internal', :txt)
    # {:hostent, 'regions.corrodemo.internal', [], :txt, 1, [['ewr,lax,yul,yyz']]}
    regions = List.first(region_list)
    |> List.to_string()
    |> String.split(",")
    |> IO.inspect(label: "corro regions")
    {:ok, regions}
  end

end
