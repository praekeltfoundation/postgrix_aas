defmodule InternalDB.Repo.Migrations.CreateBindings do
  use Ecto.Migration

  def up do
    execute """
      CREATE TABLE bindings (
      id SERIAL,
      binding_id VARCHAR(256) UNIQUE,
      instance_id VARCHAR(256) REFERENCES instances(instance_id)
      ON DELETE CASCADE ON UPDATE CASCADE);
    """
  end

  def down do
    execute """
      DROP TABLE bindings;
    """
  end

end
