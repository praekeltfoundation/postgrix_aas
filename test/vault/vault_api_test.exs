defmodule Vault.API.Test do
  use ExUnit.Case
  alias Vault.API
  import Vaultix

  setup tags do
    :ok

    on_exit(fn ->
      host = Application.get_env(:postgrix_aas, Vault, :cluster_db)[:cluster_db]
      port = 5432
      db_name = "postgres_cluster"
      role_name_r = "#{host}--#{port}--#{db_name}--readonly"
      role_name_rw = "#{host}--#{port}--#{db_name}--readwrite"
      policy_name_r = "postgresql--#{host}--#{port}--#{db_name}--readonly"
      policy_name_rw = "postgresql--#{host}--#{port}--#{db_name}--readwrite"
      owner = "owner"
      default_ttl = "30m"
      max_ttl = "6h"
      conn_name = "postgresql--#{host}--#{port}--#{db_name}"
      API.deleteConnection("testconnection")
      API.deleteConnection(conn_name)
      API.deleteVaultPolicy(policy_name_r)
      API.deleteVaultPolicy(policy_name_rw)
      API.deleteRole(role_name_r)
      API.deleteRole(role_name_rw)
    end)
  end

  defp deleteAllConnections() do
    path = "database/config/*"
    Vaultix.Client.delete(path, :token, {"myroot"})
  end

  test "Add a database to Vault" do
    conn_name = "testconnection"
    host = Application.get_env(:postgrix_aas, Vault, :cluster_db)[:cluster_db]
    port = 5432
    db_name = "postgres_cluster"
    vault_user = "postgres"
    vault_pass = "mysecretpassword2"
    allowed_roles = ["#{host}--#{port}--#{db_name}--readwrite", "#{host}--#{port}--#{db_name}--readonly"]
    path = "database/config/#{conn_name}"
    API.addDatabase(conn_name, host, port, db_name, vault_user, vault_pass, allowed_roles)
    assert API.databaseExists?(conn_name) == true
  end

  test "Add a read/write Postgres database role" do
    conn_name = "testconnection"
    host = Application.get_env(:postgrix_aas, Vault, :cluster_db)[:cluster_db]
    port = 5432
    db_name = "postgres_cluster"
    role_name = "#{host}--#{port}--#{db_name}--readwrite"
    owner = "owner"
    vault_user = "postgres"
    vault_pass = "mysecretpassword2"
    default_ttl = "30m"
    max_ttl = "6h"
    allowed_roles = ["#{host}--#{port}--#{db_name}--readwrite", "#{host}--#{port}--#{db_name}--readonly"]
    assert API.roleExists?(role_name) == false
    API.addDatabase(conn_name, host, port, db_name, vault_user, vault_pass, allowed_roles)
    API.addReadWriteRole(role_name, owner, default_ttl, max_ttl)
    assert API.roleExists?(role_name) == true
  end

  test "Add a read-only Postgres database role" do
    conn_name = "testconnection"
    host = Application.get_env(:postgrix_aas, Vault, :cluster_db)[:cluster_db]
    port = 5432
    db_name = "postgres_cluster"
    role_name = "#{host}--#{port}--#{db_name}--readonly"
    owner = "owner"
    vault_user = "postgres"
    vault_pass = "mysecretpassword2"
    default_ttl = "30m"
    max_ttl = "6h"
    allowed_roles = ["#{host}--#{port}--#{db_name}--readwrite", "#{host}--#{port}--#{db_name}--readonly"]
    assert API.roleExists?(role_name) == false
    API.addDatabase(conn_name, host, port, db_name, vault_user, vault_pass, allowed_roles)
    API.addReadWriteRole(role_name, owner, default_ttl, max_ttl)
    assert API.roleExists?(role_name) == true
  end

  test "Add a Vault ACL for access to database creds" do
    host = Application.get_env(:postgrix_aas, Vault, :cluster_db)[:cluster_db]
    port = 5432
    db_name = "postgres_cluster"
    policy_name = "postgresql--#{host}--#{port}--#{db_name}--readwrite"
    role_name = "#{host}--#{port}--#{db_name}--readwrite"
    API.addVaultPolicy(policy_name, role_name)
    assert API.vaultPolicyExists?(policy_name) == true
  end

  test "Register a newly-provisioned database instance for dynamic credentials" do
    host = Application.get_env(:postgrix_aas, Vault, :cluster_db)[:cluster_db]
    port = 5432
    db_name = "postgres_cluster"
    vault_user = "postgres"
    vault_pass = "mysecretpassword2"
    owner = "owner"
    default_ttl = "30m"
    max_ttl = "6h"
    conn_name = "postgresql--#{host}--#{port}--#{db_name}"
    role_name_r = "#{host}--#{port}--#{db_name}--readonly"
    role_name_rw = "#{host}--#{port}--#{db_name}--readwrite"
    policy_name_r = "postgresql--#{host}--#{port}--#{db_name}--readonly"
    policy_name_rw = "postgresql--#{host}--#{port}--#{db_name}--readwrite"
    assert API.databaseExists?(conn_name) == false
    assert API.roleExists?(role_name_r) == false
    assert API.roleExists?(role_name_rw) == false
    assert API.vaultPolicyExists?(policy_name_r) == false
    assert API.vaultPolicyExists?(policy_name_rw) == false
    API.provision(host, port, db_name, vault_user, vault_pass, owner, default_ttl, max_ttl)
    assert API.databaseExists?(conn_name) == true
    assert API.roleExists?(role_name_r) == true
    assert API.roleExists?(role_name_rw) == true
    assert API.vaultPolicyExists?(policy_name_r) == true
    assert API.vaultPolicyExists?(policy_name_rw) == true
  end

  test "Roll back a Vault provision if any of the intermediate steps fail" do
    host = Application.get_env(:postgrix_aas, Vault, :cluster_db)[:cluster_db]
    port = 5432
    db_name = "invalid"
    vault_user = "postgres"
    vault_pass = "mysecretpassword2"
    owner = "owner"
    default_ttl = "30m"
    max_ttl = "6h"
    conn_name = "postgresql--#{host}--#{port}--#{db_name}"
    role_name_r = "#{host}--#{port}--#{db_name}--readonly"
    role_name_rw = "#{host}--#{port}--#{db_name}--readwrite"
    policy_name_r = "postgresql--#{host}--#{port}--#{db_name}--readonly"
    policy_name_rw = "postgresql--#{host}--#{port}--#{db_name}--readwrite"
    assert API.databaseExists?(conn_name) == false
    assert API.roleExists?(role_name_r) == false
    assert API.roleExists?(role_name_rw) == false
    assert API.vaultPolicyExists?(policy_name_r) == false
    assert API.vaultPolicyExists?(policy_name_rw) == false
    API.provision(host, port, db_name, vault_user, vault_pass, owner, default_ttl, max_ttl)
    assert API.databaseExists?(conn_name) == false
    assert API.roleExists?(role_name_r) == false
    assert API.roleExists?(role_name_rw) == false
    assert API.vaultPolicyExists?(policy_name_r) == false
    assert API.vaultPolicyExists?(policy_name_rw) == false
  end



end
