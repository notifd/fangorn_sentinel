defmodule FangornSentinel.Guardian do
  use Guardian, otp_app: :fangorn_sentinel

  alias FangornSentinel.Accounts

  def subject_for_token(%{id: id}, _claims) do
    {:ok, to_string(id)}
  end

  def subject_for_token(_, _) do
    {:error, :invalid_resource}
  end

  def resource_from_claims(%{"sub" => id}) when is_binary(id) do
    case Integer.parse(id) do
      {int_id, ""} when int_id > 0 ->
        case Accounts.get_user(int_id) do
          nil -> {:error, :user_not_found}
          user -> {:ok, user}
        end

      _ ->
        {:error, :invalid_sub}
    end
  end

  def resource_from_claims(%{"sub" => id}) when is_integer(id) and id > 0 do
    case Accounts.get_user(id) do
      nil -> {:error, :user_not_found}
      user -> {:ok, user}
    end
  end

  def resource_from_claims(%{"sub" => _}) do
    {:error, :invalid_sub}
  end

  def resource_from_claims(_claims) do
    {:error, :invalid_claims}
  end
end
