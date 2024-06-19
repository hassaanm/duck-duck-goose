defmodule Birds.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @port Application.compile_env(:birds, :port)

  @impl true
  def start(_type, _args) do
    # Don't start normal supervision tree in tests because this type of application
    # requires multiple instances, so we'll manually start the processes in the tests.
    children =
      if Mix.env() == :test do
        []
      else
        [
          {Bandit, plug: Birds.Router, scheme: :http, port: @port},
          {Birds.Bird, db: Birds.DB.BirdTracker, port: @port}
        ]
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Birds.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
