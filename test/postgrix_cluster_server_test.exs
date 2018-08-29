defmodule PostgrixCluster.Server.Test do
  use ExUnit.Case
  use ExUnit.CaseTemplate
  alias PostgrixCluster.Server, as: Server
  alias PostgrixCluster.API, as: ClusterAPI
  alias InternalDB.API, as: InternalDBAPI
  alias InternalDB.Repo

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    on_exit(fn ->
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
      Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
      {:ok, result} = Server.start_link(name: Cluster.Server)
      db_name = "test1"
      instance_id = "instance_id"
      db_owner = "owner"
      vault_user = "vault"
      Server.rollbackProvision(Cluster.Server, instance_id, db_name, db_owner, vault_user)
    end)

    {:ok, result} = Server.start_link(name: ClusterAPI.Server)
    :ok
  end

  test "test provisioning a database instance and updating internal records" do
    ip = "127.0.0.1"
    port = 5433
    db_name = "test1"
    instance_id = "instance_id"
    vault_user = "vault"
    vault_pass = "pass"
    db_owner = "owner"
    owner_pass = "pass"

    Server.provision(
      ClusterAPI.Server,
      ip: ip,
      port: port,
      db_name: db_name,
      instance_id: instance_id,
      vault_user: vault_user,
      vault_pass: vault_pass,
      db_owner: db_owner,
      owner_pass: owner_pass
    )

    assert InternalDBAPI.getInstance(instance_id) != nil
  end

  test "test rolling back all operations if provision fails at intermediate steps" do
    ip = "badvalue"
    port = 5433
    db_name = "test1"
    instance_id = "instance_id"
    vault_user = "vault"
    vault_pass = "pass"
    db_owner = "owner"
    owner_pass = "pass"

    result =
      Server.provision(
        ClusterAPI.Server,
        ip: ip,
        port: port,
        db_name: db_name,
        instance_id: instance_id,
        vault_user: vault_user,
        vault_pass: vault_pass,
        db_owner: db_owner,
        owner_pass: owner_pass
      )

    assert InternalDBAPI.getInstance(instance_id) == nil
    state = GenServer.call(ClusterAPI.Server, {:_getstate})
    assert ClusterAPI.databaseExists?(state.pid, db_name) == false
    assert ClusterAPI.roleExists?(state.pid, db_owner) == false
    assert ClusterAPI.roleExists?(state.pid, vault_user) == false
  end
end
