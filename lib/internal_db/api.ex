defmodule InternalDB.API do
  alias InternalDB.{Repo, Host}
  import Ecto.Query

  def hosts do
    (from h in Host, select: {h.ip, h.hostname})
    |> Repo.all
  end

  def addHost(ip, hostname) do
    InternalDB.Host.changeset(%Host{}, %{ip: ip, hostname: hostname})
    |> Repo.insert!
  end

end
