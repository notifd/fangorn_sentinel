defmodule FangornSentinelWeb.GraphQL.Types.Schedule do
  use Absinthe.Schema.Notation

  @desc "On-call schedule"
  object :schedule do
    field :id, non_null(:id)
    field :name, non_null(:string)
    field :description, :string
    field :timezone, non_null(:string)

    field :rotations, list_of(:rotation) do
      resolve fn schedule, _, _ ->
        {:ok, FangornSentinel.Schedules.list_rotations(schedule.id)}
      end
    end

    field :inserted_at, non_null(:datetime)
    field :updated_at, non_null(:datetime)
  end

  @desc "Rotation type"
  enum :rotation_type do
    value :daily, description: "Daily rotation"
    value :weekly, description: "Weekly rotation"
    value :custom, description: "Custom rotation pattern"
  end

  @desc "On-call rotation"
  object :rotation do
    field :id, non_null(:id)
    field :name, non_null(:string)
    field :type, non_null(:rotation_type)
    field :start_time, :string
    field :duration_hours, :integer
    field :rotation_start_date, non_null(:date)

    field :participants, list_of(:user) do
      resolve fn rotation, _, _ ->
        users = Enum.map(rotation.participants, fn user_id ->
          FangornSentinel.Accounts.get_user(user_id)
        end)
        {:ok, Enum.reject(users, &is_nil/1)}
      end
    end

    field :inserted_at, non_null(:datetime)
    field :updated_at, non_null(:datetime)
  end
end
