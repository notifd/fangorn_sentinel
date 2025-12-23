defmodule FangornSentinelWeb.API.V1.ScheduleJSON do
  @moduledoc """
  JSON rendering for schedule API responses.
  """

  alias FangornSentinel.Schedules.Schedule

  def index(%{schedules: schedules}) do
    %{schedules: Enum.map(schedules, &schedule_to_json/1)}
  end

  def show(%{schedule: schedule}) do
    %{schedule: schedule_to_json(schedule)}
  end

  defp schedule_to_json(%Schedule{} = schedule) do
    %{
      id: schedule.id,
      name: schedule.name,
      description: schedule.description,
      timezone: schedule.timezone,
      team_id: schedule.team_id,
      rotations: rotations_to_json(schedule),
      inserted_at: schedule.inserted_at,
      updated_at: schedule.updated_at
    }
  end

  defp rotations_to_json(%{rotations: %Ecto.Association.NotLoaded{}}), do: nil
  defp rotations_to_json(%{rotations: rotations}) when is_list(rotations) do
    Enum.map(rotations, fn rotation ->
      %{
        id: rotation.id,
        name: rotation.name,
        type: rotation.type,
        start_time: rotation.start_time,
        duration_hours: rotation.duration_hours,
        participants: rotation.participants,
        rotation_start_date: rotation.rotation_start_date
      }
    end)
  end
  defp rotations_to_json(_), do: nil
end
