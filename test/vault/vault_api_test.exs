defmodule API.Router.Test do
  use ExUnit.Case
  use Vaultex
  alias Vault.API

  setup tags do
    on_exit(fn ->

    end)
    :ok

    Vaultex.Client.auth(:token, {"myroot"})
  end

  test "Add a database to Vault" do
    conn_name = "testconnection"
    url = "localhost"
    post = 5432
    db_name = "postgres"
    vault_user = "vault"
    vault_pass = "pass"
    allowed_roles = "testrole1"

    API.addDatabase(conn_name, url, port, db_name, vault_user, vault_pass, allowed_roles)

    {:ok, result} = Vault.Client.read("database/config/" + conn_name)
    IO.puts(result)
  end

end
