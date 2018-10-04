defmodule API.Router do
  use Plug.Router
  use GenServer
  alias PostgrixCluster.Server, as: ClusterServer
  require Logger

  @moduledoc """
  RESTful Endpoint for resource provisioning.
  """

  def init(options), do: options

  plug Plug.Logger

  plug(:match)

  plug(
    Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:dispatch)

  post "/v1/instance/provision" do
    {status, body} =
      case conn.body_params do
        %{"ip" => ip, "port" => port, "db_name" => db_name, "instance_id" => instance_id} ->
          provisionInstance(ip, port, db_name, instance_id)
          {200, success()}

        _ ->
          {422, missing_params([:ip, :port, :db_name, :instance_id])}
      end

    send_resp(conn, status, body)
  end

  post "/v1/instance/deprovision" do
    {status, body} =
      case conn.body_params do
        %{"instance_id" => instance_id} ->
          deprovisionInstance(instance_id)
          {200, success()}

        _ ->
          {422, missing_params([:instance_id])}
      end

    send_resp(conn, status, body)
  end

  defp provisionInstance(ip, port, db_name, instance_id) do
    ClusterServer.provision(
      ClusterAPI.Server,
      ip: ip,
      port: port,
      db_name: db_name,
      instance_id: instance_id,
      vault_user: "vault",
      vault_pass: "pass",
      db_owner: "owner",
      owner_pass: "pass"
    )
  end

  defp deprovisionInstance(instance_id) do
    ClusterServer.deprovision(ClusterAPI.Server, instance_id)
  end

  defp success() do
    Jason.encode!(%{response: "Action successfully performed."})
  end

  defp format_list(list) do
    Enum.join(list, ", ")
  end

  defp missing_params(params) do
    Jason.encode!(%{error: "Expected #{format_list(params)} as JSON parameters."})
  end

  match(_, do: send_resp(conn, 404, "Oops!"))
end
