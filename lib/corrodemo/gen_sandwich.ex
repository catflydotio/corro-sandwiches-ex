defmodule Corrodemo.GenSandwich do
  use GenServer
  @name __MODULE__

  # I'm hard-coding some sandwiches into some regions. Obviously you'd get the list for your region from somewhere else. They could be stored in corrosion, if you wanted to. :D
  @sandwiches [{:yul, ["smoked meat", "halloumi", "saucisson"]}, {:yyz, ["burger", "brie and cranberry", "reuben"]}, {:ewr, ["avocado", "grilled cheese", "smoked salmon"]}, {:lax,["shiitake", "ham", "BLT"]}]

  def start_link(_opts \\ []) do
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
    region = String.to_atom(System.get_env("FLY_REGION"))
    #IO.inspect{"Checking region: #{region}"}
    result = Enum.random(@sandwiches[region])
    Phoenix.PubSub.broadcast(Corrodemo.PubSub, "sandwichmsg", {:sandwich, result})
    # IO.inspect("is this doing anything?")
    do_the_swap()
    {:noreply, state}
  end

end
