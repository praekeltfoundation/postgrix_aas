defmodule InternalDB.Instances do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
  Schema defining database instances in the internal database.
  """

  @primary_key {:id, :id, autogenerate: true}
  schema "instances" do
    field(:ip, EctoNetwork.INET)
    field(:port, :integer)
    field(:db_name, :string)
    field(:instance_id, :string, unique: true)
    has_many(:bindings, InternalDB.Bindings, foreign_key: :instance_id)
  end

  @fields ~w(ip port db_name instance_id)
  def changeset(data, params \\ %{}) do
    data
    |> cast(params, @fields)
    |> validate_required([:ip, :port, :instance_id])
    |> validate_number(:port, greater_than_or_equal_to: 0)
    |> validate_number(:port, less_than_or_equal_to: 65_535)
    |> unique_constraint(:ip, name: "instances_clusters_fk")
    |> foreign_key_constraint(:ip, name: "instances_clusters_fk")
  end
end
