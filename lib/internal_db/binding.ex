defmodule InternalDB.Binding do
  use Ecto.Schema
  import Ecto.Changeset


  @primary_key {:id, :id, autogenerate: true}
  schema "bindings" do
    field :binding_id, :string
    belongs_to :instance, InternalDB.Instance, references: :instance_id
    timestamps()
  end


  @fields ~w(instance_id binding_id)

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, @fields)
    |> validate_required([:instance_id])
    |> validate_required([:binding_id])
    |> assoc_constraint(:instance)
    end
end
