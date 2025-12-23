defmodule FangornSentinel.Escalation.History do
  @moduledoc """
  Schema for tracking escalation history.

  Records each escalation action taken for an alert, including:
  - Which step was executed
  - Who was notified
  - What channels were used
  - Whether escalation was cancelled or completed
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type action :: :step_executed | :escalation_started | :escalation_cancelled | :escalation_completed

  schema "escalation_history" do
    field :step_number, :integer
    field :action, :string
    field :notified_user_ids, {:array, :integer}, default: []
    field :channels_used, {:array, :string}, default: []
    field :metadata, :map, default: %{}

    belongs_to :alert, FangornSentinel.Alerts.Alert
    belongs_to :policy, FangornSentinel.Escalation.Policy

    timestamps()
  end

  @required_fields [:alert_id, :step_number, :action]
  @optional_fields [:policy_id, :notified_user_ids, :channels_used, :metadata]

  @valid_actions ~w(step_executed escalation_started escalation_cancelled escalation_completed)

  @doc false
  def changeset(history, attrs) do
    history
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:action, @valid_actions)
    |> validate_number(:step_number, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:alert_id)
    |> foreign_key_constraint(:policy_id)
  end
end
