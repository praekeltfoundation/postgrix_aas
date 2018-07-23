defmodule PostgrixCluster.API do
  @moduledoc """
  Provides functions that interact with the root database
  in a cluster and provisions new database instances.
  """

  def createDatabase(pid, db_name) do
    Postgrex.query(pid, "CREATE DATABASE #{db_name} WITH OWNER DEFAULT;", [])
  end

  def createSchema(pid, schema) do
    Postgrex.query(pid, "CREATE SCHEMA IF NOT EXISTS #{schema};", [])
  end

  def dropDatabase(pid, db_name) do
    Postgrex.transaction(
      pid,
      fn conn ->
        Postgrex.query(conn, "SELECT pg_terminate_backend(pg_stat_activity.pid)
                          FROM pg_stat_activity WHERE pg_stat_activity.datname = \'#{db_name}\'
                          AND pid <> pg_backend_pid();", [])
        Postgrex.query(conn, "DROP DATABASE IF EXISTS #{db_name};", [])
      end,
      []
    )
  end

  def databaseExists!(pid, db_name) do
    case Postgrex.query(
           pid,
           "SELECT 1 AS result FROM pg_database WHERE datname='#{db_name}';",
           []
         ) do
      {:ok, result} ->
        result.rows == [[1]]

      _ ->
        false
    end
  end

  def addVaultRole(pid, db_name, vault_user, vault_password) do
    Postgrex.transaction(
      pid,
      fn conn ->
        Postgrex.query(conn, "CREATE ROLE #{vault_user} WITH CREATEROLE
                              INHERIT LOGIN ENCRYPTED PASSWORD \'#{vault_password}\';", [])
        Postgrex.query(conn, "GRANT ALL PRIVILEGES ON DATABASE #{db_name} TO
                              #{vault_user} WITH GRANT OPTION;", [])
      end,
      []
    )
  end

  def dropVaultRole(pid, db_name, vault_user) do
    Postgrex.transaction(
      pid,
      fn conn ->
        Postgrex.query(
          conn,
          "REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public from #{vault_user};",
          []
        )

        Postgrex.query(
          conn,
          "REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public from #{vault_user};",
          []
        )

        Postgrex.query(conn, "REVOKE ALL PRIVILEGES ON SCHEMA public from #{vault_user};", [])

        Postgrex.query(
          conn,
          "REVOKE ALL PRIVILEGES ON DATABASE #{db_name} from #{vault_user};",
          []
        )

        Postgrex.query(conn, "DROP ROLE IF EXISTS #{vault_user}", [])
      end,
      []
    )
  end

  def roleExists!(pid, role) do
    case Postgrex.query(pid, "SELECT 1 FROM pg_roles WHERE rolname='#{role}';", []) do
      {:ok, result} -> result.rows == [[1]]
      _ -> false
    end
  end

  def addOwnerRole(pid, db_name, db_owner, owner_password) do
    Postgrex.transaction(
      pid,
      fn conn ->
        Postgrex.query(
          conn,
          "CREATE ROLE #{db_owner} WITH LOGIN ENCRYPTED PASSWORD \'#{owner_password}\';",
          []
        )

        Postgrex.query(conn, "ALTER DATABASE #{db_name} OWNER TO #{db_owner};", [])
        Postgrex.query(conn, "ALTER SCHEMA public OWNER TO #{db_owner};", [])
      end,
      []
    )
  end

  def grantOwnerRole(pid, db_owner, vault_user) do
    Postgrex.query(pid, "GRANT #{db_owner} TO #{vault_user};", [])
  end

  def hasRole!(pid, user, role) do
    case Postgrex.query(pid, "WITH RECURSIVE cte AS (
                              SELECT oid FROM pg_roles WHERE rolname = \'#{user}\'
                              UNION ALL SELECT m.roleid
                              FROM   cte
                              JOIN   pg_auth_members m ON m.member = cte.oid)
                              SELECT 1
                              FROM cte, pg_roles
                              WHERE cte.oid = pg_roles.oid
                              AND rolname = \'#{role}\';", []) do
      {:ok, result} -> result.rows == [[1]]
      _ -> false
    end
  end
end
