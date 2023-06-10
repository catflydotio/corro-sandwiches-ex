defmodule CorrodemoWeb.ShowOutputLive do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.LiveView
  import Corrodemo.CorroCalls

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
    <div>
    The latest "sandwich" PubSub message: <%= @sandwichmsg %>
    </div>
    <div>
    The latest message from Corrosion: <%= @corromsg %>
    </div>
    <div>
    yyz sandwich: <%= @yyz %>
    </div>
    <div>
    ewr sandwich: <%= @ewr %>
    </div>
    <div>
    lax sandwich: <%= @lax %>
    </div>
    <div>
    yul sandwich: <%= @yul %>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    temperature = 500
    Phoenix.PubSub.subscribe(Corrodemo.PubSub, "fromcorro")
    Phoenix.PubSub.subscribe(Corrodemo.PubSub, "sandwichmsg")
    {:ok, assign(socket, temperature: temperature, thirteen_value: "nothing eh", pubsubmsg: "uninitialised", sandwichmsg: "empty bread", corromsg: "blank", yyz: "blank", ewr: "blank", lax: "blank", yul: "blank")}
  end

  def handle_event("inc_temperature", _params, socket) do
    # The generic response is of the form {:noreply, socket}
    # You can also return a reply, a map, and a socket, e.g.
    # https://elixirforum.com/t/use-case-for-returning-reply-map-socket-in-handle-event-callback/42917/2
     {:noreply, update(socket, :temperature, &(&1 + 1))}
  end

  # find_thirteen is a test handler to make sure I can get a value with an API request
  def handle_event("find_thirteen", _params, socket) do
    {:ok, response} = Corrodemo.CorroCalls.corro_request("query","SELECT foo FROM tests WHERE id = 13")
    msg = response
    # |> IO.inspect()
    {:noreply, assign(socket, :thirteen_value, response.value)}
  end

  def handle_info({:sandwich, message}, socket) do
    IO.puts "LiveView getting the local sandwich: #{message}"
    {:noreply, assign(socket, sandwichmsg: message)}
  end

  # def handle_info({:fromcorro, message}, socket) do
  #   IO.puts "LiveView getting a sandwich from corrosion: #{message}"
  #   {:noreply, assign(socket, corromsg: message)}
  # end

  def handle_info({:fromcorro, %{region: region, sandwich: sandwich}}, socket) do
    IO.puts "LiveView getting a sandwich from corrosion: #{region}, #{sandwich}"
    {:noreply, assign(socket, String.to_existing_atom(region), sandwich)}
  end

end
