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
    defstruct [:pid, :config]
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
        opts \\ []
      ) do
    params = [
      ip: Keyword.get(opts, :ip),
      port: Keyword.get(opts, :port),
      db_name: Keyword.get(opts, :db_name),
      instance_id: Keyword.get(opts, :instance_id),
      vault_user: Keyword.get(opts, :vault_user),
      vault_pass: Keyword.get(opts, :vault_pass),
      db_owner: Keyword.get(opts, :db_owner),
      owner_pass: Keyword.get(opts, :owner_pass)
    ]

    GenServer.call(
      server,
      {:provision, params}
    )
  end

  def deprovision(server, instance_id) do
    GenServer.call(server, {:deprovision, instance_id})
  end

  def rollbackProvision(server, instance_id, db_name, db_owner, vault_user) do
    GenServer.call(server, {:rollbackprovision, instance_id, db_name, db_owner, vault_user})
  end

  @impl GenServer
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
             port: state.config[:port],
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
        handle_call({:rollbackprovision, instance_id, db_name, db_owner, vault_user}, from, state)
        {:reply, "Error provisioning database. Rolling back changes.", state}
    end
  end

  @impl GenServer
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

  @impl GenServer
  def handle_call({:rollbackprovision, instance_id, db_name, db_owner, vault_user}, _from, state) do
    if InternalDBAPI.getInstance(instance_id) != nil do
      InternalDBAPI.removeInstance(instance_id)
    end

    if ClusterAPI.databaseExists?(state.pid, db_name) == true do
      ClusterAPI.dropDatabase(state.pid, db_name)
    end

    if ClusterAPI.roleExists?(state.pid, db_owner) == true do
      ClusterAPI.dropRole(state.pid, db_owner)
    end

    if ClusterAPI.roleExists?(state.pid, vault_user) == true do
      ClusterAPI.dropRole(state.pid, vault_user)
    end

    {:reply, "Rolled back provision.", state}
  end

  @impl GenServer
  def handle_call({:_getstate}, _from, state) do
    {:reply, state, state}
  end
end
