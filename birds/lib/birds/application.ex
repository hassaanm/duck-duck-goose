defmodule Birds.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @port Application.compile_env(:birds, :port)

  @impl true
  def start(_type, _args) do
    children = [
      {Bandit, plug: Birds.Router, scheme: :http, port: @port},
      {Birds.Bird, db: Birds.DB.BirdTracker, port: @port, name: Birds.Bird}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Birds.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
