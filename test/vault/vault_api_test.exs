defmodule Vault.API.Test do
  use ExUnit.Case
  alias Vault.API
  import Vaultex

  setup tags do
    :ok
  end

  test "Add a database to Vault" do
    conn_name = "testconnection"
    host = Application.get_env(:postgrix_aas, Vault, :cluster_db)[:cluster_db]
    port = 5432
    db_name = "postgres_cluster"
    vault_user = "postgres"
    vault_pass = "mysecretpassword2"
    allowed_roles = ["testrole1"]
    path = "database/config/#{conn_name}"

    API.addDatabase(conn_name, host, port, db_name, vault_user, vault_pass, allowed_roles)

    #{:ok, result} = Vaultex.Client.read(path, :token, {"myroot"})
    #payload = %{"options" => %{},
    #            "data" => %{"foo" => "bar"}}

    #{:ok, result} = Vaultex.Client.write("secret/data/my-secret", payload, :token, {Application.get_env(:postgrix_aas, Vault, :token)[:token]})
  end

end
