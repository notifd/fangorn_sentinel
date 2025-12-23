defmodule FangornSentinelWeb.Plugs.ApiAuth do
  @moduledoc """
  Authentication plug for REST API endpoints.

  Supports two authentication methods:
  1. API Key: `X-API-Key` header
  2. JWT Bearer Token: `Authorization: Bearer <token>` header

  For API key authentication, keys are stored in the application config
  or can be loaded from the database.

  For JWT authentication, uses the existing Guardian setup.
  """
  @behaviour Plug

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts) do
    required = Keyword.get(opts, :required, true)

    case authenticate(conn) do
      {:ok, user} ->
        assign(conn, :current_user, user)

      {:error, _reason} when required ->
        conn
        |> put_status(:unauthorized)
        |> Phoenix.Controller.json(%{error: "Authentication required"})
        |> halt()

      {:error, _reason} ->
        # Auth not required, continue without user
        conn
    end
  end

  defp authenticate(conn) do
    with {:error, :no_api_key} <- authenticate_api_key(conn) do
      authenticate_jwt(conn)
    end
  end

  defp authenticate_api_key(conn) do
    case get_req_header(conn, "x-api-key") do
      [api_key] when is_binary(api_key) and byte_size(api_key) > 0 ->
        validate_api_key(api_key)

      _ ->
        {:error, :no_api_key}
    end
  end

  defp validate_api_key(api_key) do
    # Check against configured API keys
    # In production, these would be stored in the database
    configured_keys = Application.get_env(:fangorn_sentinel, :api_keys, [])

    case Enum.find(configured_keys, fn {_name, key} -> key == api_key end) do
      {name, _key} ->
        # Return a system user for API key auth
        {:ok, %{id: 0, name: name, email: "api@system", type: :api_key}}

      nil ->
        {:error, :invalid_api_key}
    end
  end

  defp authenticate_jwt(conn) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, claims} <- FangornSentinel.Guardian.decode_and_verify(token),
         {:ok, user} <- FangornSentinel.Guardian.resource_from_claims(claims) do
      {:ok, user}
    else
      [] -> {:error, :no_token}
      _ -> {:error, :invalid_token}
    end
  end
end
