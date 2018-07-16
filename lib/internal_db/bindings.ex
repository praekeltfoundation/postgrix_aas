defmodule InternalDB.Bindings do
  use Ecto.Schema
  import Ecto.Changeset


  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :string
  schema "bindings" do
    field :binding_id, :string
    belongs_to :instance, InternalDB.Instances, references: :instance_id

  end


  def changeset(data, params \\ %{}) do
    data
    |> cast(params, [:instance_id, :binding_id])
    |> validate_required([:instance_id])
    |> validate_required([:binding_id])
    |> assoc_constraint(:instance)
    end
end
