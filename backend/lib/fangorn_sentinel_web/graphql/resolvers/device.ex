defmodule FangornSentinelWeb.GraphQL.Resolvers.Device do
  @moduledoc """
  GraphQL resolver for device registration.
  """

  alias FangornSentinel.Push

  @doc """
  Registers a push notification device for the current user.
  """
  def register(_parent, args, %{context: %{current_user: user}}) do
    device_params = %{
      user_id: user.id,
      device_token: args[:token],
      platform: to_string(args[:platform]),  # Convert atom to string for database
      device_name: args[:device_name]
    }

    case Push.register_device(device_params) do
      {:ok, device} -> {:ok, device}
      {:error, changeset} -> {:error, format_errors(changeset)}
    end
  end

  def register(_parent, _args, _context) do
    {:error, "Not authenticated"}
  end

  @doc """
  Lists devices for the current user.
  """
  def list_devices(_parent, _args, %{context: %{current_user: user}}) do
    {:ok, Push.get_user_devices(user.id)}
  end

  def list_devices(_parent, _args, _context) do
    {:error, "Not authenticated"}
  end

  @doc """
  Unregisters a device by token.
  """
  def unregister(_parent, %{token: token}, %{context: %{current_user: _user}}) do
    case Push.unregister_device(token) do
      {:ok, _} -> {:ok, true}
      {:error, :not_found} -> {:error, "Device not found"}
      {:error, _} -> {:error, "Failed to unregister device"}
    end
  end

  def unregister(_parent, _args, _context) do
    {:error, "Not authenticated"}
  end

  defp format_errors(changeset) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Enum.reduce(opts, msg, fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end)
      end)

    "Validation failed: #{inspect(errors)}"
  end
end
