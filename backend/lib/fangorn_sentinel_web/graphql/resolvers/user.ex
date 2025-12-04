defmodule FangornSentinelWeb.GraphQL.Resolvers.User do
  alias FangornSentinel.Accounts
  alias FangornSentinel.Accounts.User

  def me(_parent, _args, %{context: %{current_user: user}}) do
    {:ok, user}
  end

  def me(_parent, _args, _context) do
    {:error, "Not authenticated"}
  end

  def login(_parent, %{email: email, password: password}, _context) do
    case Accounts.get_user_by_email_and_password(email, password) do
      %User{} = user ->
        case FangornSentinel.Guardian.encode_and_sign(user) do
          {:ok, token, _claims} ->
            {:ok, %{token: token, user: user}}

          {:error, reason} ->
            {:error, "Authentication failed: #{inspect(reason)}"}
        end

      nil ->
        # Prevent timing attacks
        Bcrypt.no_user_verify()
        {:error, "Invalid email or password"}
    end
  end
end
