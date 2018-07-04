defmodule Postgrix_Cluster.RepoCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Postgrix_Cluster.Repo

      import Ecto
      import Ecto.Query
      import Postgrix_Cluster.RepoCase

      # and any other stuff
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Postgrix_Cluster.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Postgrix_Cluster.Repo, {:shared, self()})
    end

    :ok
  end
end
