defmodule InternalDB.Cluster do
  use Ecto.Schema
  import Ecto
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :id, autogenerate: true}
  schema "clusters" do
    field :ip, :string, primary_key: true
    field :port, :integer, primary_key: true
    belongs_to :host, InternalDB.Host, references: :ip

    timestamps()
  end

  @fields ~w(ip port)

  def changeset(host, params \\ %{}) do
    host
    |> cast(params, @fields)
    |> validate_required([:ip, :port])
    |> validate_number(:port, greater_than_or_equal_to: Integer.new(0))
    |> validate_number(:port, lesser_than_or_equal_to: Integer.new(65535))
    |> unique_constraint(:ip, name: "instances_pkey")
    |> assoc_constraint(:host)
    end
end
