defmodule Corrodemo.CorroSockets do
  use WebSockex
  require Logger

  # @corro_sub_endpoint "ws://echo.websocket.events/?encoding=text"
  @corro_sub_endpoint "http://localhost:8080/v1/subscribe"

  def start_link(opts \\ []) do
    # This is the function that gets run by the supervisor when I run the server
    # so I guess I have to include add_sub.
    {:ok, pid} = WebSockex.start_link(@corro_sub_endpoint, __MODULE__, %{}, opts)
    add_sub(pid)
  end

  def add_sub(pid) do
    msgstruct = %{
      add: %{
      id: "my_id",
      where_clause: "tbl_name = 'sw'"
      }
    }
    msg = Jason.encode!(msgstruct)
    # IO.inspect(msg)
    WebSockex.send_frame(pid, {:text, msg})
    {:ok, pid}
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

  def handle_frame({:binary, msg}, state) do
    # IO.inspect(msg)
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

    sandwich = get_col(event, "sandwich")
    # IO.inspect(sandwich)

    pk = get_pk(event, "pk")
    # IO.inspect(pk)

    # Once that's figured out, get it to send an assign update to the LiveView
    # Broadcast over the "corro" pubsub topic
    Phoenix.PubSub.broadcast(Corrodemo.PubSub, "fromcorro", {:fromcorro, %{region: pk, sandwich: sandwich}})
    # Phoenix.PubSub.broadcast(Corrodemo.PubSub, "fromcorro", {:fromcorro, "#{pk} = #{sandwich}"})
    # Phoenix.PubSub.broadcast(Corrodemo.PubSub, "sandwichmsg", {:sandwich, result})
    # Websockex wants the end message to be like this:
    {:ok, data}
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
