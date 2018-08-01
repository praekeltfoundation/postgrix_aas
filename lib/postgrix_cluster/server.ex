defmodule PostgrixCluster.Server do
  use GenServer
  alias PostgrixCluster.API, as: ClusterAPI
  alias InternalDB.API, as: InternalDBAPI

  @moduledoc """
  Internal API server for managing cluster resources.
  """

  defmodule State do
    @moduledoc """
    Internal state of the API server.
    """
    defstruct pid: nil, config: nil
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
        ip: ip,
        port: port,
        db_name: db_name,
        instance_id: instance_id,
        vault_user: vault_user,
        vault_pass: vault_pass,
        db_owner: db_owner,
        owner_pass: owner_pass
      ) do
    GenServer.call(
      server,
      {:provision,
       [
         ip: ip,
         port: port,
         db_name: db_name,
         instance_id: instance_id,
         vault_user: vault_user,
         vault_pass: vault_pass,
         db_owner: db_owner,
         owner_pass: owner_pass
       ]}
    )
  end

  def deprovision(server, instance_id) do
    GenServer.call(server, {:deprovision, instance_id})
  end

  def rollbackProvision(server, db_name, instance_id) do
    GenServer.call(server, {:rollbackprovision, instance_id, db_name})
  end

  @impl true
  def handle_call(
        {:provision,
         [
           ip: ip,
           port: port,
           db_name: db_name,
           instance_id: instance_id,
           vault_user: vault_user,
           vault_pass: vault_pass,
           db_owner: db_owner,
           owner_pass: owner_pass
         ]},
        from,
        state
      ) do
    with {:ok, result} <- ClusterAPI.createDatabase(state.pid, db_name),
         {:ok, pid2} <-
           Postgrex.start_link(
             hostname: state.config[:hostname],
             port: port,
             username: state.config[:username],
             password: state.config[:password],
             database: db_name
           ),
         {:ok, result} <- ClusterAPI.addOwnerRole(pid2, db_name, db_owner, owner_pass),
         {:ok, result} <- ClusterAPI.addVaultRole(pid2, db_name, vault_user, vault_pass),
         {:ok, result} <- ClusterAPI.grantOwnerRole(pid2, db_owner, vault_user),
         {:ok, result} <- InternalDBAPI.addInstance(ip, port, db_name, instance_id) do
      GenServer.stop(pid2)
      {:reply, "Database successfully provisioned: #{inspect(result)}", state}
    else
      _ ->
        handle_call({:rollbackprovision, instance_id, db_name}, from, state)
        {:reply, "Error provisioning database. Rolling back changes.", state}
    end
  end

  @impl true
  def handle_call(
        {:deprovision, instance_id},
        _from,
        state
      ) do
    with result <- InternalDB.API.getInstance(instance_id),
         {:ok, result} <- ClusterAPI.dropDatabase(state.pid, result.db_name),
         {:ok, result} <- InternalDBAPI.removeInstance(instance_id) do
      {:reply, "Database successfully deprovisioned: #{inspect(result)}", state}
    else
      error -> {:reply, "Error deprovisioning database: #{inspect(error)}", state}
    end
  end

  @impl true
  def handle_call({:rollbackprovision, instance_id, db_name}, _from, state) do
    if InternalDBAPI.getInstance(instance_id) != nil do
      InternalDBAPI.removeInstance(instance_id)
    end

    if ClusterAPI.databaseExists!(state.pid, db_name) == true do
      ClusterAPI.dropDatabase(state.pid, db_name)
    end

    {:reply, "Rolled back provision.", state}
  end

  @impl true
  def handle_call({:_getstate}, _from, state) do
    {:reply, state, state}
  end
end
