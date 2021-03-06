defmodule InternalDB.Instances do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
  Schema defining database instances in the internal database.
  """

  @primary_key {:id, :id, autogenerate: true}
  schema "instances" do
    field :ip, EctoNetwork.INET
    field :port, :integer
    field :db_name, :string
    field :instance_id, :string, unique: true
  end

  @fields ~w(ip port db_name instance_id)
  def changeset(data, params \\ %{}) do
    changeset = change(data, params)

    changeset
    |> validate_ip(:ip)
    |> cast(params, @fields)
    |> validate_required([:ip, :port, :instance_id])
    |> validate_number(:port, greater_than_or_equal_to: 0)
    |> validate_number(:port, less_than_or_equal_to: 65_535)
  end

  def validate_ip(changeset, field) do
    validate_change(changeset, field, fn _, ip ->
      case EctoNetwork.INET.cast(ip) do
        {:ok, %Postgrex.INET{address: {:error, :einval}}} ->
          [{:error, "Error casting IP address to %Postgrex.INET{}: Invalid IP format"}]

        {:ok, result} ->
          []

        _ ->
          [{:error, "Unknown error validating IP address."}]
      end
    end)
  end
end
