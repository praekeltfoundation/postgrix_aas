defmodule Postgrix_aaS.RepoCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Postgrix_aaS.Repo

      import Ecto
      import Ecto.Query
      import Postgrix_aaS.RepoCase

      # and any other stuff
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Postgrix_aaS.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Postgrix_aaS.Repo, {:shared, self()})
    end

    :ok
  end
end
