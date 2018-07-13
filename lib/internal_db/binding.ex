defmodule InternalDB.Binding do
  use Ecto.Schema
  import Ecto.Changeset

  alias InternalDB.Binding

  @primary_key {:id, :id, autogenerate: true}
  schema "bindings" do
    field :instance_id, :string
    field :binding_id, :string

    timestamps()
  end


  @fields ~w(instance_id binding_id)

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, @fields)
    |> validate_required([:instance_id])
    |> validate_required([:binding_id])
    end
end
