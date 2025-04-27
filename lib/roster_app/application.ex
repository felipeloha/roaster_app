defmodule RosterApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RosterAppWeb.Telemetry,
      RosterApp.Repo,
      {DNSCluster, query: Application.get_env(:roster_app, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: RosterApp.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: RosterApp.Finch},
      # Start a worker by calling: RosterApp.Worker.start_link(arg)
      # {RosterApp.Worker, arg},
      # Start to serve requests, typically the last entry
      RosterAppWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RosterApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RosterAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
