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
    execute """
    ALTER TABLE instances
    ADD CONSTRAINT instances_clusters_fk
    FOREIGN KEY (ip, port) REFERENCES clusters(ip, port)
    ON DELETE CASCADE ON UPDATE CASCADE
    """
  end

  def down do
    execute """
      DROP TABLE instances;
    """
  end

end
