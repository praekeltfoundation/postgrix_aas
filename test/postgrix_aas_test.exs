defmodule Postgrix_Clusters.RepoCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Postgrix_aaS.Repo

      import Ecto
      import Ecto.Query
      import Postgrix_Clusters.RepoCase

      # and any other stuff
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Postgrix_Clusters.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Postgrix_Clusters.Repo, {:shared, self()})
    end

    :ok
  end
end
