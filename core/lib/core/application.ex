defmodule Core.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(CoreWeb.Endpoint, []),
      worker(Core.Queue, [], restart: :permanent),
      worker(Core.Discovery, [], restart: :permanent),
      worker(Core.CouchDB, [], restart: :permanent),
      worker(Core.Replication, [], restart: :permanent)
      # Start your own worker by calling: Core.Worker.start_link(arg1, arg2, arg3)
      # worker(Core.Worker, [arg1, arg2, arg3]),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Core.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CoreWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
