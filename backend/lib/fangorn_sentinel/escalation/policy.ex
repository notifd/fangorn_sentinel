defmodule FangornSentinel.Escalation.Policy do
  @moduledoc """
  Schema for escalation policies - defines how alerts are escalated.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "escalation_policies" do
    field :name, :string
    field :description, :string

    belongs_to :team, FangornSentinel.Accounts.Team
    has_many :steps, FangornSentinel.Escalation.Step

    timestamps()
  end

  @doc false
  def changeset(policy, attrs) do
    policy
    |> cast(attrs, [:name, :description, :team_id])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 255)
    |> foreign_key_constraint(:team_id)
  end
end
