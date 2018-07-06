defmodule InternalDB.Repo.Migrations.CreateClusters do
  use Ecto.Migration

  def up do
    execute """
      CREATE TABLE clusters (
      id SERIAL,
      ip INET REFERENCES hosts(ip)
      ON DELETE CASCADE ON UPDATE CASCADE,
      port INT,
      PRIMARY KEY (ip, port)
      );
    """
  end

  def down do
    execute """
      DROP TABLE clusters;
    """
  end

end
