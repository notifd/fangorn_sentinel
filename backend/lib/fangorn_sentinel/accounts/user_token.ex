defmodule FangornSentinel.Accounts.UserToken do
  @moduledoc """
  Schema for user tokens used for session, password reset, and email verification.
  """
  use Ecto.Schema
  import Ecto.Query

  @rand_size 32
  @hash_algorithm :sha256

  # Token validity periods
  @session_validity_in_days 60
  @reset_password_validity_in_hours 1
  @confirm_validity_in_days 7

  schema "users_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string

    belongs_to :user, FangornSentinel.Accounts.User

    timestamps(updated_at: false)
  end

  @doc """
  Generates a session token.
  """
  def build_session_token(user) do
    token = :crypto.strong_rand_bytes(@rand_size)
    {token, %__MODULE__{token: token, context: "session", user_id: user.id}}
  end

  @doc """
  Builds a token and its hash for email-based tokens (reset password, confirm email).
  """
  def build_email_token(user, context) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %__MODULE__{
       token: hashed_token,
       context: context,
       sent_to: user.email,
       user_id: user.id
     }}
  end

  @doc """
  Returns the query for checking session token validity.
  """
  def verify_session_token_query(token) do
    query =
      from t in __MODULE__,
        where: t.token == ^token and t.context == "session",
        where: t.inserted_at > ago(@session_validity_in_days, "day"),
        join: u in assoc(t, :user),
        select: u

    {:ok, query}
  end

  @doc """
  Returns the query for checking email token validity.
  """
  def verify_email_token_query(token, context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)
        days = days_for_context(context)

        query =
          from t in __MODULE__,
            where: t.token == ^hashed_token and t.context == ^context,
            where: t.inserted_at > ago(^days, "day"),
            join: u in assoc(t, :user),
            select: u

        {:ok, query}

      :error ->
        :error
    end
  end

  defp days_for_context("reset_password"), do: div(@reset_password_validity_in_hours, 24) + 1
  defp days_for_context("confirm"), do: @confirm_validity_in_days
  defp days_for_context(_), do: 0

  @doc """
  Returns the query for deleting user tokens.
  """
  def user_and_contexts_query(user, :all) do
    from t in __MODULE__, where: t.user_id == ^user.id
  end

  def user_and_contexts_query(user, contexts) when is_list(contexts) do
    from t in __MODULE__, where: t.user_id == ^user.id and t.context in ^contexts
  end
end
