defmodule InternalDB.RepoCase do
  use ExUnit.Case
  use ExUnit.CaseTemplate
  alias InternalDB.{Repo, API}

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    :ok
  end

  defp addInstance(ip, port, db_name, instance_id) do
    qry = "INSERT INTO instances VALUES (DEFAULT, $1, $2, $3, $4);"

    Ecto.Adapters.SQL.query!(Repo, qry, [ip, port, db_name, instance_id])
  end

  defp addBinding(ip, port, db_name, instance_id, binding_id) do
    addInstance(ip, port, db_name, instance_id)
    qry = "INSERT INTO bindings VALUES (DEFAULT, $1, $2);"
    Ecto.Adapters.SQL.query!(Repo, qry, [binding_id, instance_id])
  end

  test "querying all instances and adding a new instance" do
    ip = %Postgrex.INET{address: {127, 0, 0, 1}}
    port = 5432
    db_name = "testdb"
    instance_id = "instance1"

    assert [] = API.instances()

    API.addInstance(ip, port, db_name, instance_id)

    assert [{ip, port, db_name, instance_id}] == API.instances()
  end

  test "adding a new instance with an invalid IP" do
    ip = "invalid"
    port = 5432
    db_name = "testdb"
    instance_id = "instance1"
    API.addInstance(ip, port, db_name, instance_id)
    assert [] == API.instances()
  end

  test "removing an instance" do
    ip = %Postgrex.INET{address: {127, 0, 0, 1}}
    port = 5432
    db_name = "testdb"
    instance_id = "instance1"
    binding_id = "i1binding1"

    addBinding(ip, port, db_name, instance_id, binding_id)

    API.removeInstance(instance_id)

    assert [] == API.instances()
    assert [] == API.bindings()
  end

  test "retrieving an instance" do
    ip = %Postgrex.INET{address: {127, 0, 0, 1}}
    port = 5432
    db_name = "testdb"
    instance_id = "instance1"

    addInstance(ip, port, db_name, instance_id)

    case API.getInstance(instance_id) do
      %{
        ip: %Postgrex.INET{address: {127, 0, 0, 1}},
        port: 5432,
        db_name: "testdb",
        instance_id: "instance1"
      } ->
        assert true

      _ ->
        assert false
    end
  end

  test "querying all bindings and adding a new binding" do
    ip = %Postgrex.INET{address: {127, 0, 0, 1}}
    port = 5432
    db_name = "testdb"
    instance_id = "instance1"
    binding_id = "i1binding1"

    assert [] = API.bindings()

    addInstance(ip, port, db_name, instance_id)
    API.addBinding(instance_id, binding_id)

    assert [{instance_id, binding_id}] == API.bindings()
  end

  test "removing a binding" do
    ip = %Postgrex.INET{address: {127, 0, 0, 1}}
    port = 5432
    db_name = "testdb"
    instance_id = "instance1"
    binding_id = "i1binding1"

    addBinding(ip, port, db_name, instance_id, binding_id)
    API.removeBinding(binding_id)

    assert [] = API.bindings()
  end

  test "retrieving a binding" do
    ip = %Postgrex.INET{address: {127, 0, 0, 1}}
    port = 5432
    db_name = "testdb"
    instance_id = "instance1"
    binding_id = "i1binding1"

    addBinding(ip, port, db_name, instance_id, binding_id)

    case API.getBinding(binding_id) do
      %{binding_id: "i1binding1", instance_id: "instance1"} ->
        assert true

      _ ->
        assert false
    end
  end
end
