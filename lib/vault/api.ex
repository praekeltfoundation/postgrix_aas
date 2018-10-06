defmodule Vaul.API do
import Vaultex
  @moduledoc """
  Provides functions that interact with Vault
  to manage dynamic credentials with databases.
  """

  #this is for bind
  #use gatekeeper location for now
  def equipBindPolicy(policy_name, role_name) do
    path = "/secret/gatekeeper"
    {:ok, data} = Vaultex.Client.read(path)
    policies = Jason.decode!(data)
    policy = policies[policy_name]
    if policy == None do
      policy = Jason.encode!(%{"roles" => role_name,
                            "ttl" => 5000,
                            "num_uses" => 1})
    else
      current = policy["roles"]
      [role_name | current]
      policy = current
    end
    Map.update!(policies, policy_name, policy)
    Vaultex.Client.write(path, policy)
  end

  #add vault internal policy to get perms to read creds from role
  def addVaultPolicy(policy_name, role_name) do
    path = "/sys/policy/" + policy_name
    policy = "path \"database/roles/" + role_name + "\"" + "{capabilities = [\"read\", \"list\"]}"
    payload = %{"policy" => policy}
    Vaultex.Client.write(path, payload)
  end

  def addDatabase(conn_name, url, port, db_name, vault_user, vault_pass, allowed_roles) do
    path = "database/config/" + conn_name
    plugin_name = "postgresql-database-plugin"
    connection_url = "postgresql://" + vault_user + ":" + vault_pass + "@" + url + ":" + port + "/" + db_name
    payload = %{"plugin_name" => plugin_name,
                "allowed_roles" => allowed_roles,
                "connection_url" => connection_url}
    Vaultex.Client.write(path, payload)
  end

  def addRole(role_name, creation_statements, revocation_statements, default_ttl, max_ttl) do
    path = "database/roles/" + role_name
    db_type = "postgresql"
    payload = %{"db_name" => db_type,
                "creation_statements" => creation_statements,
                "revocation_statements" => revocation_statements,
                "default_ttl" => default_ttl,
                "max_ttl" => max_ttl}
    Vaultex.Client.write(path, payload)
  end

  def addReadOnlyRole(role_name, owner, default_ttl, max_ttl) do
    creation_statements = "CREATE ROLE \"{{name}}\" WITH LOGIN ENCRYPTED PASSWORD '{{password}}' VALID UNTIL '{{expiration}}' IN ROLE \"" + role_name + "\" INHERIT NOCREATEROLE NOCREATEDB NOSUPERUSER NOREPLICATION; GRANT USAGE ON SCHEMA public TO \"{{name}}\"; GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO \"{{name}}\"; GRANT ALL ON ALL SEQUENCES IN SCHEMA public to \"{{name}}\";"
    revocation_statements = "REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public from \"{{name}}\"; REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public from \"{{name}}\"; REVOKE ALL PRIVILEGES ON SCHEMA public from \"{{name}}\"; DROP ROLE IF EXISTS \"{{name}}\";"
    addRole(role_name, creation_statements, revocation_statements, default_ttl, max_ttl)
  end

  def addReadWriteRole(role_name, owner, default_ttl, max_ttl) do
    creation_statements = "CREATE ROLE \"{{name}}\" WITH LOGIN ENCRYPTED PASSWORD '{{password}}' VALID UNTIL '{{expiration}}' IN ROLE \"" + role_name + "\" INHERIT NOCREATEROLE NOCREATEDB NOSUPERUSER NOREPLICATION; GRANT USAGE ON SCHEMA public TO \"{{name}}\"; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\"; GRANT ALL ON ALL SEQUENCES IN SCHEMA public to \"{{name}}\";"
    revocation_statements = "REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public from \"{{name}}\"; REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public from \"{{name}}\"; REVOKE ALL PRIVILEGES ON SCHEMA public from \"{{name}}\"; DROP ROLE IF EXISTS \"{{name}}\";"
    addRole(role_name, creation_statements, revocation_statements, default_ttl, max_ttl)
  end

  def provision(instance_id, url, port, db_name, vault_user, vault_pass, owner, default_ttl, max_ttl) do
    role_name_r = url + "--" + port + "--" + db_name + "--" + "readonly"
    role_name_rw = url + "--" + port + "--" + db_name + "--" + "readwrite"
    allowed_roles = [role_name_r, role_name_rw]
    addDatabase(instance_id, url, port, db_name, vault_user, vault_pass, allowed_roles)
    addReadOnlyRole(role_name_r, owner, default_ttl, max_ttl)
    addReadWriteRole(role_name_rw, owner, default_ttl, max_ttl)
  end

end
