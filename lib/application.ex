defmodule PostgrixAas.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    #  import Supervisor.Spec
    # List all child processes to be supervised
    children = [
      InternalDB.Repo,
      {Plug.Adapters.Cowboy2, scheme: :http, plug: API.Router, options: [port: 8080]},
      {PostgrixCluster.Server, name: ClusterAPI.Server}
    ]

    #start vaultex client here? or auth here?
    Logger.info("Application Started!")
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PostgrixAas.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
