defmodule BirdOrganizer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # How to kick off an elixir server in the background
    # Task.start(fn -> System.cmd("sh", ["-c", "mix run --no-halt &"], env: [{"PORT", "4001"}]) end)

    children = [
      BirdOrganizerWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:bird_organizer, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: BirdOrganizer.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: BirdOrganizer.Finch},
      # Start a worker by calling: BirdOrganizer.Worker.start_link(arg)
      # {BirdOrganizer.Worker, arg},
      # Start to serve requests, typically the last entry
      BirdOrganizerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BirdOrganizer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BirdOrganizerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
