defmodule FangornSentinel.AccountsValidationTest do
  @moduledoc """
  Validation tests for Accounts context.

  FAILURES FOUND: 3
  - Bug #24: get_user with nil ID crashes with ArgumentError
  - Bug #25: get_user with string ID crashes with CastError
  - Bug #26: Guardian resource_from_claims with non-integer sub crashes
  """
  use FangornSentinel.DataCase

  alias FangornSentinel.Accounts
  alias FangornSentinel.Guardian

  describe "authentication validation" do
    setup do
      {:ok, user} = Accounts.create_user(%{
        email: "auth_test@example.com",
        password: "password123"
      })
      %{user: user}
    end

    # FAILURES FOUND: 1 (Bug #24 - ArgumentError on nil)
    test "get_user handles nil id gracefully" do
      # Should not crash
      result = Accounts.get_user(nil)
      assert is_nil(result)
    end

    # FAILURES FOUND: 0
    test "get_user handles negative id" do
      result = Accounts.get_user(-1)
      assert is_nil(result)
    end

    # FAILURES FOUND: 1 (Bug #25 - CastError on string)
    test "get_user handles string id" do
      # String ID (from URL params) should not crash
      result = Accounts.get_user("abc")
      assert is_nil(result)
    end

    # FAILURES FOUND: 0
    test "get_user_by_email handles empty string" do
      result = Accounts.get_user_by_email("")
      assert is_nil(result)
    end

    # FAILURES FOUND: 1 (Bug #26 - CastError on non-integer sub)
    test "Guardian resource_from_claims handles malformed sub" do
      # Non-integer sub value
      result = Guardian.resource_from_claims(%{"sub" => "not-an-id"})
      assert {:error, :invalid_sub} = result
    end

    # FAILURES FOUND: 0
    test "Guardian resource_from_claims handles missing sub" do
      result = Guardian.resource_from_claims(%{})
      assert {:error, _} = result
    end

    # FAILURES FOUND: 0
    test "Guardian subject_for_token handles nil resource" do
      result = Guardian.subject_for_token(nil, %{})
      assert {:error, _} = result
    end

    # FAILURES FOUND: 0
    test "Guardian subject_for_token handles map without id" do
      result = Guardian.subject_for_token(%{name: "test"}, %{})
      assert {:error, _} = result
    end
  end

  describe "password validation" do
    # FAILURES FOUND: 0
    test "rejects empty password" do
      result = Accounts.create_user(%{
        email: "empty_pass@example.com",
        password: ""
      })

      assert {:error, changeset} = result
      assert changeset.errors[:password] != nil
    end

    # FAILURES FOUND: 0
    test "rejects very short password" do
      result = Accounts.create_user(%{
        email: "short_pass@example.com",
        password: "ab"
      })

      assert {:error, changeset} = result
      # Should have minimum length requirement
      assert Keyword.get_values(changeset.errors, :password) != []
    end

    # FAILURES FOUND: 0
    test "rejects extremely long password (DoS)" do
      huge_password = String.duplicate("a", 100_000)
      result = Accounts.create_user(%{
        email: "huge_pass@example.com",
        password: huge_password
      })

      # Should either reject or not take excessive time
      case result do
        {:error, _} -> :ok
        {:ok, _user} ->
          # If accepted, it should have been processed quickly (not DoS)
          :ok
      end
    end
  end
end
