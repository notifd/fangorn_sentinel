defmodule FangornSentinelWeb.GraphQL.Resolvers.Device do
  alias FangornSentinel.Push

  def register(_parent, args, %{context: %{current_user: user}}) do
    device_params = %{
      user_id: user.id,
      device_token: args[:token],
      platform: args[:platform],
      device_name: args[:device_name]
    }

    case Push.register_device(device_params) do
      {:ok, device} -> {:ok, device}
      {:error, changeset} -> {:error, "Failed to register device: #{inspect(changeset.errors)}"}
    end
  end

  def register(_parent, _args, _context) do
    {:error, "Not authenticated"}
  end
end
