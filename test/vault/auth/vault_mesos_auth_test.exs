defmodule Vault.Mesos.Auth.Test do
  use ExUnit.Case
  alias Vault.Auth.API, as: Auth
  
  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "Successfully update the Vault policies for a Mesos task", %{bypass: bypass} do
    Bypass.expect(bypass, fn conn ->
      assert "PUT" == conn.method
      assert "auth/mesos/task-policies" == conn.request_path
      assert "mytoken" == List.keyfind(conn.req_headers, "x-vault-token", 0)
      Plug.Conn.resp(conn, 200, "")
    end)
    
    assert {:ok, ""} = Auth.updatePolicy("prefix", ["test1", "test2"])
  end

end