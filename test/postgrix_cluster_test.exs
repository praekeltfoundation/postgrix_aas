defmodule PostgrixCluster.Test do
  use ExUnit.Case
  use ExUnit.CaseTemplate
  alias PostgrixCluster.{API}

  using do
    quote do
      import Ecto
      import Ecto.Query
    end
  end

  setup do
    db_name = "testdb"
    schema = "public"
    vault_user = "vault"
    db_owner = "owner"
    hostname = "localhost"

    port =
      cond do
        Mix.env() == :dev ->
          5433

        Mix.env() == :test ->
          5432

        true ->
          5432
      end

    username = "postgres"
    password = "mysecretpassword2"
    database = "postgres_cluster"

    on_exit(fn ->
      {:ok, pid} =
        Postgrex.start_link(
          hostname: hostname,
          port: port,
          username: username,
          password: password,
          database: database
        )

      dropSchema(pid, schema)
      dropDatabase(pid, db_name)
      dropRole(pid, vault_user)
      dropRole(pid, db_owner)
    end)

    {:ok, pid} =
      start_supervised(
        {Postgrex,
         [
           hostname: hostname,
           port: port,
           username: username,
           password: password,
           database: database,
           pool_size: 20,
           pool_timeout: 15_000,
           timeout: 15_000
         ]}
      )

    {:ok, pid: pid}
  end

  defp roleExists?(pid, role) do
    case Postgrex.query!(pid, "SELECT 1 FROM pg_roles WHERE rolname='#{role}';", []) do
      {:ok, result} -> result.rows == [[1]]
      _ -> false
    end
  end

  defp schemaExists?(pid, schema) do
    with {:ok, result} <-
           Postgrex.query(
             pid,
             "SELECT schema_name FROM information_schema.schemata WHERE schema_name = '#{schema}';",
             []
           ) do
      result.rows == [[1]]
    else
      _ -> {:error, "Error checking if schema exists."}
    end
  end

  defp dropRole(pid, role) do
    Postgrex.query(pid, "DROP ROLE IF EXISTS #{role};", [])
  end

  defp createDatabase(pid, db_name) do
    Postgrex.query(pid, "CREATE DATABASE #{db_name} WITH OWNER DEFAULT;", [])
  end

  defp dropDatabase(pid, db_name) do
    Postgrex.query(pid, "DROP DATABASE IF EXISTS #{db_name};", [])
  end

  defp createSchema(pid, schema) do
    if !schemaExists?(pid, schema) do
      Postgrex.query(pid, "CREATE SCHEMA #{schema};", [])
    end
  end

  defp dropSchema(pid, schema) do
    Postgrex.query(pid, "DROP SCHEMA IF EXISTS #{schema};", [])
  end

  defp addVaultRole(pid, db_name, vault_user, vault_password) do
    Postgrex.transaction(
      pid,
      fn conn ->
        Postgrex.query(conn, "CREATE ROLE #{vault_user} WITH CREATEROLE
                              INHERIT LOGIN ENCRYPTED PASSWORD '#{vault_password}';", [])
        Postgrex.query(conn, "GRANT ALL PRIVILEGES ON DATABASE #{db_name} TO
                              #{vault_user} WITH GRANT OPTION;", [])
      end
    )
  end

  test "create a database", context do
    db_name = "testdb"
    pid = context[:pid]

    API.createDatabase(pid, db_name)
    assert API.databaseExists?(pid, db_name) == true
  end

  test "add Vault master role", context do
    db_name = "testdb"
    schema = "public"
    vault_user = "vault"
    vault_password = "vaultpass"
    pid = context[:pid]

    createDatabase(pid, db_name)
    createSchema(pid, schema)
    API.addVaultRole(pid, db_name, vault_user, vault_password)
    assert API.roleExists?(pid, vault_user) == true
  end

  test "check if schema exists", context do
    db_name = "testdb"
    schema = "public"
    vault_user = "vault"
    vault_password = "vaultpass"
    pid = context[:pid]
    assert API.schemaExists?(pid, schema) == false
    createDatabase(pid, db_name)
    createSchema(pid, schema)

    assert API.schemaExists?(pid, schema) == true
  end

  test "add an owner role, grant the owner role to the Vault user", context do
    db_name = "testdb"
    schema = "public"
    vault_user = "vault"
    vault_password = "vaultpass"
    db_owner = "owner"
    owner_pass = "ownerpass"
    pid = context[:pid]

    API.createDatabase(pid, db_name)
    API.createSchema(pid, schema)
    API.addVaultRole(pid, db_name, vault_user, vault_password)

    API.addOwnerRole(pid, db_name, db_owner, owner_pass)
    pid = context[:pid]

    API.grantOwnerRole(pid, db_owner, vault_user)
    assert API.hasRole?(pid, vault_user, db_owner) == true
  end

  test "create and drop a database", context do
    db_name = "testdb"
    pid = context[:pid]
    createDatabase(pid, db_name)

    assert API.databaseExists?(pid, db_name) == true

    API.dropDatabase(pid, db_name)

    assert API.databaseExists?(pid, db_name) == false
  end

  test "create and drop Vault role", context do
    db_name = "testdb"
    vault_user = "vault"
    vault_password = "vaultpass"
    schema = "public"
    pid = context[:pid]
    API.createDatabase(pid, db_name)
    API.createSchema(pid, schema)
    API.addVaultRole(pid, db_name, vault_user, vault_password)
    assert API.roleExists?(pid, vault_user) == true

    API.dropVaultRole(pid, db_name, vault_user)
    assert API.roleExists?(pid, vault_user) == false
  end

  test "create and drop owner role", context do
    db_name = "testdb"
    db_owner = "owner"
    owner_pass = "ownerpass"
    schema = "public"
    pid = context[:pid]
    API.createDatabase(pid, db_name)
    API.createSchema(pid, schema)
    assert API.roleExists?(pid, db_owner) == false
    API.addOwnerRole(pid, db_name, db_owner, owner_pass)
    assert API.roleExists?(pid, db_owner) == true
    API.dropDatabase(pid, db_name)
    API.dropRole(pid, db_owner)
    assert API.roleExists?(pid, db_owner) == false
  end

  test "test that parameter validation only allows words", context do
    assert API.isValid?("testword") == true

    assert API.isValid?("test_word") == true

    assert API.isValid?("'--test;") == false
  end
end
