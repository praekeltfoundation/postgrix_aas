use Mix.Config

# TODO: Make these read configs from Vaultkeeper output

config :postgrix_aas, InternalDB.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "internal_db",
  username: "ps_internal",
  password: "mysecretpassword1",
  hostname: "0.0.0.0",
  port: 5433,
  ssl: false,
  pool: Ecto.Adapters.SQL.Sandbox,
  timeout: :infinity

config :postgrix_aas, ecto_repos: [InternalDB.Repo]

config :postgrix_aas, PostgrixCluster,
  database: "postgres_cluster",
  username: "postgres",
  password: "mysecretpassword2",
  hostname: "0.0.0.0",
  port: 5434,
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
