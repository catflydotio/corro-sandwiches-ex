defmodule CorrodemoWeb.ShowOutputLive do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.LiveView
  import Corrodemo.CorroCalls
  import Corrodemo.FriendFinder

  def render(assigns) do
    ~H"""
    <%= if Application.fetch_env!(:corrodemo, :fly_app_name) do %>
    <h2>This is <%= Application.fetch_env!(:corrodemo, :fly_app_name) %> in <%= @local_region %></h2>
    <div>
      This app is also running in:
      <%= for reg <- @other_regions do %>
        <%= reg %>&nbsp;
      <% end %>
    </div>
    <% end %>
    <%= unless Application.fetch_env!(:corrodemo, :corro_builtin)== "1" do %>
      <div>
        The <%=Application.fetch_env!(:corrodemo, :fly_corrosion_app)%> corrosion cluster is running in:
        <%= for reg <- @corro_regions do %>
          <%= reg %>&nbsp;
        <% end %>
      </div>
      <div>
      top1.nearest.of.<%=Application.fetch_env!(:corrodemo, :fly_corrosion_app)%>.internal is Machine <%= @nearest_corrosion["instance"] %>, in <%= @nearest_corrosion["region"] %> at 6PN address <%= @nearest_corrosion["ip"] %>
      </div>
    <% end %>
    <div>
      The latest local "sandwich" PubSub message: <%= @sandwichmsg %>
    </div>
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
    Phoenix.PubSub.subscribe(Corrodemo.PubSub, "nearest_corrosion")
    # Phoenix.PubSub.subscribe(Corrodemo.PubSub, "corrosion_ip")
    init_app_regions(socket)
    {:ok, assign(socket, thirteen_value: "nothing eh", pubsubmsg: "uninitialised", local_region: Application.fetch_env!(:corrodemo, :fly_region), local_corrosion_sandwich: "empty bread", kvs: %{}, sandwichmsg: "empty bread", corromsg: "blank", other_regions: [], corro_regions: [], nearest_corrosion: %{})}
    # , yyz: "blank", ewr: "blank", lax: "blank", yul: "blank"
  end

  # defp check_other_regions() do
  #   IO.inspect("this is the check_other_regions function in the liveview")
  #   {:ok, other_regions} = Corrodemo.FriendFinder.check_regions()
  #   # Enum.each(region_list, fn region ->
  #   #   assign_new(socket, String.to_atom(region), "initialised")
  #   # end)
  # end

  defp init_app_regions(socket) do
    case Corrodemo.FriendFinder.check_regions() do
      {:ok, other_regions} -> {:noreply, assign(socket, :other_regions, other_regions)}
      _ -> IO.puts("init_app_regions didn't receive any regions from check_regions")
    end
  end

  def handle_info({:sandwich, message}, socket) do
    #IO.puts "LiveView getting the local sandwich: #{message}"
    {:noreply, assign(socket, sandwichmsg: message)}
  end

  # def handle_info({:fromcorro, message}, socket) do
  #   IO.puts "LiveView getting a sandwich from corrosion: #{message}"
  #   {:noreply, assign(socket, corromsg: message)}
  # end

  #This sets the value of an existing assign with a region name. Trying to
  #replace it with an assign
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
    # IO.puts "LiveView getting corrosion region list from PubSub: #{other_regions}"
    {:noreply, assign(socket, :corro_regions, corro_regions)}
  end

  def handle_info({:nearest_corrosion, nearest_corrosion}, socket) do
    # IO.puts "LiveView getting nearest corrosion info from PubSub."
    {:noreply, assign(socket, :nearest_corrosion, nearest_corrosion)}
  end

  # This is inactive for now (see check_corro module). If activating,
  # also uncomment the PubSub subscription to corrosion_ip up top
  # def handle_info({:corro_ip, %{region: region, ip: ip}}, socket) do
  #   IO.puts "LiveView getting a corrosion IP over PubSub: #{ip}"
  #   {:noreply, assign(socket, String.to_atom("corro_" <> region), ip)}
  # end

end
