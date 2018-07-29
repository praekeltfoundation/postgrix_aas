defmodule PostgrixCluster.Server do
  use GenServer
  alias PostgrixCluster.API, as: ClusterAPI
  alias InternalDB.API, as: InternalDBAPI

  defmodule State do
    defstruct pid: nil, config: nil
  end

  defmodule Instance do
    defstruct ip: nil,
              port: nil,
              db_name: nil,
              instance_id: nil,
              vault_user: nil,
              vault_pass: nil,
              db_owner: nil,
              owner_pass: nil
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    config = Application.get_env(:postgrix_aas, PostgrixCluster)
    {:ok, pid} = Postgrex.start_link(config)
    {:ok, %State{pid: pid, config: config}}
  end

  def provision(
        server,
        [ip: ip, port: port, db_name: db_name, instance_id: instance_id, vault_user: vault_user, vault_pass: vault_pass, db_owner: db_owner, owner_pass: owner_pass]
      ) do
    GenServer.call(
      server,
      {:provision, [ip: ip, port: port, db_name: db_name, instance_id: instance_id, vault_user: vault_user, vault_pass: vault_pass, db_owner: db_owner, owner_pass: owner_pass]}
    )
  end

  def handle_call(
        {:provision,
        [ip: ip, port: port, db_name: db_name, instance_id: instance_id, vault_user: vault_user, vault_pass: vault_pass, db_owner: db_owner, owner_pass: owner_pass]},
        _from,
        state
      ) do
    provision(
      state.pid,
      ip,
      port,
      db_name,
      instance_id,
      vault_user,
      vault_pass,
      db_owner,
      owner_pass,
      state.config
    )
  end

  defp provision(
         pid,
         ip,
         port,
         db_name,
         instance_id,
         vault_user,
         vault_pass,
         db_owner,
         owner_pass,
         config
       ) do
    with {:ok, result} <- ClusterAPI.createDatabase(pid, db_name),
         {:ok, pid2} <-
           Postgrex.start_link(
             hostname: ip,
             port: port,
             username: config[:username],
             password: config[:password],
             database: db_name
           ),
         {:ok, result} <- ClusterAPI.addOwnerRole(pid2, db_name, db_owner, owner_pass),
         {:ok, result} <- ClusterAPI.addVaultRole(pid2, db_name, vault_user, vault_pass),
         {:ok, result} <- ClusterAPI.grantOwnerRole(pid2, db_owner, vault_user),
         {:ok, result} <- InternalDBAPI.addInstance(ip, port, db_name, instance_id) do
      {:ok, "Database successfully provisioned: #{inspect result}"}
    end
  else
    error -> {:error, "Error provisioning database."}
  end

  def deprovision(pid, ip, port, db_name, instance_id, db_owner, vault_user) do
    with {:ok, result} <- ClusterAPI.dropDatabase(db_name, db_owner),
         {:ok, result} <- InternalDBAPI.removeInstance(instance_id) do
      {:ok, "Database successfully deprovisioned: #{inspect result}"}
    end
  else
    error -> {:error, "Error deprovisioning database: #{inspect error}"}
  end
end
