defmodule Corrodemo.CorroPort do
  use GenServer
  # Not finished! Not started by supervisor yet either.
  # https://hexdocs.pm/elixir/1.13/Port.html
  # Also read https://tonyc.github.io/posts/managing-external-commands-in-elixir-with-ports/


  def start_link(_opts \\ []) do
    GenServer.start_link(Corrodemo.CorroPort, [])
  end

  def init(_opts) do
    command = "/app/corrosion" # agent -c /app/config.toml"
    options = [{:args, ["agent", "-c", "/app/config.toml"]}, :binary, :exit_status]
    port = Port.open({:spawn_executable, command}, options)
    {:ok, []}
  end


end
