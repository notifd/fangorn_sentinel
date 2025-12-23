defmodule FangornSentinelWeb.GraphQL.Resolvers.Schedule do
  alias FangornSentinel.Schedules
  alias FangornSentinel.Accounts

  def list_schedules(_parent, _args, %{context: %{current_user: _user}}) do
    {:ok, Schedules.list_schedules()}
  end

  def list_schedules(_parent, _args, _context) do
    {:error, "Not authenticated"}
  end

  def get_schedule(_parent, %{id: id}, %{context: %{current_user: _user}}) do
    case Schedules.get_schedule_with_rotations!(id) do
      nil -> {:error, "Schedule not found"}
      schedule -> {:ok, schedule}
    end
  rescue
    Ecto.NoResultsError -> {:error, "Schedule not found"}
  end

  def get_schedule(_parent, _args, _context) do
    {:error, "Not authenticated"}
  end

  def who_is_on_call(_parent, args, %{context: %{current_user: _user}}) do
    user_ids = if args[:team_id] do
      Schedules.who_is_on_call_for_team(args[:team_id])
    else
      []
    end

    users = Enum.map(user_ids, &Accounts.get_user/1) |> Enum.reject(&is_nil/1)
    {:ok, users}
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
