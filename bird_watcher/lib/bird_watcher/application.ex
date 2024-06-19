defmodule BirdWatcher.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # How to kick off an elixir server in the background
    # Task.start(fn -> System.cmd("sh", ["-c", "mix run --no-halt &"], env: [{"PORT", "4001"}]) end)

    children = [
      BirdWatcherWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:bird_watcher, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: BirdWatcher.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: BirdWatcher.Finch},
      # Start a worker by calling: BirdWatcher.Worker.start_link(arg)
      # {BirdWatcher.Worker, arg},
      # Start to serve requests, typically the last entry
      BirdWatcherWeb.Endpoint,
      BirdWatcher.DB,
      BirdWatcher.Watcher
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BirdWatcher.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BirdWatcherWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
