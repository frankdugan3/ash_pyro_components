defmodule AshPyroComponentsExample.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AshPyroComponentsExampleWeb.Telemetry,
      AshPyroComponentsExample.Repo,
      {DNSCluster, query: Application.get_env(:ash_pyro_components_example, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: AshPyroComponentsExample.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: AshPyroComponentsExample.Finch},
      # Start a worker by calling: AshPyroComponentsExample.Worker.start_link(arg)
      # {AshPyroComponentsExample.Worker, arg},
      {AshAuthentication.Supervisor, otp_app: :ash_pyro_components_example},
      # Start to serve requests, typically the last entry
      AshPyroComponentsExampleWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AshPyroComponentsExample.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AshPyroComponentsExampleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
