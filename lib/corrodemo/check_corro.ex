defmodule Corrodemo.CheckCorro do
  # Took this out of the application start function.
  # Wrote this to check the 6PN address of the nearest corrosion. It does that,
  # but I don't necessarily want to keep checking that.
  # Better would be to get the IP once on subscription. Could go further and
  # try comparing the subscribed instance to the current top1.nearest.of. But
  # that's really just something you could do, not something I have a lot of
  # use for.
  use GenServer
  @name __MODULE__

  def start_link(_opts \\ []) do
    GenServer.start_link(Corrodemo.CheckCorro, [])
  end

  def do_the_thing do
    Process.send_after(self(), :do_the_thing, 5000)
  end

  # Callbacks

  def init(_opts) do
    do_the_thing()
    {:ok, []}
  end

  def handle_info(:do_the_thing, state) do
    # IO.inspect("is this doing anything?")
    region = System.get_env("FLY_REGION")
    result = get_corro_ipv6()
    Phoenix.PubSub.broadcast(Corrodemo.PubSub, "corrosion_ip", {:corro_ip, %{region: region, ip: result}})
    do_the_thing()
    {:noreply, state}
  end


  def get_corro_ipv6() do
    {:ok, {_, _, _, _, _, ip_list}} = :inet_res.getbyname('top1.nearest.of.ccorrosion.internal', :aaaa)
    List.first(ip_list)
    |> Tuple.to_list()
    |> Enum.map(fn x -> Integer.to_string(x,16) end)
    |> Enum.join(":")
    |> String.downcase()
    |> IO.inspect()
  end

  defp v6_to_hex(ip_tuple) do
    ip_tuple
    |> Tuple.to_list()
    |> Enum.map(fn x -> Integer.to_string(x,16) end)
    |> Enum.join(":")
    |> String.downcase()
  end

end
