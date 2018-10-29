use Mix.Config

# TODO: Make these read configs from Vaultkeeper output

config :postgrix_aas, InternalDB.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "internal_db",
  username: "ps_internal",
  password: "mysecretpassword1",
  hostname: "localhost",
  port: 5432,
  ssl: false,
  pool: Ecto.Adapters.SQL.Sandbox,
  timeout: :infinity

config :postgrix_aas, ecto_repos: [InternalDB.Repo]

config :postgrix_aas, PostgrixCluster,
  database: "postgres_cluster",
  username: "postgres",
  password: "mysecretpassword2",
  hostname: "localhost",
  port: 5433,
  ssl: true,
  ssl_opts: [
    cacertfile: "./ca.pem"
  ],
  ownership_timeout: :infinity

config :postgrix_aas, Vault,
  token: "myroot",
  internal_db: "internal_db",
  cluster_db: "postgres_cluster",
  vault_addr: "vault"
