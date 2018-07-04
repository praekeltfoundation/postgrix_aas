defmodule PostgrixAas.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
  #  import Supervisor.Spec
    # List all child processes to be supervised
    children = [
      Postgrix_Cluster.Repo,
    ]
    IO.puts("Application Started!")
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PostgrixAas.Supervisor]
    Supervisor.start_link(children, opts)
    #Supervisor.start_link(Postgrex.start_link(hostname: "localhost", username: "postgres", password: "mysecretpassword", database: "postgres"), opts)

  end

end
