defmodule Corrodemo.GenSandwich do
  use GenServer
  @name __MODULE__

  @sandwiches ["smoked meat", "smoked halloumi", "smoked salmon"]

  def start_link(_opts \\ []) do
    # This is the function that gets run by the supervisor when I run the server
    GenServer.start_link(Corrodemo.GenSandwich, [])
  end

  def do_the_swap do
    Process.send_after(self(), :do_the_swap, 1000)
  end

  # Callbacks

  def init(_opts) do
    do_the_swap()
    {:ok, []}
  end

  def handle_info(:do_the_swap, state) do
    result = Enum.random(@sandwiches)
    Phoenix.PubSub.broadcast(Corrodemo.PubSub, "sandwichmsg", {:sandwich, result})
    # IO.inspect("is this doing anything?")
    do_the_swap()
    {:noreply, state}
  end

end
