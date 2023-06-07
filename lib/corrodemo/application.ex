defmodule Corrodemo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      CorrodemoWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Corrodemo.PubSub},
      # Start Finch
      {Finch, name: Corrodemo.Finch},
      # Start the Endpoint (http/https)
      CorrodemoWeb.Endpoint,
      # Start a worker by calling: Corrodemo.Worker.start_link(arg)
      # {Corrodemo.Worker, arg}
      ## CAN: starting up the websocket connection to Corrosion
      ## the supervisor will run start_link
      Corrodemo.CorroSockets,
      Corrodemo.GenSandwich,
      Corrodemo.SandwichSender
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Corrodemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CorrodemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end