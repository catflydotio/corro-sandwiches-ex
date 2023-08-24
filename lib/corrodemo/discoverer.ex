defmodule Corrodemo.Discoverer do
  use GenServer

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, [], name: Discoverer)
  end

  def start_checking() do
    Process.send_after(self(), :check_local_service_msg, 3000)
  end

  def start_cleaning() do
    Process.send(self(), :start_cleaning_msg, [])
    # Process.send_after(self(), :start_cleaning_msg, 2000)
  end

  # def check_local_service() do
  #   Corrodemo.GenSandwich.get_sandwich()
  # end

  def corro_service_update(status, sandwich) do
    region = Application.fetch_env!(:corrodemo, :fly_region)
    datetime = DateTime.utc_now()
    timestamp = DateTime.to_unix(datetime)
    sandwich_addr = Application.fetch_env!(:corrodemo, :fly_private_ip)
    # IO.inspect(timestamp, label: "timestamp")
    IO.inspect(sandwich_addr, label: "sandwich_addr")
    vm_id = Application.fetch_env!(:corrodemo, :fly_vm_id)
    transactions = ["REPLACE INTO sandwich_services (vm_id, region, sandwich_addr, srv_state, sandwich, timestmp) VALUES (\"#{vm_id}\", \"#{region}\", \"#{sandwich_addr}\", \"#{status}\", \"#{sandwich}\", \"#{timestamp}\")"]
    IO.inspect("updated local service status to #{status}")
    Corrodemo.CorroCalls.execute_corro(transactions)
    # vm_id TEXT PRIMARY KEY, region TEXT, srv_state TEXT, sandwich TEXT, timestmp TEXT
  end

  def test_remote_sandwiches() do
    query = "SELECT sandwich_addr FROM sandwich_services WHERE srv_state = 'up'"
    Corrodemo.CorroCalls.query_corro(query)
    |> IO.inspect(label: "in test_remote_sandwiches")
  end

  @impl true
  def init(_opts) do
    start_checking()
    start_cleaning()
    {:ok, []}
  end

  @impl true
  def handle_info(:check_local_service_msg, _state) do
    IO.puts("I AM CHECKING THAT I AM WORKING")
    # check_local_service()
    Corrodemo.GenSandwich.get_sandwich()
    |> inspect |> IO.inspect(label: "GenSandwich.get_sandwich")
    case Corrodemo.GenSandwich.get_sandwich() do
      %{sandwich: sandwich} -> corro_service_update("up", sandwich)
      _ -> corro_service_update("down", "unknown")
    end
    start_checking()
    {:noreply, []}
  end

  @impl true
  def handle_info(:start_cleaning_msg, _state) do
    IO.puts("I HAVE RECEIVED A start_cleaning_msg MESSAGE")
    Task.Supervisor.start_child(Corrodemo.TaskSupervisor, fn ->
      IO.puts("HEY! I'm inside the task!")
      # business logic
      do_services_cleaning()
      Process.sleep(5000)
      Process.send(Discoverer, :start_cleaning_msg, [])
     end)
    {:noreply, []}
  end

  def do_services_cleaning() do
    IO.puts("this is where the actual checking of all the services goes")
    # Ask Corrosion for the IP addresses for which srv_state is "up"
    test_remote_sandwiches()
    #
  end

end
