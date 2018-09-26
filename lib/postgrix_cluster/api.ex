defmodule PostgrixCluster.API do
  @moduledoc """
  Provides functions that interact with the root database
  in a cluster and provisions new database instances.
  """

  def createDatabase(pid, db_name) do
    with true <- isValid?(db_name),
         {:ok, result} <-
           Postgrex.query(pid, "CREATE DATABASE #{db_name} WITH OWNER DEFAULT;", []) do
      {:ok, result}
    else
      _ -> {:error, "Error creating database."}
    end
  end

  def schemaExists?(pid, schema) do
    with true <- isValid?(schema),
         {:ok, result} <-
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

  def createSchema(pid, schema) do
    with true <- isValid?(schema),
         true <- schemaExists?(pid, schema),
         {:ok, result} <- Postgrex.query(pid, "CREATE SCHEMA #{schema};", []) do
      {:ok, result}
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, "Error creating schema"}
    end
  end

  def dropDatabase(pid, db_name) do
    with true <- isValid?(db_name),
         {:ok, result} <- Postgrex.query(pid, "SELECT pg_terminate_backend(pg_stat_activity.pid)
                      FROM pg_stat_activity WHERE pg_stat_activity.datname = '#{db_name}'
                      AND pid <> pg_backend_pid();", []),
         {:ok, result} <- Postgrex.query(pid, "DROP DATABASE IF EXISTS #{db_name};", []) do
      {:ok, result}
    else
      _ -> {:error, "Error dropping database."}
    end
  end

  def databaseExists?(pid, db_name) do
    with true <- isValid?(db_name) do
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
    else
      _ -> false
    end
  end

  def addVaultRole(pid, db_name, vault_user, vault_password) do
    with true <- isValid?(db_name),
         true <- isValid?(vault_user),
         true <- isValid?(vault_password),
         {:ok, result} <-
           Postgrex.transaction(
             pid,
             fn conn ->
               Postgrex.query(conn, "CREATE ROLE #{vault_user} WITH CREATEROLE
                              INHERIT LOGIN ENCRYPTED PASSWORD '#{vault_password}';", [])
               Postgrex.query(conn, "GRANT ALL PRIVILEGES ON DATABASE #{db_name} TO
                              #{vault_user} WITH GRANT OPTION;", [])
             end,
             []
           ) do
      {:ok, result}
    else
      _ -> {:error, "Error adding Vault role."}
    end
  end

  def dropVaultRole(pid, db_name, vault_user) do
    with true <- isValid?(db_name),
         true <- isValid?(vault_user),
         {:ok, result} <-
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

               Postgrex.query(
                 conn,
                 "REVOKE ALL PRIVILEGES ON SCHEMA public from #{vault_user};",
                 []
               )

               Postgrex.query(
                 conn,
                 "REVOKE ALL PRIVILEGES ON DATABASE #{db_name} from #{vault_user};",
                 []
               )

               Postgrex.query(conn, "DROP ROLE IF EXISTS #{vault_user}", [])
             end,
             []
           ) do
      {:ok, result}
    else
      _ -> {:error, "Error dropping Vault role."}
    end
  end

  def roleExists?(pid, role) do
    with true <- isValid?(role) do
      case Postgrex.query(pid, "SELECT 1 FROM pg_roles WHERE rolname='#{role}';", []) do
        {:ok, result} -> result.rows == [[1]]
        {:error, reason} -> raise RuntimeError, message: reason
        _ -> false
      end
    else
      _ -> raise ArgumentError, message: "Argument to function contains disallowed characters."
    end
  end

  def addOwnerRole(pid, db_name, db_owner, owner_password) do
    with true <- isValid?(db_name),
         true <- isValid?(db_owner),
         true <- isValid?(owner_password),
         {:ok, result} <-
           Postgrex.transaction(
             pid,
             fn conn ->
               Postgrex.query(
                 conn,
                 "CREATE ROLE #{db_owner} WITH LOGIN ENCRYPTED PASSWORD '#{owner_password}';",
                 []
               )

               Postgrex.query(conn, "ALTER DATABASE #{db_name} OWNER TO #{db_owner};", [])
               Postgrex.query(conn, "ALTER SCHEMA public OWNER TO #{db_owner};", [])
             end,
             []
           ) do
      {:ok, result}
    else
      _ -> {:error, "Error adding owner role to database."}
    end
  end

  def grantOwnerRole(pid, db_owner, vault_user) do
    with true <- isValid?(db_owner),
         true <- isValid?(vault_user),
         {:ok, result} <- Postgrex.query(pid, "GRANT #{db_owner} TO #{vault_user};", []) do
      {:ok, result}
    else
      _ -> {:error, "Error granting owner role to target role."}
    end
  end

  def hasRole?(pid, user, role) do
    with true <- isValid?(user),
         true <- isValid?(role) do
      case Postgrex.query(pid, "WITH RECURSIVE cte AS (
                              SELECT oid FROM pg_roles WHERE rolname = '#{user}'
                              UNION ALL SELECT m.roleid
                              FROM   cte
                              JOIN   pg_auth_members m ON m.member = cte.oid)
                              SELECT 1
                              FROM cte, pg_roles
                              WHERE cte.oid = pg_roles.oid
                              AND rolname = '#{role}';", []) do
        {:ok, result} -> result.rows == [[1]]
        _ -> false
      end
    else
      _ -> false
    end
  end

  def dropRole(pid, role) do
    with true <- isValid?(role),
         {:ok, result} <- Postgrex.query(pid, "DROP ROLE IF EXISTS #{role};", []) do
      {:ok, result}
    else
      _ -> {:error, "Error dropping role."}
    end
  end

  # Applies a word-only whitelist for values passed to Postgres
  def isValid?(value) do
    Regex.match?(~r/^\w+$/, value)
  end
end
