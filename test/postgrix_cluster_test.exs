defmodule PostgrixCluster.RepoCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias PostgrixCluster.Repo

      import Ecto
      import Ecto.Query
      import PostgrixCluster.RepoCase

      # and any other stuff
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(PostgrixCluster.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(PostgrixCluster.Repo, {:shared, self()})
    end

    :ok
  end
end
