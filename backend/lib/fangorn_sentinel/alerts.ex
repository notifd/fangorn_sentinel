defmodule FangornSentinel.Alerts do
  @moduledoc """
  The Alerts context - handles all operations related to alerts.
  """

  import Ecto.Query, warn: false
  alias FangornSentinel.Repo
  alias FangornSentinel.Alerts.Alert

  @doc """
  Creates a new alert.

  ## Examples

      iex> create_alert(%{title: "High CPU", severity: "critical", source: "grafana", fired_at: DateTime.utc_now()})
      {:ok, %Alert{}}

      iex> create_alert(%{invalid: "attrs"})
      {:error, %Ecto.Changeset{}}
  """
  def create_alert(attrs \\ %{}) do
    %Alert{}
    |> Alert.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns a list of alerts, with optional filtering and limiting.

  ## Options

    * `:status` - Filter by status (firing, acknowledged, resolved)
    * `:severity` - Filter by severity (critical, warning, info)
    * `:source` - Filter by source (grafana, prometheus, etc.)
    * `:limit` - Limit number of results (default: no limit)

  ## Examples

      iex> list_alerts()
      [%Alert{}, ...]

      iex> list_alerts(status: "firing", limit: 10)
      [%Alert{}, ...]
  """
  def list_alerts(opts \\ []) do
    Alert
    |> apply_filters(opts)
    |> apply_limit(opts)
    |> order_by([a], desc: a.fired_at)
    |> Repo.all()
  end

  @doc """
  Gets a single alert by ID.

  Returns `{:ok, alert}` if found, `{:error, :not_found}` otherwise.

  ## Examples

      iex> get_alert(123)
      {:ok, %Alert{}}

      iex> get_alert(456)
      {:error, :not_found}
  """
  def get_alert(id) do
    case Repo.get(Alert, id) do
      nil -> {:error, :not_found}
      alert -> {:ok, alert}
    end
  end

  @doc """
  Gets a single alert by ID, raising if not found.

  ## Examples

      iex> get_alert!(123)
      %Alert{}

      iex> get_alert!(456)
      ** (Ecto.NoResultsError)
  """
  def get_alert!(id) do
    Repo.get!(Alert, id)
  end

  @doc """
  Updates an alert.

  ## Examples

      iex> update_alert(alert, %{title: "Updated Title"})
      {:ok, %Alert{}}

      iex> update_alert(alert, %{severity: "invalid"})
      {:error, %Ecto.Changeset{}}
  """
  def update_alert(%Alert{} = alert, attrs) do
    alert
    |> Alert.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an alert.

  ## Examples

      iex> delete_alert(alert)
      {:ok, %Alert{}}
  """
  def delete_alert(%Alert{} = alert) do
    Repo.delete(alert)
  end

  @doc """
  Acknowledges an alert.

  ## Examples

      iex> acknowledge_alert(alert, user, "Looking into it")
      {:ok, %Alert{}}
  """
  def acknowledge_alert(%Alert{} = alert, user, note \\ nil) do
    attrs = %{
      acknowledged_by_id: user.id,
      acknowledged_at: DateTime.utc_now(),
      status: :acknowledged
    }

    attrs = if note, do: Map.put(attrs, :acknowledgement_note, note), else: attrs

    alert
    |> Alert.acknowledge_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Resolves an alert.

  ## Examples

      iex> resolve_alert(alert, user, "Fixed the issue")
      {:ok, %Alert{}}
  """
  def resolve_alert(%Alert{} = alert, user, resolution_note \\ nil) do
    attrs = %{
      resolved_by_id: user.id,
      resolved_at: DateTime.utc_now(),
      status: :resolved
    }

    attrs = if resolution_note, do: Map.put(attrs, :resolution_note, resolution_note), else: attrs

    alert
    |> Alert.resolve_changeset(attrs)
    |> Repo.update()
  end

  # Private helper functions

  defp apply_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:status, status}, query ->
        where(query, [a], a.status == ^status)

      {:severity, severity}, query ->
        where(query, [a], a.severity == ^severity)

      {:source, source}, query ->
        where(query, [a], a.source == ^source)

      _other, query ->
        query
    end)
  end

  defp apply_limit(query, opts) do
    case Keyword.get(opts, :limit) do
      nil -> query
      limit -> limit(query, ^limit)
    end
  end
end
