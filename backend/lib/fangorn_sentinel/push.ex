defmodule FangornSentinel.Push do
  @moduledoc """
  The Push context - handles device registration and push notifications.
  """

  import Ecto.Query, warn: false
  alias FangornSentinel.Repo
  alias FangornSentinel.Push.PushDevice

  @doc """
  Registers or updates a push notification device.

  ## Examples

      iex> register_device(%{user_id: 1, device_token: "abc123", platform: :ios})
      {:ok, %PushDevice{}}

  """
  def register_device(attrs) do
    # Sanitize and validate device_token before lookup
    token = attrs[:device_token] || attrs["device_token"]

    # Handle nil or empty token - return validation error
    if is_nil(token) or (is_binary(token) and String.trim(token) == "") do
      changeset = %PushDevice{}
        |> PushDevice.changeset(attrs)
        |> Ecto.Changeset.add_error(:device_token, "can't be blank")
      {:error, changeset}
    else
      # Sanitize token before lookup (remove null bytes, limit length)
      sanitized_token = sanitize_token(token)
      sanitized_attrs = Map.put(attrs, :device_token, sanitized_token)

      # Try to find existing device by token
      case Repo.get_by(PushDevice, device_token: sanitized_token) do
        nil ->
          %PushDevice{}
          |> PushDevice.changeset(sanitized_attrs)
          |> Repo.insert()

        device ->
          device
          |> PushDevice.changeset(sanitized_attrs)
          |> Repo.update()
      end
    end
  end

  # Sanitize device token: remove null bytes, limit length
  defp sanitize_token(token) when is_binary(token) do
    token
    |> String.replace(<<0>>, "")  # Remove null bytes
    |> String.replace(~r/[\x00-\x1F\x7F]/, "")  # Remove control characters
    |> String.slice(0, 255)  # Limit to database column size
  end
  defp sanitize_token(_), do: ""

  @doc """
  Gets devices for a user.

  ## Examples

      iex> get_user_devices(1)
      [%PushDevice{}, ...]

  """
  def get_user_devices(user_id) do
    PushDevice
    |> where([d], d.user_id == ^user_id)
    |> Repo.all()
  end

  @doc """
  Unregisters a device by token.

  ## Examples

      iex> unregister_device("abc123")
      {:ok, %PushDevice{}}

  """
  def unregister_device(device_token) do
    case Repo.get_by(PushDevice, device_token: device_token) do
      nil -> {:error, :not_found}
      device -> Repo.delete(device)
    end
  end
end
