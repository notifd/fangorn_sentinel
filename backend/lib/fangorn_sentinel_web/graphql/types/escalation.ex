defmodule FangornSentinelWeb.GraphQL.Types.Escalation do
  use Absinthe.Schema.Notation

  alias FangornSentinel.Escalation

  @desc "Notification channel"
  enum :notification_channel do
    value :push, description: "Push notification"
    value :sms, description: "SMS message"
    value :phone, description: "Phone call"
    value :email, description: "Email"
    value :slack, description: "Slack message"
  end

  @desc "Escalation policy"
  object :escalation_policy do
    field :id, non_null(:id)
    field :name, non_null(:string)
    field :description, :string
    field :team_id, :id

    field :steps, list_of(:escalation_step) do
      resolve fn policy, _, _ ->
        steps = Escalation.get_policy_with_steps!(policy.id).steps
        {:ok, steps}
      end
    end

    field :inserted_at, non_null(:datetime)
    field :updated_at, non_null(:datetime)
  end

  @desc "Escalation step"
  object :escalation_step do
    field :id, non_null(:id)
    field :step_number, non_null(:integer)
    field :wait_minutes, non_null(:integer)
    field :notify_users, list_of(:integer)
    field :notify_schedules, list_of(:integer)
    field :channels, list_of(:notification_channel)

    field :inserted_at, non_null(:datetime)
    field :updated_at, non_null(:datetime)
  end

  @desc "Input for creating an escalation policy"
  input_object :escalation_policy_input do
    field :name, non_null(:string)
    field :description, :string
    field :team_id, :id
  end

  @desc "Input for creating an escalation step"
  input_object :escalation_step_input do
    field :step_number, non_null(:integer)
    field :wait_minutes, :integer
    field :notify_users, list_of(:integer)
    field :notify_schedules, list_of(:integer)
    field :channels, list_of(:notification_channel)
  end
end
