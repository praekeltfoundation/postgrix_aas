defmodule InternalDB.Hosts do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
  Schema defining database hosts in the internal database.
  """

  @primary_key {:id, :id, autogenerate: true}
  schema "hosts" do
    field :ip, EctoNetwork.INET, primary_key: true
    field :hostname, :string

    has_many :clusters, InternalDB.Clusters, foreign_key: :ip
  end

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, [:ip, :hostname])
  end
end
