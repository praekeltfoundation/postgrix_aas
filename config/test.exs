use Mix.Config

config :postgrix_aas, Postgrix_Cluster.Repo,
  database: "testpostgres",
  username: "postgres",
  password: "mysecretpassword",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
