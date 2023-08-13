defmodule Corrodemo.SandwichSender do
  use GenServer
  require Logger

  def start_link(_opts \\ []) do
    # This is the function that gets run by the supervisor when I run the server
    GenServer.start_link(Corrodemo.SandwichSender, [])
  end

  def init(_opts) do
    Corrodemo.StartupChecks.do_corro_checks()
    {Phoenix.PubSub.subscribe(Corrodemo.PubSub, "sandwichmsg")}
    |> IO.inspect(label: "Sandwich sender subscribed to sandwichmsg PubSub topic")
    vm = Application.fetch_env!(:corrodemo, :fly_vm_id)
    IO.inspect("About to call init local sandwich #{vm}")
    init_local_sandwich(vm)
    IO.inspect("About to start a watch")
    Corrodemo.CorroCalls.start_watch("SELECT pk AS vm_id, sandwich FROM sw")
    {:ok, []}
  end

  def handle_info({:sandwich, message}, state) do
    #  IO.puts("Sandwich sender received #{message} by PubSub")
    vm = Application.fetch_env!(:corrodemo, :fly_vm_id)
    Corrodemo.FlyDnsReq.get_all_instances()
    upload_local_sandwich(vm, message)
    {:noreply, state}
  end

  def handle_info(message, state) do
    IO.puts("Sandwich sender received some other message #{message}")
    {:noreply, state}
  end

  def init_local_sandwich(vm_id) do
    transactions = ["INSERT OR IGNORE INTO sw (pk, sandwich) VALUES ('#{vm_id}', 'empty')"]
    # IO.inspect(statement)
    case Corrodemo.CorroCalls.execute_corro(transactions) do
    {:ok, results}
          -> case results do
            %{"rows_affected" => rows_affected} ->
              cond do
                rows_affected == 0 -> IO.puts("No rows affected; sandwich already initialised")
                rows_affected > 0 -> IO.puts("Initialised sandwich")
              end
              {:ok, []}
          end
      {:error, reason}
        -> IO.puts("Couldn't initialise local sandwich!")
        inspect(reason) |> Logger.debug()
        {:ok, "Couldn't init local sandwich"}
      _ -> IO.puts("init_local_sandwich returned something I don't recognise")
    end
  end

  # "UPDATE tests SET foo = \"boffo\" WHERE id = 1021"
  def upload_local_sandwich(vm_id, sandwich) do
    transactions = ["UPDATE sw SET sandwich = '#{sandwich}' WHERE pk = '#{vm_id}'"]
    # IO.inspect(transactions)
    case Corrodemo.CorroCalls.execute_corro(transactions) do
    {:ok, results}
        -> case results do
          %{"rows_affected" => rows_affected} ->
            cond do
              rows_affected == 0 -> IO.puts("No rows affected; no sandwich uploaded")
              rows_affected > 0 -> IO.inspect("rows_affected: #{rows_affected}. Successfully updated sandwich in Corrosion")
            end
            {:ok, []}
          end
    {:error, reason}
      -> IO.puts("Couldn't upload local sandwich!")
      inspect(reason) |> Logger.debug()
      System.stop(0)
    end
  end


  @doc """
  This isn't used or tested
  """
  def get_local_sandwich(vm_id) do
    statement = "SELECT sandwich FROM sw WHERE pk = '#{vm_id}'"
    Corrodemo.CorroCalls.query_corro(statement)
  end

  @doc """
  This isn't used or tested
  """
  def get_sandwich_table() do
    statement = "SELECT * FROM sw"
    Corrodemo.CorroCalls.corro_request("query", statement)
    |> IO.inspect()
  end



end
