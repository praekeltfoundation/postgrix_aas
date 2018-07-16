defmodule InternalDB.RepoCase do
  use ExUnit.Case
  use ExUnit.CaseTemplate
  alias InternalDB.{Repo, API, Hosts, Clusters}

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    end

    :ok
  end

  defp addHost(ip, hostname) do
    qry = "INSERT INTO hosts VALUES (DEFAULT, '#{ip}', '#{hostname}');"
    Ecto.Adapters.SQL.query!(Repo, qry, [])
  end

  defp addCluster(ip, hostname, port) do
    addHost(ip, port)
    qry = "INSERT INTO clusters VALUES (DEFAULT, '#{ip}', #{port});"
    Ecto.Adapters.SQL.query!(Repo, qry, [])
  end

  defp addInstance(ip, hostname, port, db_name, instance_id) do
    addCluster(ip, hostname, port)
    qry = "INSERT INTO instances VALUES (DEFAULT, '#{ip}', #{port}, '#{db_name}', '#{instance_id}');"
    Ecto.Adapters.SQL.query!(Repo, qry, [])
  end

  test "querying all hosts and adding a new host" do
    ip = %Postgrex.INET{address: {127,0,0,1}}
    hostname = "example.com"
    assert [] == API.hosts

    API.addHost(ip, hostname)

    assert [{ip, hostname}] == API.hosts
  end

  test "querying all clusters and adding a new cluster" do
    ip = %Postgrex.INET{address: {127,0,0,1}}
    hostname = "example.com"
    port = 5432

    assert [] = API.clusters
    addHost(ip, hostname)

    API.addCluster(ip, port)

    assert [{ip, port}] == API.clusters
  end

  test "querying all instances and adding a new instance" do
    ip = %Postgrex.INET{address: {127,0,0,1}}
    hostname = "example.com"
    port = 5432
    db_name = "testdb"
    instance_id = "instance1"

    assert [] = API.instances

    addCluster(ip, hostname, port)
    API.addInstance(ip, port, db_name, instance_id)

    assert [{ip, port, db_name, instance_id}] == API.instances
  end

  test "querying all bindings and adding a new binding" do
    ip = %Postgrex.INET{address: {127,0,0,1}}
    hostname = "example.com"
    port = 5432
    db_name = "testdb"
    instance_id = "instance1"
    binding_id = "i1binding1"

    assert [] = API.bindings

    addInstance(ip, hostname, port, db_name, instance_id)
    API.addBinding(instance_id, binding_id)

    assert [{instance_id, binding_id}] == API.bindings
  end

end
