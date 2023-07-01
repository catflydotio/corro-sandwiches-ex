defmodule CorrodemoWeb.ShowOutputLive do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.LiveView
  import Corrodemo.CorroCalls
  import Corrodemo.FriendFinder

  def render(assigns) do
    ~H"""
    <%!-- <div>
    Current temperature: <%= @temperature %>
    <button phx-click="inc_temperature">+</button>
    </div> --%>
    <%!-- <div>
    Latest tests table data: <%= @thirteen_value %>
    <button phx-click="find_thirteen">update</button>
    </div> --%>
    <h2>This is the Sandwich Cloud in <%= @local_region %></h2>
    <div>
    This app is also running in:
    <%= for reg <- @other_regions do %>
      <%= reg %>&nbsp;
    <% end %>
    </div>
    <div>
    The ctestcorro corrosion cluster is running in:
    <%= for reg <- @corro_regions do %>
      <%= reg %>&nbsp;
    <% end %>
    </div>
    <div>
    The latest local "sandwich" PubSub message: <%= @sandwichmsg %>
    </div>
    <%!-- <div>
    The latest message from Corrosion: <%= @corromsg %>
    </div> --%>
    <%= for {region, sandwich} <- @kvs do %>
      <div>
        <%= region %> sandwich: <%= sandwich %>
      </div>
    <% end %>
    <%!-- <div>
    The latest <%= @local_region %> sandwich from Corrosion: <%= @local_corrosion_sandwich %>
    </div> --%>

    """
  end

  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(Corrodemo.PubSub, "fromcorro")
    Phoenix.PubSub.subscribe(Corrodemo.PubSub, "sandwichmsg")
    Phoenix.PubSub.subscribe(Corrodemo.PubSub, "friend_regions")
    Phoenix.PubSub.subscribe(Corrodemo.PubSub, "corro_regions")
    # Phoenix.PubSub.subscribe(Corrodemo.PubSub, "corrosion_ip")
    init_regions()
    {:ok, assign(socket, thirteen_value: "nothing eh", pubsubmsg: "uninitialised", local_region: System.get_env("FLY_REGION"), local_corrosion_sandwich: "empty bread", kvs: %{}, sandwichmsg: "empty bread", corromsg: "blank", other_regions: [], corro_regions: [])}
    # , yyz: "blank", ewr: "blank", lax: "blank", yul: "blank"
  end

  defp init_regions() do
    IO.inspect("this is the init_regions function")
    {:ok, other_regions} = Corrodemo.FriendFinder.check_regions()
    # Enum.each(region_list, fn region ->
    #   assign_new(socket, String.to_atom(region), "initialised")
    # end)
  end

  # find_thirteen is a test handler to make sure I can get a value with an API request
  def handle_event("find_thirteen", _params, socket) do
    {:ok, response} = Corrodemo.CorroCalls.corro_request("query","SELECT foo FROM tests WHERE id = 13")
    msg = response
    # |> IO.inspect()
    {:noreply, assign(socket, :thirteen_value, response.value)}
  end

  def handle_info({:sandwich, message}, socket) do
    #IO.puts "LiveView getting the local sandwich: #{message}"
    {:noreply, assign(socket, sandwichmsg: message)}
  end

  # def handle_info({:fromcorro, message}, socket) do
  #   IO.puts "LiveView getting a sandwich from corrosion: #{message}"
  #   {:noreply, assign(socket, corromsg: message)}
  # end

  # This sets the value of an existing assign with a region name. Trying to
  # replace it with an assign
  # def handle_info({:fromcorro, %{region: region, sandwich: sandwich}}, socket) do
  #   IO.puts "LiveView getting a sandwich from corrosion: #{region}, #{sandwich}"
  #   {:noreply, assign(socket, String.to_atom(region), sandwich)}
  # end

  def handle_info({:fromcorro, %{region: region, sandwich: sandwich}}, socket) do
    # IO.puts "LiveView getting a sandwich from corrosion: #{region}, #{sandwich}"
    updated_kvs = Map.put(socket.assigns.kvs, region, sandwich)
    # thing = Code.eval_string(updated_kvs) # |> elem(0)
    # IO.inspect(updated_kvs)
    {:noreply, assign(socket, :kvs, updated_kvs)}
  end

  def handle_info({:other_regions, other_regions}, socket) do
    # IO.puts "LiveView getting region list from PubSub: #{other_regions}"
    {:noreply, assign(socket, :other_regions, other_regions)}
  end

  def handle_info({:corro_regions, corro_regions}, socket) do
    # IO.puts "LiveView getting region list from PubSub: #{other_regions}"
    {:noreply, assign(socket, :corro_regions, corro_regions)}
  end

  # This is inactive for now (see check_corro module). If activating,
  # also uncomment the PubSub subscription to corrosion_ip up top
  # def handle_info({:corro_ip, %{region: region, ip: ip}}, socket) do
  #   IO.puts "LiveView getting a corrosion IP over PubSub: #{ip}"
  #   {:noreply, assign(socket, String.to_atom("corro_" <> region), ip)}
  # end

end
