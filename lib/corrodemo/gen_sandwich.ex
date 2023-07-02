defmodule Corrodemo.GenSandwich do
  use GenServer

  @all_sandwiches ["smoked meat", "halloumi", "saucisson", "burger", "brie and cranberry", "reuben", "avocado", "grilled cheese", "smoked salmon", "shiitake", "ham", "BLT", "portobello"]

  def start_link(_opts \\ []) do
    GenServer.start_link(Corrodemo.GenSandwich, [])
  end

  def do_the_swap(menu) do
    Process.send_after(self(), {:do_the_swap, menu}, 1000)
  end

  def init(_opts) do
    :rand.seed(:exsplus, :erlang.now) # If I don't do this, all the VMs get the same set of sandwiches.
    # I don't know anything about the algorithms for this, but it really doesn't matter in this app
    menu = Enum.take_random(@all_sandwiches, 3)
    IO.inspect "In #{System.get_env("FLY_REGION")}, the sandwich menu is #{menu}."
    do_the_swap(menu)
    {:ok, []}
  end

  def handle_info({:do_the_swap, menu}, state) do
    # region = String.to_atom(System.get_env("FLY_REGION"))
    # #IO.inspect{"Checking region: #{region}"}
    # #result = Enum.random(@sandwiches[region]) # this was to pick a sandwich from a hardcoded list
    result = Enum.random(menu)
    Phoenix.PubSub.broadcast(Corrodemo.PubSub, "sandwichmsg", {:sandwich, result})
    do_the_swap(menu)
    {:noreply, state}
  end

end
