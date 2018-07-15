defmodule InternalDB.RepoCase do
  use ExUnit.Case
  use ExUnit.CaseTemplate
  alias InternalDB.{Repo, API, Host}

  using do
    quote do
      alias InternalDB.{Repo, API, Host}

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

  test "adding a new host" do
    assert [] == API.hosts

    API.addHost(%Postgrex.INET{address: {127, 0, 0, 1}}, "example.com")

    assert [{%Postgrex.INET{address: {127, 0, 0, 1}}, "example.com"}] == API.hosts
  end
end
