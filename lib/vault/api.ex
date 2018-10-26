defmodule Vault.API do
  import Vaultix

  @moduledoc """
  Provides functions that interact with Vault
  to manage dynamic credentials with databases.
  """

  # this is for bind
  # use gatekeeper location for now
  def equipBindPolicy(policy_name, role_name) do
    path = "secret/gatekeeper"

    {:ok, data} =
      Vaultix.Client.read(
        path,
        :token,
        {Application.get_env(:postgrix_aas, Vault, :token)[:token]}
      )

    policies = Jason.decode!(data)
    policy = policies[policy_name]

    if policy == None do
      policy = Jason.encode!(%{"roles" => role_name, "ttl" => 5000, "num_uses" => 1})
    else
      current = policy["roles"]
      [role_name | current]
      policy = current
    end

    Map.update!(policies, policy_name, policy)

    Vaultix.Client.write(
      path,
      policy,
      :token,
      {Application.get_env(:postgrix_aas, Vault, :token)[:token]}
    )
  end

  # add vault internal policy to get perms to read creds from role
  def addVaultPolicy(policy_name, role_name) do
    path = "sys/policy/#{policy_name}"
    policy = "path \"database/roles/#{role_name}\"{capabilities = [\"read\", \"list\"]}"
    payload = %{"policy" => policy}

    Vaultix.Client.write(
      path,
      payload,
      :token,
      {Application.get_env(:postgrix_aas, Vault, :token)[:token]}
    )
  end

  def addDatabase(conn_name, host, port, db_name, vault_user, vault_pass, allowed_roles) do
    path = "database/config/#{conn_name}"
    plugin_name = "postgresql-database-plugin"
    connection_url = "postgresql://{{username}}:{{password}}@#{host}:#{port}/#{db_name}"

    payload = %{
      "plugin_name" => plugin_name,
      "allowed_roles" => allowed_roles,
      "connection_url" => connection_url,
      "username" => vault_user,
      "password" => vault_pass
    }

    Vaultix.Client.write(
      path,
      payload,
      :token,
      {Application.get_env(:postgrix_aas, Vault, :token)[:token]}
    )
  end

  def addRole(role_name, creation_statements, revocation_statements, default_ttl, max_ttl) do
    path = "database/roles/#{role_name}"
    db_type = "postgresql"

    payload = %{
      "db_name" => db_type,
      "creation_statements" => creation_statements,
      "revocation_statements" => revocation_statements,
      "default_ttl" => default_ttl,
      "max_ttl" => max_ttl
    }

    Vaultix.Client.write(
      path,
      payload,
      :token,
      {Application.get_env(:postgrix_aas, Vault, :token)[:token]}
    )
  end

  def addReadOnlyRole(role_name, owner, default_ttl, max_ttl) do
    creation_statements =
      "CREATE ROLE \"{{name}}\" WITH LOGIN ENCRYPTED PASSWORD '{{password}}' VALID UNTIL '{{expiration}}' IN ROLE \"#{
        owner
      }\" INHERIT NOCREATEROLE NOCREATEDB NOSUPERUSER NOREPLICATION; GRANT USAGE ON SCHEMA public TO \"{{name}}\"; GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO \"{{name}}\"; GRANT ALL ON ALL SEQUENCES IN SCHEMA public to \"{{name}}\";"

    revocation_statements =
      "REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public from \"{{name}}\"; REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public from \"{{name}}\"; REVOKE ALL PRIVILEGES ON SCHEMA public from \"{{name}}\"; DROP ROLE IF EXISTS \"{{name}}\";"

    addRole(role_name, creation_statements, revocation_statements, default_ttl, max_ttl)
  end

  def addReadWriteRole(role_name, owner, default_ttl, max_ttl) do
    creation_statements =
      "CREATE ROLE \"{{name}}\" WITH LOGIN ENCRYPTED PASSWORD '{{password}}' VALID UNTIL '{{expiration}}' IN ROLE \"#{
        owner
      }\" INHERIT NOCREATEROLE NOCREATEDB NOSUPERUSER NOREPLICATION; GRANT USAGE ON SCHEMA public TO \"{{name}}\"; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\"; GRANT ALL ON ALL SEQUENCES IN SCHEMA public to \"{{name}}\";"

    revocation_statements =
      "REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public from \"{{name}}\"; REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public from \"{{name}}\"; REVOKE ALL PRIVILEGES ON SCHEMA public from \"{{name}}\"; DROP ROLE IF EXISTS \"{{name}}\";"

    addRole(role_name, creation_statements, revocation_statements, default_ttl, max_ttl)
  end

  # this needs to roll back if any intermediate steps fail?
  def provision(host, port, db_name, vault_user, vault_pass, owner, default_ttl, max_ttl) do
    conn_name = "postgresql--#{host}--#{port}--#{db_name}"
    role_name_r = "#{host}--#{port}--#{db_name}--readonly"
    role_name_rw = "#{host}--#{port}--#{db_name}--readwrite"
    policy_name_r = "postgresql--#{host}--#{port}--#{db_name}--readonly"
    policy_name_rw = "postgresql--#{host}--#{port}--#{db_name}--readwrite"
    allowed_roles = [role_name_r, role_name_rw]

    with {:ok, result} <-
           addDatabase(conn_name, host, port, db_name, vault_user, vault_pass, allowed_roles),
         :ok <- addReadOnlyRole(role_name_r, owner, default_ttl, max_ttl),
         :ok <- addReadWriteRole(role_name_rw, owner, default_ttl, max_ttl),
         :ok <- addVaultPolicy(policy_name_r, role_name_r),
         :ok <- addVaultPolicy(policy_name_rw, role_name_rw) do
      :ok
    else
      _ ->
        rollbackProvision(conn_name, role_name_r, role_name_rw, policy_name_r, policy_name_rw)
        {:error, "Error setting up database for dynamic credentials with Vault"}
    end
  end

  def databaseExists?(conn_name) do
    path = "database/config/#{conn_name}"

    case Vaultix.Client.read(
           path,
           :token,
           {Application.get_env(:postgrix_aas, Vault, :token)[:token]}
         ) do
      {:ok, result} -> true
      {:error, reason} -> false
    end
  end

  def roleExists?(role_name) do
    path = "database/roles/#{role_name}"

    case Vaultix.Client.read(
           path,
           :token,
           {Application.get_env(:postgrix_aas, Vault, :token)[:token]}
         ) do
      {:ok, result} -> true
      {:error, reason} -> false
    end
  end

  def vaultPolicyExists?(policy_name) do
    path = "sys/policy/#{policy_name}"

    case Vaultix.Client.read(
           path,
           :token,
           {Application.get_env(:postgrix_aas, Vault, :token)[:token]}
         ) do
      {:ok, result} -> true
      {:error, reason} -> false
    end
  end

  def deleteConnection(conn_name) do
    path = "database/config/#{conn_name}"
    Vaultix.Client.delete(path, :token, {"myroot"})
  end

  def deleteRole(role_name) do
    path = "database/roles/#{role_name}"
    Vaultix.Client.delete(path, :token, {"myroot"})
  end

  def deleteVaultPolicy(policy_name) do
    path = "sys/policy/#{policy_name}"
    Vaultix.Client.delete(path, :token, {"myroot"})
  end

  defp rollbackProvision(conn_name, role_name_r, role_name_rw, policy_name_r, policy_name_rw) do
    with :ok <- deleteConnection(conn_name),
         :ok <- deleteRole(role_name_r),
         :ok <- deleteRole(role_name_rw),
         :ok <- deleteVaultPolicy(policy_name_r),
         :ok <- deleteVaultPolicy(policy_name_rw) do
      :ok
    else
      _ ->
        raise RuntimeError,
          message: "Critical error: Failed to roll back a failed Vault provision."
    end
  end
end
