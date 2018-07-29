defmodule InternalDB.API do
  alias InternalDB.{Repo, Instances, Bindings}
  import Ecto.Query

  @moduledoc """
  Provides functions that interact with the service's
  internal database to keep records on provisioned resources.
  """

  def instances do
    Instances
    |> select([i], {i.ip, i.port, i.db_name, i.instance_id})
    |> Repo.all()
  end

  def addInstance(ip, port, db_name, instance_id) do
    %Instances{}
    |> Instances.changeset(%{ip: ip, port: port, db_name: db_name, instance_id: instance_id})
    |> Repo.insert!()
  end

  def getInstance(instance_id) do
    Repo.get_by(Instances, instance_id: instance_id)
  end

  def removeInstance(instance_id) do
    instance_id
    |> getInstance
    |> Repo.delete()
  end

  def bindings do
    Bindings
    |> select([b], {b.instance_id, b.binding_id})
    |> Repo.all()
  end

  def addBinding(instance_id, binding_id) do
    %Bindings{}
    |> Bindings.changeset(%{instance_id: instance_id, binding_id: binding_id})
    |> Repo.insert!()
  end

  def getBinding(binding_id) do
    Repo.get_by(Bindings, binding_id: binding_id)
  end

  def removeBinding(binding_id) do
    binding_id
    |> getBinding
    |> Repo.delete()
  end
end
