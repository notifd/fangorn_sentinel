defmodule FangornSentinelWeb.GraphQL.Types.Alert do
  use Absinthe.Schema.Notation

  @desc "Alert severity levels"
  enum :alert_severity do
    value :critical, description: "Critical alert requiring immediate attention"
    value :warning, description: "Warning that should be addressed soon"
    value :info, description: "Informational alert"
  end

  @desc "Alert status"
  enum :alert_status do
    value :firing, description: "Alert is currently firing"
    value :acknowledged, description: "Alert has been acknowledged"
    value :resolved, description: "Alert has been resolved"
  end

  @desc "An alert from a monitoring system"
  object :alert do
    field :id, non_null(:id)
    field :title, non_null(:string)
    field :message, :string
    field :severity, non_null(:alert_severity)
    field :status, non_null(:alert_status)
    field :source, :string
    field :source_id, :string
    field :labels, :string
    field :annotations, :string
    field :fired_at, non_null(:datetime)
    field :acknowledged_at, :datetime
    field :resolved_at, :datetime

    field :assigned_to, :user do
      resolve fn alert, _, _ ->
        if alert.assigned_to_id do
          case FangornSentinel.Accounts.get_user(alert.assigned_to_id) do
            nil -> {:ok, nil}
            user -> {:ok, user}
          end
        else
          {:ok, nil}
        end
      end
    end

    field :inserted_at, non_null(:datetime)
    field :updated_at, non_null(:datetime)
  end

  @desc "Input for creating an alert"
  input_object :alert_input do
    field :title, non_null(:string)
    field :message, :string
    field :severity, non_null(:alert_severity)
    field :source, :string
    field :source_id, :string
    field :labels, :string
    field :annotations, :string
  end
end
