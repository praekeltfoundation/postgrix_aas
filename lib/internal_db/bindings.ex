defmodule InternalDB.Bindings do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
  Schema defining database bindings in the internal database.
  """

  @primary_key {:id, :id, autogenerate: true}
  schema "bindings" do
    field(:instance_id, :string)
    field(:binding_id, :string, unique: true)
  end

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, [:instance_id, :binding_id])
    |> validate_required([:instance_id])
    |> validate_required([:binding_id])
  end
end
