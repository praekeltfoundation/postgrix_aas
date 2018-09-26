defmodule InternalDB.Repo.Migrations.CreateInstances do
  use Ecto.Migration

  def up do
    execute """
      CREATE TABLE instances (
      id SERIAL,
      ip INET,
      port INT,
      db_name VARCHAR(256),
      instance_id VARCHAR(256) UNIQUE
      );
    """
  end

  def down do
    execute """
      DROP TABLE instances;
    """
  end

end
