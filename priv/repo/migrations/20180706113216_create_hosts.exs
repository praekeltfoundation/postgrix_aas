defmodule InternalDB.Repo.Migrations.CreateHosts do
  use Ecto.Migration

  def up do
    execute """
      CREATE TABLE hosts (
      id SERIAL,
      ip INET PRIMARY KEY,
      host VARCHAR(256));
    """
  end

  def down do
    execute """
      DROP TABLE hosts;
    """
  end
end
