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
          case provisionInstance(ip, port, db_name, instance_id) do
            {:reply, result} -> {200, result}
          end

        _ ->
          {422, missing_params([:ip, :port, :db_name, :instance_id])}
      end

    send_resp(conn, status, body)
  end

  post "/v1/instance/deprovision" do
    {status, body} =
      case conn.body_params do
        %{"instance_id" => instance_id} ->
          case deprovisionInstance(instance_id) do
            {:reply, result} -> {200, result}
          end

        _ ->
          {422, missing_params([:ip, :port, :db_name, :instance_id])}
      end

    send_resp(conn, status, body)
  end

  defp provisionInstance(ip, port, db_name, instance_id) do
    result =
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

    {:reply, result}
  end

  defp deprovisionInstance(instance_id) do
    result = ClusterServer.deprovision(ClusterAPI.Server, instance_id)
    {:reply, result}
  end

  defp success(message) do
    Jason.encode!(%{response: "Success: #{inspect(message)}"})
  end

  defp error(message) do
    Jason.encode!(%{response: "Error: #{inspect(message)}"})
  end

  defp format_list(list) do
    Enum.join(list, ", ")
  end

  def make_password(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.encode64()
    |> binary_part(0, length)
  end

  defp missing_params(params) do
    Jason.encode!(%{error: "Expected #{format_list(params)} as JSON parameters."})
  end

  match(_, do: send_resp(conn, 404, "Oops!"))
end
