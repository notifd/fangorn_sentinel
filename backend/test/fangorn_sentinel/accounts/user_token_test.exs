defmodule FangornSentinel.Accounts.UserTokenTest do
  @moduledoc """
  Tests for UserToken schema.

  FAILURES FOUND: 0 (NEW)
  """
  use FangornSentinel.DataCase

  alias FangornSentinel.Accounts.{User, UserToken}

  describe "build_session_token/1" do
    test "generates a token and struct for a user" do
      user = %User{id: 1, email: "test@example.com"}
      {token, user_token} = UserToken.build_session_token(user)

      assert is_binary(token)
      assert byte_size(token) == 32
      assert user_token.token == token
      assert user_token.context == "session"
      assert user_token.user_id == 1
    end
  end

  describe "build_email_token/2" do
    test "generates an encoded token and hashed struct for reset_password" do
      user = %User{id: 1, email: "test@example.com"}
      {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")

      assert is_binary(encoded_token)
      assert user_token.context == "reset_password"
      assert user_token.sent_to == "test@example.com"
      assert user_token.user_id == 1
      # Token should be hashed (different from encoded)
      assert {:ok, decoded} = Base.url_decode64(encoded_token, padding: false)
      assert user_token.token == :crypto.hash(:sha256, decoded)
    end

    test "generates an encoded token for confirm" do
      user = %User{id: 1, email: "test@example.com"}
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")

      assert is_binary(encoded_token)
      assert user_token.context == "confirm"
      assert user_token.sent_to == "test@example.com"
    end
  end

  describe "verify_email_token_query/2" do
    test "returns error for invalid base64 token" do
      assert UserToken.verify_email_token_query("not-valid-base64!!!", "reset_password") == :error
    end

    test "returns query for valid token format" do
      {:ok, decoded} = Base.url_decode64("dGVzdHRva2VuMTIzNDU2Nzg5MDEyMzQ1Njc4OTA", padding: false)
      assert {:ok, query} = UserToken.verify_email_token_query("dGVzdHRva2VuMTIzNDU2Nzg5MDEyMzQ1Njc4OTA", "reset_password")
      assert %Ecto.Query{} = query
    end
  end

  describe "user_and_contexts_query/2" do
    test "returns query for all contexts" do
      user = %User{id: 1}
      query = UserToken.user_and_contexts_query(user, :all)
      assert %Ecto.Query{} = query
    end

    test "returns query for specific contexts" do
      user = %User{id: 1}
      query = UserToken.user_and_contexts_query(user, ["session", "reset_password"])
      assert %Ecto.Query{} = query
    end
  end
end
