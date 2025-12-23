defmodule FangornSentinelWeb.API.V1.ScheduleController do
  @moduledoc """
  REST API controller for schedule management.
  """
  use FangornSentinelWeb, :controller

  alias FangornSentinel.Schedules
  alias FangornSentinel.Schedules.{Schedule, Rotation, Override}

  action_fallback FangornSentinelWeb.FallbackController

  # Schedule CRUD

  def index(conn, params) do
    schedules = Schedules.list_schedules()
    render(conn, :index, schedules: schedules)
  end

  def show(conn, %{"id" => id}) do
    schedule = Schedules.get_schedule_with_rotations!(id)
    render(conn, :show, schedule: schedule)
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> json(%{error: "Schedule not found"})
  end

  def create(conn, %{"schedule" => schedule_params}) do
    case Schedules.create_schedule(schedule_params) do
      {:ok, schedule} ->
        conn
        |> put_status(:created)
        |> render(:show, schedule: schedule)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  end

  def update(conn, %{"id" => id, "schedule" => schedule_params}) do
    schedule = Schedules.get_schedule!(id)

    case Schedules.update_schedule(schedule, schedule_params) do
      {:ok, schedule} ->
        render(conn, :show, schedule: schedule)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> json(%{error: "Schedule not found"})
  end

  def delete(conn, %{"id" => id}) do
    schedule = Schedules.get_schedule!(id)

    case Schedules.delete_schedule(schedule) do
      {:ok, _} ->
        send_resp(conn, :no_content, "")

      {:error, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Failed to delete schedule"})
    end
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> json(%{error: "Schedule not found"})
  end

  # On-call queries

  def who_is_on_call(conn, %{"id" => id}) do
    user_ids = Schedules.who_is_on_call_with_overrides(id)
    json(conn, %{on_call_user_ids: user_ids})
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> json(%{error: "Schedule not found"})
  end

  # Rotation management

  def create_rotation(conn, %{"schedule_id" => schedule_id, "rotation" => rotation_params}) do
    rotation_params = Map.put(rotation_params, "schedule_id", schedule_id)

    case Schedules.create_rotation(rotation_params) do
      {:ok, rotation} ->
        conn
        |> put_status(:created)
        |> json(%{rotation: rotation_to_json(rotation)})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  end

  # Override management

  def create_override(conn, %{"schedule_id" => schedule_id, "override" => override_params}) do
    override_params = Map.put(override_params, "schedule_id", schedule_id)

    case Schedules.create_override(override_params) do
      {:ok, override} ->
        conn
        |> put_status(:created)
        |> json(%{override: override_to_json(override)})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  end

  def list_overrides(conn, %{"schedule_id" => schedule_id}) do
    overrides = Schedules.list_overrides(schedule_id)
    json(conn, %{overrides: Enum.map(overrides, &override_to_json/1)})
  end

  # Helpers

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  defp rotation_to_json(rotation) do
    %{
      id: rotation.id,
      name: rotation.name,
      type: rotation.type,
      start_time: rotation.start_time,
      duration_hours: rotation.duration_hours,
      participants: rotation.participants,
      rotation_start_date: rotation.rotation_start_date
    }
  end

  defp override_to_json(override) do
    %{
      id: override.id,
      user_id: override.user_id,
      start_time: override.start_time,
      end_time: override.end_time,
      override_type: override.override_type,
      note: override.note
    }
  end
end
