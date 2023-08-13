defmodule Corrodemo.Discoverer do
  use GenServer

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_opts) do
    start_checking()
    {:ok, []}
  end

  def start_checking() do
    Process.send_after(self(), :check_service, 3000)
  end

  def handle_info(:check_service, _state) do
    check_service()
    |> inspect |> IO.inspect(label: "check_service")
    case check_service() do
      %{sandwich: sandwich } -> corro_service_update("up", sandwich)
      _ -> corro_service_update("down", "unknown")
    end
    start_checking()
    {:noreply, []}
  end

  def check_service() do
    Corrodemo.GenSandwich.get_sandwich()
  end

  def corro_service_update(status, sandwich) do
    region = Application.fetch_env!(:corrodemo, :fly_region)
    datetime = DateTime.utc_now()
    timestamp = DateTime.to_unix(datetime)
    IO.inspect(timestamp, label: "timestamp")
    vm_id = Application.fetch_env!(:corrodemo, :fly_vm_id)
    transactions = ["REPLACE INTO sandwich_services (vm_id, region, srv_state, sandwich, timestmp) VALUES (\"#{vm_id}\", \"#{region}\", \"#{status}\", \"#{sandwich}\", \"#{timestamp}\")"]
    IO.inspect(transactions)
    Corrodemo.CorroCalls.execute_corro(transactions)
    # vm_id TEXT PRIMARY KEY, region TEXT, srv_state TEXT, sandwich TEXT, timestmp TEXT
  end
end
