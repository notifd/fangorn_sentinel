defmodule FangornSentinelWeb.API.V1.DeviceController do
  use FangornSentinelWeb, :controller

  alias FangornSentinel.Push.PushDevice
  alias FangornSentinel.Repo

  @doc """
  Registers a new push notification device or updates an existing one.

  Expected payload:
  ```json
  {
    "user_id": 123,
    "platform": "ios",  // "ios" or "android"
    "device_token": "...",
    "device_name": "iPhone 15 Pro",  // optional
    "app_version": "1.0.0",  // optional
    "os_version": "17.2"  // optional
  }
  ```
  """
  def register(conn, params) do
    case register_or_update_device(params) do
      {:ok, device} ->
        conn
        |> put_status(:ok)
        |> json(%{status: "registered", platform: device.platform})

      {:error, _changeset} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid device registration"})
    end
  end

  @doc """
  Unregisters a device by token.

  Expected payload:
  ```json
  {
    "device_token": "..."
  }
  ```
  """
  def unregister(conn, %{"device_token" => device_token}) do
    # Delete device if it exists
    case Repo.get_by(PushDevice, device_token: device_token) do
      nil -> :ok
      device -> Repo.delete(device)
    end

    conn
    |> put_status(:ok)
    |> json(%{status: "unregistered"})
  end

  def unregister(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "device_token required"})
  end

  # Private functions

  defp register_or_update_device(params) do
    device_token = Map.get(params, "device_token")

    # If device_token is nil, just try to insert and let the changeset validation handle it
    if device_token == nil do
      %PushDevice{}
      |> PushDevice.changeset(parse_device_params(params))
      |> Repo.insert()
    else
      case Repo.get_by(PushDevice, device_token: device_token) do
        nil ->
          # Create new device
          %PushDevice{}
          |> PushDevice.changeset(parse_device_params(params))
          |> Repo.insert()

        existing_device ->
          # Update existing device
          existing_device
          |> PushDevice.changeset(parse_device_params(params))
          |> Repo.update()
      end
    end
  end

  defp parse_device_params(params) do
    %{
      user_id: Map.get(params, "user_id"),
      platform: Map.get(params, "platform"),
      device_token: Map.get(params, "device_token"),
      device_name: Map.get(params, "device_name"),
      app_version: Map.get(params, "app_version"),
      os_version: Map.get(params, "os_version"),
      last_active_at: DateTime.utc_now()
    }
  end
end
