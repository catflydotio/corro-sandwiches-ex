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
        unless System.get_env("CORRO_BUILTIN") == "1" do
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
    home_region = System.get_env("FLY_REGION")
    this_app = System.get_env("FLY_APP_NAME")
    #IO.inspect("FLY_APP_NAME is #{this_app}")
      cond do
        this_app -> {:ok, []}
          app_regions_resolver = ":inet_res.getbyname('regions.#{System.get_env("FLY_APP_NAME")}.internal', :txt)"
          case Code.eval_string(app_regions_resolver) do
            {{:ok,  {_, _, _, _, _, region_list}}, []} -> other_regions = List.first(region_list)
            |> List.to_string()
            |> String.split(",")
            # |> IO.inspect(label: "app regions")
            |> Enum.reject(& match?(^home_region, &1))
            #|> IO.inspect(label: "other regions")
            {:ok, other_regions}
            {:ok} -> {:ok, []}
            {{:error, :nxdomain}, []} -> {:error, :nxdomain}
          end
        # {:error, resp} -> {:error, resp}
        true -> {:ok, "Looks like FLY_APP_NAME isn't set"}
    end
  end

  def check_corrosion_regions() do
    corro_regions_resolver = ":inet_res.getbyname('regions.#{System.get_env("FLY_CORROSION_APP")}.internal', :txt)"
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
