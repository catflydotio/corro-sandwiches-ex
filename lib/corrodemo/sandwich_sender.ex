defmodule Corrodemo.SandwichSender do
  use GenServer
  import Corrodemo.CorroCalls
  require Logger

  # @name __MODULE__

  def start_link(_opts \\ []) do
    # This is the function that gets run by the supervisor when I run the server
    GenServer.start_link(Corrodemo.SandwichSender, [])
  end

  def init(_opts) do
    {Phoenix.PubSub.subscribe(Corrodemo.PubSub, "sandwichmsg")}
    |> IO.inspect(label: "Sandwich sender subscribed to sandwichmsg topic")
    region = System.get_env("FLY_REGION")
    IO.inspect("About to call init region sandwich #{region}")
    case Corrodemo.CorroCalls.init_region_sandwich(region) do
      {:ok} 
        -> IO.puts("Initialised region sandwich")
        {:ok, %{}}
      {:error, reason} 
        -> IO.puts("Couldn't initialise region sandwich: #{reason}")
        {:ok, %{}}
    end

  end

  # Callbacks

  def handle_info({:sandwich, message}, state) do
     #IO.puts("Sandwich sender received #{message} by PubSub")
     fly_region = System.get_env("FLY_REGION")
      #IO.inspect(fly_region)
      IO.inspect(message)
     Corrodemo.CorroCalls.upload_region_sandwich(fly_region, message)
    {:noreply, state}
  end

  def handle_info(message, state) do
    IO.puts("Sandwich sender received some other message #{message}")
    {:noreply, state}
  end

end
