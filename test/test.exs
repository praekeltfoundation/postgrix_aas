use Mix.Config

config :my_app, Postgres_aaS.Repo,
  database: "testpostgres",
  username: "postgres",
  password: "mysecretpassword",
  hostname: "localhost"
  pool: Ecto.Adapters.SQL.Sandbox
