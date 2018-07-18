use Mix.Config

config :postgrix_aas, InternalDB.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "internal_db",
  username: "ps_internal",
  password: "mysecretpassword1",
  hostname: "localhost",
  port: 5432,
  pool: Ecto.Adapters.SQL.Sandbox


config :postgrix_aas, PostgrixCluster.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "postgres_cluster",
  username: "ps_cluster",
  password: "mysecretpassword2",
  hostname: "localhost",
  port: 5432,
  pool: Ecto.Adapters.SQL.Sandbox

config :postgrix_aas, ecto_repos: [InternalDB.Repo, PostgrixCluster.Repo]

