defmodule FangornSentinelWeb.GraphQL.Resolvers.Schedule do
  alias FangornSentinel.Schedules

  def who_is_on_call(_parent, args, %{context: %{current_user: _user}}) do
    team_id = args[:team_id]
    {:ok, Schedules.who_is_on_call(team_id)}
  end

  def who_is_on_call(_parent, _args, _context) do
    {:error, "Not authenticated"}
  end

  def my_schedule(_parent, _args, %{context: %{current_user: user}}) do
    case Schedules.get_user_schedule(user.id) do
      nil -> {:ok, nil}
      schedule -> {:ok, schedule}
    end
  end

  def my_schedule(_parent, _args, _context) do
    {:error, "Not authenticated"}
  end
end
