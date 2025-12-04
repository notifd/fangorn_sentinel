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
    # Try to find existing device by token
    case Repo.get_by(PushDevice, device_token: attrs[:device_token]) do
      nil ->
        %PushDevice{}
        |> PushDevice.changeset(attrs)
        |> Repo.insert()

      device ->
        device
        |> PushDevice.changeset(attrs)
        |> Repo.update()
    end
  end

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
