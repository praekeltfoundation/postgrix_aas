ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(InternalDB.Repo, :manual)
Ecto.Adapters.SQL.Sandbox.mode(Postgrix_Cluster.Repo, :manual)

