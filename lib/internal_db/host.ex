defmodule InternalDB.Host do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "hosts" do
    field :ip, EctoNetwork.INET
    field :hostname, :string

    has_many :clusters, InternalDB.Cluster, foreign_key: :ip
  end

  def changeset(data, params \\ :empty) do
    data
    |> cast(params, [:ip, :hostname])
    end
end
