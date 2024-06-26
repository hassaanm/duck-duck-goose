defmodule BirdWatcher.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BirdWatcherWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:bird_watcher, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: BirdWatcher.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: BirdWatcher.Finch},
      {Task.Supervisor, name: BirdWatcher.TaskSupervisor, restart: :transiant},
      BirdWatcher.DB,
      BirdWatcher.Watcher,
      # Start to serve requests, typically the last entry
      BirdWatcherWeb.Endpoint
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
