defmodule CorrodemoWeb.ShowOutputLive do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.LiveView
  import Corrodemo.CorroCalls
  import Corrodemo.FriendFinder

  def render(assigns) do
    ~H"""
    <div class="min-h-screen overflow-hidden bg-gray-100 py-6 px-6">
      <%= if Application.fetch_env!(:corrodemo, :fly_app_name) do %>
        <h2 class="text-[1.5rem] mb-2 font-semibold leading-10">This is <%= @fly_app %> on <%= @this_instance %> in <%= @local_region %></h2>
        <div class="mb-2">
          This app is also running in:
          <code>
          <%= for reg <- @other_regions do %>
            <%= reg %>&nbsp;
          <% end %>
          </code>
        </div>
      <% end %>

      <div class="grid grid-cols-2 auto-cols-min gap-2">

          <div class="grid grid-cols-2 auto-cols-min gap-2 mb-2">
            <div>
              Local "sandwich" by PubSub:
            </div>
            <div>
              <%= @pubsub_sandwich %>
            </div>
          </div>
          <div class="text-sm px-3 pt-3  bg-violet-200">
            Here's some text about how the app generates a new sandwich each second.

            <p>It picks a new sandwich from a list every second, and sends a Phoenix PubSub message about it. </p>
            <p>This LiveView subscribes to those messages and changes the <code>&commat;pubsub_sandwich</code> assign when the local sandwich changes.</p>
          </div>
          <h2 class="text-lg mb-2 font-semibold leading-10 col-span-2">From Corrosion:</h2>
          <div class="grid grid-cols-2 auto-cols-min gap-2 content-start">
            <%= for {vm, sandwich} <- @kvs do %>
            <div>
              <%= vm %> sandwich:
            </div>
            <div>
              <%= sandwich %>
            </div>
            <% end %>
          </div>
      <div>
        <code><pre class="text-sm px-3 pt-3 overflow-x-scroll bg-blue-200">
curl -v http://top1.nearest.of.ccorrosion.internal:8080/v1/watches \
-H "content-type: application/json" \
-d '"SELECT pk AS vm_id, sandwich FROM sw"'
        </pre></code>
        <code><pre class="text-sm px-3 pt-3 overflow-x-scroll bg-gray-200">
&lt; HTTP/1.1 200 OK
&lt; corro-query-id: 046aabad-7b11-446b-9380-78bbc4a2ae43
&lt; transfer-encoding: chunked
&lt; date: Sat, 12 Aug 2023 16:40:56 GMT
&lt;
{"event":"columns","data":["vm_id","sandwich"]}
{"event":"columns","data":["vm_id","sandwich"]}
{"event":"row","data":{"rowid":1,"change_type":"upsert","cells":["yyz","halloumi"]}}
{"event":"row","data":{"rowid":2,"change_type":"upsert","cells":["918575d5f43d98","halloumi"]}}
{"event":"row","data":{"rowid":3,"change_type":"upsert","cells":["local","smoked salmon"]}}
{"event":"row","data":{"rowid":4,"change_type":"upsert","cells":["e286555df05718","smoked salmon"]}}
{"event":"row","data":{"rowid":1350,"change_type":"upsert","cells":["localhost","burger"]}}
{"event":"end_of_query"}
{"event":"row","data":{"rowid":2,"change_type":"upsert","cells":["918575d5f43d98","ham"]}}
{"event":"row","data":{"rowid":4,"change_type":"upsert","cells":["e286555df05718","shiitake"]}}
{"event":"row","data":{"rowid":1350,"change_type":"upsert","cells":["localhost","saucisson"]}}
{"event":"row","data":{"rowid":1350,"change_type":"upsert","cells":["localhost","grilled cheese"]}}
...
            </pre></code>
        </div>
      </div>

    <%= unless Application.fetch_env!(:corrodemo, :corro_builtin)== "1" do %>
        <div class="text-sm my-5">
        <div>
          <code>The <%=Application.fetch_env!(:corrodemo, :fly_corrosion_app)%> corrosion cluster is running in:
          <%= for reg <- @corro_regions do %>
            <%= reg %>&nbsp;
          <% end %>
          </code>
        </div>
        <div>
        <code>top1.nearest.of.<%=Application.fetch_env!(:corrodemo, :fly_corrosion_app)%>.internal: <%= @nearest_corrosion["ip"] %> (id <%= @nearest_corrosion["instance"] %>, in <%= @nearest_corrosion["region"] %>)</code>
        </div>
        </div>
      <% end %>
    </div>

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
    with corro_app = Application.fetch_env(:corrodemo, :fly_corrosion_app) do
      assign(socket,
        fly_corrosion_app:  corro_app
        )
    end
    {:ok, assign(socket,
      thirteen_value: "nothing eh",
      pubsubmsg: "uninitialised",
      fly_app: Application.fetch_env!(:corrodemo, :fly_app_name),
      local_region: Application.fetch_env!(:corrodemo, :fly_region),
      local_corrosion_sandwich: "empty bread",
      kvs: %{},
      pubsub_sandwich: "empty bread",
      this_instance: Application.fetch_env!(:corrodemo, :fly_vm_id),
      corromsg: "blank",
      other_regions: [],
      corro_regions: [],
      nearest_corrosion: %{}
      )
    }

  end

  defp init_app_regions(socket) do
    case Corrodemo.FriendFinder.check_regions() do
      {:ok, other_regions} -> {:noreply, assign(socket, :other_regions, other_regions)}
      _ -> IO.puts("init_app_regions didn't receive any regions from check_regions")
    end
  end

  def handle_info({:sandwich, sandwich}, socket) do
    #IO.puts "LiveView getting the local sandwich: #{message}"
    {:noreply, assign(socket, pubsub_sandwich: sandwich)}
  end

  def handle_info({:fromcorro, [vm_id, sandwich]}, socket) do
    # IO.puts "LiveView getting a sandwich from corrosion: #{vm_id}, #{sandwich}"
    updated_kvs = Map.put(socket.assigns.kvs, vm_id, sandwich)
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
