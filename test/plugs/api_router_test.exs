defmodule API.Router.Test do
  use ExUnit.Case
  use Plug.Test
  alias PostgrixCluster.Server, as: Server
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
      db_name = "testdb"
      instance_id = "instance_id"
      Server.rollbackProvision(Cluster.Server, db_name, instance_id)
    end)

    result = Server.start_link(name: ClusterAPI.Server)
    :ok
  end

  test "POST /v1/instance/provision" do
    conn = conn(:post, "/v1/instance/provision")
    conn = API.Router.call(conn, @opts)
    assert conn.state == :sent
    assert conn.status == 422

    assert conn.resp_body ==
             "{\"error\":\"Expected ip, port, db_name, instance_id as JSON parameters.\"}"

    body =
      Jason.encode!(%{ip: "127.0.0.1", port: 5433, db_name: "testdb", instance_id: "instance_id"})

    conn =
      conn(:post, "/v1/instance/provision", body)
      |> put_req_header("content-type", "application/json")

    conn = API.Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200

    assert conn.resp_body ==
             "Database successfully provisioned: %InternalDB.Instances{__meta__: #Ecto.Schema.Metadata<:loaded, \"instances\">, db_name: \"testdb\", id: 1, instance_id: \"instance_id\", ip: %Postgrex.INET{address: {127, 0, 0, 1}}, port: 5433}"
  end
end
