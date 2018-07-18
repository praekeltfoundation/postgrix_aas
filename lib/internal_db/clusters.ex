defmodule InternalDB.Clusters do
  use Ecto.Schema
  import Ecto
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :id, autogenerate: true}
  schema "clusters" do
    field :ip, EctoNetwork.INET, primary_key: true
    field :port, :integer, primary_key: true
  end

  @fields ~w(ip port)
  def changeset(host, params \\ %{}) do
    host
    |> cast(params, @fields)
    |> validate_required([:ip, :port])
    |> validate_number(:port, greater_than_or_equal_to: 0)
    |> validate_number(:port, less_than_or_equal_to: 65535)
    |> unique_constraint(:ip, name: "instances_pkey")
    end
end
