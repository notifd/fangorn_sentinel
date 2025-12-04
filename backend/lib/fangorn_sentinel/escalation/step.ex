defmodule FangornSentinel.Escalation.Step do
  @moduledoc """
  Schema for escalation steps - individual steps in an escalation policy.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @notification_channels [:push, :sms, :phone, :email, :slack]

  schema "escalation_steps" do
    field :step_number, :integer
    field :wait_minutes, :integer, default: 5
    field :notify_users, {:array, :integer}, default: []
    field :notify_schedules, {:array, :integer}, default: []
    field :channels, {:array, Ecto.Enum}, values: @notification_channels, default: [:push]

    belongs_to :policy, FangornSentinel.Escalation.Policy

    timestamps()
  end

  @doc false
  def changeset(step, attrs) do
    step
    |> cast(attrs, [:step_number, :wait_minutes, :notify_users, :notify_schedules, :channels, :policy_id])
    |> validate_required([:step_number, :policy_id])
    |> validate_number(:step_number, greater_than_or_equal_to: 1)
    |> validate_number(:wait_minutes, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:policy_id)
  end
end
