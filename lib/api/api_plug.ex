defmodule API.APIPlug do
  import Plug.Conn

  @moduledoc """
  RESTful interface for resource provisioning.
  """
  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Hello World!\n")
  end
end
