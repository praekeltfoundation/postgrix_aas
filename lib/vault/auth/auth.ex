defmodule Auth.API do
  import Vaultix

  @moduledoc """
  Provides functions that interact with the Mesos Vault Auth Plugin.
  """
  def updatePolicy(task_prefix, policies) do
    path = "auth/mesos/task-policies"

    payload = %{
      "task-id-prefix" => task_prefix,
      "policies" => policies
    }

    Vaultix.Client.write(
      path,
      payload,
      :token,
      {Application.get_env(:postgrix_aas, Vault, :token)[:token]}
    )
  end
end
