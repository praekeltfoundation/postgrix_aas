defmodule InternalDB.RepoCase do
  use ExUnit.Case
  use ExUnit.CaseTemplate
  alias InternalDB.{Repo, API}

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    end

    :ok
  end

  defp addHost(ip, hostname) do
    qry = "INSERT INTO hosts VALUES (DEFAULT, $1, $2);"
    Ecto.Adapters.SQL.query!(Repo, qry, [ip, hostname])
  end

  defp addCluster(ip, hostname, port) do
    addHost(ip, hostname)
    qry = "INSERT INTO clusters VALUES (DEFAULT, $1, $2);"
    Ecto.Adapters.SQL.query!(Repo, qry, [ip, port])
  end

  defp addInstance(ip, hostname, port, db_name, instance_id) do
    addCluster(ip, hostname, port)

    qry = "INSERT INTO instances VALUES (DEFAULT, $1, $2, $3, $4);"

    Ecto.Adapters.SQL.query!(Repo, qry, [ip, port, db_name, instance_id])
  end

  defp addBinding(ip, hostname, port, db_name, instance_id, binding_id) do
    addInstance(ip, hostname, port, db_name, instance_id)
    qry = "INSERT INTO bindings VALUES (DEFAULT, $1, $2);"
    Ecto.Adapters.SQL.query!(Repo, qry, [binding_id, instance_id])
  end

  test "querying all hosts and adding a new host" do
    ip = %Postgrex.INET{address: {127, 0, 0, 1}}
    hostname = "example.com"
    assert [] == API.hosts()

    API.addHost(ip, hostname)

    assert [{ip, hostname}] == API.hosts()
  end

  test "removing a host" do
    ip = %Postgrex.INET{address: {127, 0, 0, 1}}
    hostname = "example.com"
    port = 5432
    db_name = "testdb"
    instance_id = "instance1"
    binding_id = "i1binding1"

    addBinding(ip, hostname, port, db_name, instance_id, binding_id)

    API.removeHost(ip)

    assert [] == API.hosts()
    assert [] == API.clusters()
    assert [] == API.instances()
    assert [] == API.bindings()
  end

  test "retrieving a host" do
    ip = %Postgrex.INET{address: {127, 0, 0, 1}}
    hostname = "example.com"

    addHost(ip, hostname)

    case API.getHost(ip) do
      %{ip: %Postgrex.INET{address: {127, 0, 0, 1}}, hostname: "example.com"} ->
        assert true

      _ ->
        assert false
    end
  end

  test "querying all clusters and adding a new cluster" do
    ip = %Postgrex.INET{address: {127, 0, 0, 1}}
    hostname = "example.com"
    port = 5432

    assert [] = API.clusters()
    addHost(ip, hostname)

    API.addCluster(ip, port)

    assert [{ip, port}] == API.clusters()
  end

  test "removing a cluster" do
    ip = %Postgrex.INET{address: {127, 0, 0, 1}}
    hostname = "example.com"
    port = 5432
    db_name = "testdb"
    instance_id = "instance1"
    binding_id = "i1binding1"

    addBinding(ip, hostname, port, db_name, instance_id, binding_id)

    API.removeCluster(ip, port)

    assert [] == API.clusters()
    assert [] == API.instances()
    assert [] == API.bindings()
  end

  test "retrieving a cluster" do
    ip = %Postgrex.INET{address: {127, 0, 0, 1}}
    hostname = "example.com"
    port = 5432

    addCluster(ip, hostname, port)

    case API.getCluster(ip, port) do
      %{ip: %Postgrex.INET{address: {127, 0, 0, 1}}, port: 5432} ->
        assert true

      _ ->
        assert false
    end
  end

  test "querying all instances and adding a new instance" do
    ip = %Postgrex.INET{address: {127, 0, 0, 1}}
    hostname = "example.com"
    port = 5432
    db_name = "testdb"
    instance_id = "instance1"

    assert [] = API.instances()

    addCluster(ip, hostname, port)
    API.addInstance(ip, port, db_name, instance_id)

    assert [{ip, port, db_name, instance_id}] == API.instances()
  end

  test "removing an instance" do
    ip = %Postgrex.INET{address: {127, 0, 0, 1}}
    hostname = "example.com"
    port = 5432
    db_name = "testdb"
    instance_id = "instance1"
    binding_id = "i1binding1"

    addBinding(ip, hostname, port, db_name, instance_id, binding_id)

    API.removeInstance(instance_id)

    assert [] == API.instances()
    assert [] == API.bindings()
  end

  test "retrieving an instance" do
    ip = %Postgrex.INET{address: {127, 0, 0, 1}}
    hostname = "example.com"
    port = 5432
    db_name = "testdb"
    instance_id = "instance1"

    addInstance(ip, hostname, port, db_name, instance_id)

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
    hostname = "example.com"
    port = 5432
    db_name = "testdb"
    instance_id = "instance1"
    binding_id = "i1binding1"

    assert [] = API.bindings()

    addInstance(ip, hostname, port, db_name, instance_id)
    API.addBinding(instance_id, binding_id)

    assert [{instance_id, binding_id}] == API.bindings()
  end

  test "removing a binding" do
    ip = %Postgrex.INET{address: {127, 0, 0, 1}}
    hostname = "example.com"
    port = 5432
    db_name = "testdb"
    instance_id = "instance1"
    binding_id = "i1binding1"

    addBinding(ip, hostname, port, db_name, instance_id, binding_id)
    API.removeBinding(binding_id)

    assert [] = API.bindings()
  end

  test "retrieving a binding" do
    ip = %Postgrex.INET{address: {127, 0, 0, 1}}
    hostname = "example.com"
    port = 5432
    db_name = "testdb"
    instance_id = "instance1"
    binding_id = "i1binding1"

    addBinding(ip, hostname, port, db_name, instance_id, binding_id)

    case API.getBinding(binding_id) do
      %{binding_id: "i1binding1", instance_id: "instance1"} ->
        assert true

      _ ->
        assert false
    end
  end
end
