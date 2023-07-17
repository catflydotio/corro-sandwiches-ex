defmodule Corrodemo.SandwichSender do
  use GenServer
  import Corrodemo.CorroCalls
  import Corrodemo.FlyDnsReq
  require Logger

  def start_link(_opts \\ []) do
    # This is the function that gets run by the supervisor when I run the server
    GenServer.start_link(Corrodemo.SandwichSender, [])
  end

  def init(_opts) do
    {Phoenix.PubSub.subscribe(Corrodemo.PubSub, "sandwichmsg")}
    |> IO.inspect(label: "Sandwich sender subscribed to sandwichmsg topic")
    region = Application.fetch_env!(:corrodemo, :fly_region)
    IO.inspect("About to call init region sandwich #{region}")
    case Corrodemo.CorroCalls.init_region_sandwich(region) do
      {:ok, results}
        -> case results do
          %{"rows_affected" => rows_affected} ->
            cond do
              rows_affected == 0 -> IO.puts("No rows affected; sandwich already initialised")
              rows_affected > 0 -> IO.puts("Initialised sandwich")
            end
            {:ok, []}
          end
      {:error, reason}
        -> IO.puts("Couldn't initialise region sandwich!")
        inspect(reason) |> Logger.debug()
        {:ok, "Couldn't init region sandwich"}
      _ -> IO.puts("init_region_sandwich returned something I don't recognise")
    end

  end

  def handle_info({:sandwich, message}, state) do
    #  IO.puts("Sandwich sender received #{message} by PubSub")
     fly_region = Application.fetch_env!(:corrodemo, :fly_region)
     Corrodemo.FlyDnsReq.get_all_instances()
      #IO.inspect(fly_region)
      #IO.inspect(message)
     case Corrodemo.CorroCalls.upload_region_sandwich(fly_region, message) do
      {:ok, results}
        -> case results do
          %{"rows_affected" => rows_affected} ->
            cond do
              rows_affected == 0 -> IO.puts("No rows affected; no sandwich uploaded")
              rows_affected > 0 -> IO.inspect("rows_affected: #{rows_affected}. Successfully updated sandwich in Corrosion")
            end
            {:ok, []}
          end
      {:error, reason}
        -> IO.puts("Couldn't upload region sandwich!")
        inspect(reason) |> Logger.debug()
        System.stop(0)
    end
    {:noreply, state}
  end

  def handle_info(message, state) do
    IO.puts("Sandwich sender received some other message #{message}")
    {:noreply, state}
  end

end
