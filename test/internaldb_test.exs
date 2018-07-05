defmodule InternalDB.RepoCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias InternalDB.Repo

      import Ecto
      import Ecto.Query
      import InternalDB.RepoCase

      # and any other stuff
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(InternalDB.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(InternalDB.Repo, {:shared, self()})
    end

    :ok
  end
end
