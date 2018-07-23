use Mix.Config

# TODO: Make these read configs from Vaultkeeper output

config :postgrix_aas, InternalDB.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "internal_db",
  username: "ps_internal",
  password: "mysecretpassword1",
  hostname: "localhost",
  port: 5432,
  pool: Ecto.Adapters.SQL.Sandbox

config :postgrix_aas, ecto_repos: [InternalDB.Repo]

config :postgrix_aas, PostgrixCluster.Test,
  database: "postgres_cluster",
  username: "postgres",
  password: "mysecretpassword2",
  hostname: "localhost",
  port: 5432,
  url: "localhost:5432"

config :postgrix_aas, PostgrixCluster,
  pool: [
    pool: DBConnection.Poolboy,
    pool_size: 20,
    host: "localhost",
    database: "postgres_cluster"
  ]
