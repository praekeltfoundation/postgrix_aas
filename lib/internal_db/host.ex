defmodule InternalDB.Host do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "hosts" do
    field :ip, :string
    field :hostname, :string

    has_many :clusters, InternalDB.Cluster, foreign_key: :ip

    timestamps()
  end

  @fields ~w(ip hostname)

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, @fields)
    |> validate_required([:ip])
    end
end
