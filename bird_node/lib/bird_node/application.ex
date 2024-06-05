defmodule BirdNode.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  # alias Logger.Backends

  use Application

  @impl true
  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT") || "4001")

    children = [
      # Starts a worker by calling: BirdNode.Worker.start_link(arg)
      # {BirdNode.Worker, arg}
      {Bandit, plug: BirdNode.Router, scheme: :http, port: port},
      BirdNode.Node
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BirdNode.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
