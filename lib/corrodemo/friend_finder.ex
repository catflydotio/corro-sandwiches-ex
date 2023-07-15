defmodule Corrodemo.FriendFinder do
  use GenServer
  require Logger
  import Corrodemo.FlyDnsReq


  def start_link(_opts \\ []) do
    GenServer.start_link(Corrodemo.FriendFinder, [])
  end

  def broadcast_regions do
    Process.send_after(self(), :broadcast_regions, 10000)
  end

  def init(_opts) do
    broadcast_regions()
    {:ok, []}
  end

  def handle_info(:broadcast_regions, state) do
    case check_regions() do
      {:ok, other_regions} ->
        #IO.inspect(IEx.Info.info(other_regions))
        Phoenix.PubSub.broadcast(Corrodemo.PubSub, "friend_regions", {:other_regions, other_regions})
        unless Application.fetch_env!(:corrodemo, :corro_builtin) == "1" do
          ##IO.puts("Checking corrosion regions")
            {:ok, corro_regions} = check_corrosion_regions()
            Phoenix.PubSub.broadcast(Corrodemo.PubSub, "corro_regions", {:corro_regions, corro_regions})
            Phoenix.PubSub.broadcast(Corrodemo.PubSub, "nearest_corrosion", {:nearest_corrosion,   Corrodemo.FlyDnsReq.get_corro_instance()})
        end
        broadcast_regions()
        {:error, reason} -> Logger.info("Friend finder received an error from check_regions: #{reason}")
    end
    {:noreply, state}
  end

  def check_regions() do
    home_region = Application.fetch_env!(:corrodemo, :fly_region)
    this_app = Application.fetch_env!(:corrodemo, :fly_app_name)
    IO.inspect("FLY_APP_NAME is #{this_app}")
    app_regions_resolver = ":inet_res.getbyname('regions.#{this_app}.internal', :txt)"
    case Code.eval_string(app_regions_resolver) do
      {{:ok,  {_, _, _, _, _, region_list}},[]} -> other_regions = List.first(region_list)
      |> List.to_string()
      |> String.split(",")
      # |> IO.inspect(label: "app regions")
      |> Enum.reject(& match?(^home_region, &1))
      #|> IO.inspect(label: "other regions")
      {:ok, other_regions}
      {:ok} -> {:ok, []}
      {{:error, :nxdomain},[]} -> {:error, :nxdomain}
    end
  end

  def check_corrosion_regions() do
    corro_regions_resolver = ":inet_res.getbyname('regions.#{Application.fetch_env!(:corrodemo, :fly_corrosion_app)}.internal', :txt)"
    # IO.puts corro_regions_resolver
    with {{:ok,  {_, _, _, _, _, region_list}}, []} <- Code.eval_string(corro_regions_resolver) do
      #{{:ok, {:hostent, 'regions.ctestcorro.internal', [], :txt, 1, [['mad,yyz']]}}, []}
      regions = List.first(region_list)
      |> List.to_string()
      |> String.split(",")
      #|> IO.inspect(label: "corro regions")
      {:ok, regions}
    end
  end

end
