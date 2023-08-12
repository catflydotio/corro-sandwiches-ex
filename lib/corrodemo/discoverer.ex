defmodule Corrodemo.Discoverer do
  use GenServer
  import Corrodemo.CorroCalls

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_opts) do
    start_checking()
    {:ok, []}
  end

  def start_checking() do
    Process.send_after(self(), :check_service, 10000)
  end

  def handle_info(:check_service, _state) do
    case check_service() do
      %{"sandwich"=> sandwich,"status"=> statuss} -> corro_service_update(statuss, sandwich)
    end
    start_checking()
    {:noreply, []}
  end

  def check_service() do
    Corrodemo.GenSandwich.get_sandwich()
  end

  def corro_service_update(statuss, sandwich) do
    region = Application.fetch_env!(:corrodemo, :fly_region)
    datetime = DateTime.utc_now()
    timestamp = DateTime.to_unix(datetime)
    vm_id = Application.fetch_env!(:corrodemo, :fly_vm_id)
    statement = "INSERT OR UPDATE INTO sandwich_services (vm_id, srv_state, sandwich, timestmp) VALUES ('#{vm_id}', '#{statuss}', '#{sandwich}', '#{timestamp}')"
    IO.inspect(statement)
    Corrodemo.CorroCalls.execute_corro(statement)
    # vm_id TEXT PRIMARY KEY, region TEXT, srv_state TEXT, sandwich TEXT, timestmp TEXT
  end
end
