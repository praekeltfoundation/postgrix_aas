defmodule PostgrixCluster.Server.Test do
use ExUnit.Case
alias PostgrixCluster.Server, as: Server
alias PostgrixCluster.API, as: ClusterAPI
alias InternalDB.API, as: InternalDBAPI
alias InternalDB.Repo, as: Repo

setup tags do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

  unless tags[:async] do
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
  end

  on_exit(fn ->
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    {:ok, result} = Server.start_link(name: Cluster.Server)
    db_name = "test1"
    instance_id = "instance_id"
    Server.rollbackProvision(Cluster.Server, db_name, instance_id)
  end)

  {:ok, result} = Server.start_link(name: ClusterAPI.Server)
  :ok
end

test "successfully provision a database instance and update internal records" do
  ip = "127.0.0.1"
  port = 5433
  db_name = "test1"
  instance_id = "instance_id"
  vault_user = "vault"
  vault_pass = "pass"
  db_owner = "owner"
  owner_pass = "pass"
  Server.provision(ClusterAPI.Server, [ip: ip, port: port, db_name: db_name, instance_id: instance_id, vault_user: vault_user, vault_pass: vault_pass, db_owner: db_owner, owner_pass: owner_pass])
  assert InternalDBAPI.getInstance(instance_id) != nil
end

test "unsuccessfully provision a database instance" do
  ip = "badvalue"
  port = 5433
  db_name = "test1"
  instance_id = "instance_id"
  vault_user = "vault"
  vault_pass = "pass"
  db_owner = "owner"
  owner_pass = "pass"
  result = Server.provision(ClusterAPI.Server, [ip: ip, port: port, db_name: db_name, instance_id: instance_id, vault_user: vault_user, vault_pass: vault_pass, db_owner: db_owner, owner_pass: owner_pass])
  assert InternalDBAPI.getInstance(instance_id) == nil
  state = GenServer.call(ClusterAPI.Server, {:_getstate})
  assert ClusterAPI.databaseExists!(state.pid, db_name) == false
end

end
