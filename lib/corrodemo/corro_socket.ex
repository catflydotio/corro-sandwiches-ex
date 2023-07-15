defmodule Corrodemo.CorroSockets do
  use WebSockex
  require Logger

  def start_link(opts \\ []) do
    subscribe_corro(3, opts)
  end

  def subscribe_corro(retries, opts) when retries > 0 do
    subscribe_endpoint = "#{Application.fetch_env!(:corrodemo, :corro_baseurl)}/v1/subscribe"
    # IO.inspect(subscribe_endpoint, label: "corro subscription endpoint")
    #inspect(opts) |> Logger.info()
    case WebSockex.start_link(subscribe_endpoint, __MODULE__, %{}, opts) do
      {:ok, pid} -> add_sub(pid)
      {:error, reason} -> Logger.debug inspect(reason)
        IO.inspect("Couldn't start websocket connection; trying again #{retries - 1} times.")
        Process.sleep(2000)
        subscribe_corro(retries - 1, opts)
    end
  end

  def subscribe_corro(0, _opts) do
    IO.puts("Couldn't subscribe to corrosion.")
    System.stop(0)
    {:error, "Couldn't establish Corrosion websocket connection"}
  end

  def add_sub(pid) do
    IO.puts("running add_sub")
    msgstruct = %{
      add: %{
      id: "subscription_id",
      where_clause: "tbl_name = 'sw'"
      }
    }
    msg = Jason.encode!(msgstruct)
    IO.inspect(msg)
    with :ok <- WebSockex.send_frame(pid, {:text, msg}) do
      IO.puts("got ok back from WebSockex after sending subscribe frame")
      {:ok, pid}
    else
      {:error, reason} -> inspect(reason) |> IO.inspect()
      System.stop(0)
    end
  end

  def remove_sub(pid, id) do
    msgstruct = %{
      remove: %{
      id: id}
    }
    msg = Jason.encode!(msgstruct)
    # IO.inspect(msg)
    WebSockex.send_frame(pid, {:text, msg})
  end

  def handle_frame({:binary, msg}, _state) do
    IO.puts("Handling a frame from Corrosion")
    # IO.inspect("Message from Corrosion: #{msg}")
    # IO.inspect(state)
    # This needs to handle SubscriptionMessage structs in response to changes
    # Here's a brittle version of that for a single value being updated in a
    # id, foo table:
    event = msg
    |> Jason.decode!()
    |> Map.get("event",[])
    |> Map.get("event",[])
    # |> IO.inspect()
    # IO.inspect("corro_sockets handle_frame inspection above")
    data = Map.get(event, "data",[])
    # could try all_in or whatever it was called instead of three Map.gets
    pk = get_pk(event, "pk")
    sandwich = get_col(event, "sandwich")
    # Broadcast the new sandwich over the "fromcorro" pubsub topic for LiveView to pick up
    Phoenix.PubSub.broadcast(Corrodemo.PubSub, "fromcorro", {:fromcorro, %{region: pk, sandwich: sandwich}})
    # Websockex wants the end message to be like this:
    {:ok, data}
  end

  def handle_frame(_) do
    IO.puts("Got something, anything, from corrosion")
  end

  def handle_disconnect(%{reason: reason}, state) do
    Logger.info("Disconnect with reason: #{inspect reason}")
    {:ok, state}
  end

  def get_col(event, label) do
    Map.get(event, "data",[])
    |> Map.get(label,[])
  end

  def get_pk(event, label) do
    Map.get(event, "pk",[])
    |> Map.get(label,[])
  end

end
