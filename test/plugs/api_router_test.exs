defmodule API.Router.Test do
  use ExUnit.Case
  use Plug.Test
  alias PostgrixCluster.Server
  alias InternalDB.Repo

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    on_exit(fn ->
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
      Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
      {:ok, result} = Server.start_link()
      db_name = "testdb"
      instance_id = "instance_id"
      db_owner = "owner"
      vault_user = "vault"
      Server.rollbackProvision(result, instance_id, db_name, db_owner, vault_user)
    end)

    result = Server.start_link(name: ClusterAPI.Server)
    :ok
  end

  test "provision a new database in the cluster by calling POST /v1/instance/provision" do
    conn_params = conn(:post, "/v1/instance/provision")
    conn = API.Router.call(conn_params, @opts)
    assert conn.state == :sent
    assert conn.status == 422

    assert conn.resp_body ==
             "{\"error\":\"Expected ip, port, db_name, instance_id as JSON parameters.\"}"

    body =
      Jason.encode!(%{ip: "127.0.0.1", port: 5433, db_name: "testdb", instance_id: "instance_id"})

    conn_params =
      conn(:post, "/v1/instance/provision", body)
      |> put_req_header("content-type", "application/json")

    conn = API.Router.call(conn_params, @opts)

    assert conn.state == :sent
    assert conn.status == 200

    assert conn.resp_body == "{\"response\":\"Action successfully performed.\"}"
  end

  test "deprovision a provisioned database by calling POST /v1/instance/deprovision" do
    body =
      Jason.encode!(%{ip: "127.0.0.1", port: 5433, db_name: "testdb", instance_id: "instance_id"})

    conn_params =
      conn(:post, "/v1/instance/provision", body)
      |> put_req_header("content-type", "application/json")

    conn = API.Router.call(conn_params, @opts)

    assert conn.state == :sent
    assert conn.status == 200

    assert conn.resp_body == "{\"response\":\"Action successfully performed.\"}"

    body = %{instance_id: "instance_id"}

    conn_params = conn(:post, "/v1/instance/deprovision", body)
    conn = API.Router.call(conn_params, @opts)
    assert conn.state == :sent
    assert conn.resp_body == "{\"response\":\"Action successfully performed.\"}"
    assert conn.status == 200
  end
end
