defmodule InternalDB.API do
  alias InternalDB.{Repo, Hosts, Clusters, Instances, Bindings}
  import Ecto.Query

  @moduledoc """
  Provides functions that interact with the service's
  internal database to keep records on provisioned resources.
  """

  def hosts do
    Hosts
    |> select([h], {h.ip, h.hostname})
    |> Repo.all
  end

  def addHost(ip, hostname) do
    %Hosts{}
    |> Hosts.changeset(%{ip: ip, hostname: hostname})
    |> Repo.insert!
  end

  def getHost(ip) do
    Repo.get_by(Hosts, ip: ip)
  end

  def removeHost(ip) do
    ip
    |> getHost
    |> Repo.delete
  end

  def clusters do
    Clusters
    |> select([c], {c.ip, c.port})
    |> Repo.all
  end

  def addCluster(ip, port) do
    %Clusters{}
    |> Clusters.changeset(%{ip: ip, port: port})
    |> Repo.insert!
  end

  def getCluster(ip, port) do
    Repo.get_by(Clusters, ip: ip, port: port)
  end

  def removeCluster(ip, port) do
    ip
    |> getCluster(port)
    |> Repo.delete
  end

  def instances do
      Instances
      |> select([i], {i.ip, i.port, i.db_name, i.instance_id})
      |> Repo.all
  end

  def addInstance(ip, port, db_name, instance_id) do
    %Instances{}
    |> Instances.changeset(%{ip: ip, port: port, db_name: db_name, instance_id: instance_id})
    |> Repo.insert!
  end

  def getInstance(instance_id) do
    Repo.get_by(Instances, instance_id: instance_id)
  end

  def removeInstance(instance_id) do
    instance_id
    |> getInstance
    |> Repo.delete
  end

  def bindings do
    Bindings
    |> select([b], {b.instance_id, b.binding_id})
    |> Repo.all
  end

  def addBinding(instance_id, binding_id) do
    %Bindings{}
    |> Bindings.changeset(%{instance_id: instance_id, binding_id: binding_id})
    |> Repo.insert!
  end

  def getBinding(binding_id) do
    Repo.get_by(Bindings, binding_id: binding_id)
  end

  def removeBinding(binding_id) do
    binding_id
    |> getBinding
    |> Repo.delete
  end
end

