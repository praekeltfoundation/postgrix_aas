defmodule InternalDB.API do
  alias InternalDB.{Repo, Hosts, Clusters, Instances, Bindings}
  import Ecto.Query

  def hosts do
    (from h in Hosts, select: {h.ip, h.hostname})
    |> Repo.all
  end

  def addHost(ip, hostname) do
    Hosts.changeset(%Hosts{}, %{ip: ip, hostname: hostname})
    |> Repo.insert!
  end

  def removeHost(ip) do
    host = Repo.get_by(Hosts, ip: ip)
    Repo.delete(host)
  end

  def clusters do
    (from c in Clusters, select: {c.ip, c.port})
    |> Repo.all
  end

  def addCluster(ip, port) do
    Clusters.changeset(%Clusters{}, %{ip: ip, port: port})
    |> Repo.insert!
  end

  def removeCluster(ip, port) do
    cluster = Repo.get_by(Clusters, ip: ip, port: port)
    Repo.delete(cluster)
  end

  def instances do
      (from i in Instances, select: {i.ip, i.port, i.db_name, i.instance_id})
      |> Repo.all
  end

  def addInstance(ip, port, db_name, instance_id) do
    Instances.changeset(%Instances{}, %{ip: ip, port: port, db_name: db_name, instance_id: instance_id})
    |> Repo.insert!
  end

  def removeInstance(instance_id) do
    instance = Repo.get_by(Instances, [instance_id: instance_id])
    Repo.delete(instance)
  end

  def bindings do
    (from b in Bindings, select: {b.instance_id, b.binding_id})
    |> Repo.all
  end

  def addBinding(instance_id, binding_id) do
    Bindings.changeset(%Bindings{}, %{instance_id: instance_id, binding_id: binding_id})
    |> Repo.insert!
  end

  def removeBinding(binding_id) do
    binding = Repo.get_by(Bindings, binding_id: binding_id)
    Repo.delete(binding)
  end

end

