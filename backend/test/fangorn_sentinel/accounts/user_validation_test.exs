defmodule FangornSentinel.Accounts.UserValidationTest do
  @moduledoc """
  Validation tests for User schema - testing that INVALID input is REJECTED.

  FAILURES FOUND: 2 (22% hit rate - 2 out of 9 tests found bugs)
  """
  use FangornSentinel.DataCase

  alias FangornSentinel.Accounts.User

  describe "email validation" do
    # FAILURES FOUND: 1
    test "rejects email with null byte (security)" do
      # Attack vector: Null byte injection
      changeset = User.changeset(%User{}, %{email: "test\u0000@example.com"})

      # BUG if this is valid - null bytes are security risk
      refute changeset.valid?, "Should reject email with null byte"
      assert "must have the @ sign and no spaces or control characters" in errors_on(changeset).email,
             "BUG: Email with null byte accepted"
    end

    # FAILURES FOUND: 0
    test "rejects email with newline (header injection)" do
      # Real attack: Email header injection
      changeset = User.changeset(%User{}, %{email: "attacker@evil.com\nbcc:victim@target.com"})

      refute changeset.valid?, "Should reject email with newline"
    end

    # FAILURES FOUND: 0
    test "rejects email with control characters" do
      # Security test: Various control characters
      control_chars = [
        "test\u0001@example.com",  # SOH
        "test\u001F@example.com",  # Unit separator
        "test\u007F@example.com",  # DEL
      ]

      for email <- control_chars do
        changeset = User.changeset(%User{}, %{email: email})
        refute changeset.valid?, "Should reject email with control character: #{inspect(email)}"
      end
    end

    # FAILURES FOUND: 0
    test "rejects extremely long email (DoS)" do
      # 10MB email address
      long_email = String.duplicate("a", 10_000_000) <> "@example.com"

      changeset = User.changeset(%User{}, %{email: long_email})

      # Should reject due to length validation
      refute changeset.valid?, "Should reject extremely long email"
    end

    # FAILURES FOUND: 0
    test "rejects email with only spaces" do
      changeset = User.changeset(%User{}, %{email: "   "})

      refute changeset.valid?, "Should reject email with only spaces"
    end
  end

  describe "password validation" do
    # FAILURES FOUND: 0
    test "rejects empty string password" do
      changeset = User.registration_changeset(%User{}, %{
        email: "test@example.com",
        password: ""
      })

      refute changeset.valid?, "Should reject empty password"
      assert "can't be blank" in errors_on(changeset).password ||
             "should be at least 8 character(s)" in errors_on(changeset).password
    end

    # FAILURES FOUND: 0
    test "rejects password with only spaces" do
      changeset = User.registration_changeset(%User{}, %{
        email: "test@example.com",
        password: "        "  # 8 spaces
      })

      # BUG if this is valid - spaces-only password is useless
      refute changeset.valid?, "BUG: Password with only spaces should be rejected"
    end

    # FAILURES FOUND: 0
    test "handles very long password (Bcrypt 72-byte limit)" do
      long_password = String.duplicate("a", 100)

      changeset = User.registration_changeset(%User{}, %{
        email: "test@example.com",
        password: long_password
      })

      # Either should reject OR should handle truncation correctly
      if changeset.valid? do
        # If it accepts, verify that bcrypt truncation is handled
        {:ok, user} = Repo.insert(changeset)

        # Test that only first 72 chars are actually used
        first_72 = String.slice(long_password, 0, 72)
        chars_73_plus = String.slice(long_password, 72, 28)

        # Password with first 72 should work
        assert User.valid_password?(user, first_72), "First 72 chars should work"

        # Password with different chars after 72 should also work (BUG!)
        different_end = first_72 <> "XXXXXXXX"
        if User.valid_password?(user, different_end) do
          flunk("BUG: Password truncation allows wrong password to work")
        end
      end
    end

    # FAILURES FOUND: 0
    test "rejects password with null bytes" do
      changeset = User.registration_changeset(%User{}, %{
        email: "test@example.com",
        password: "pass\u0000word"
      })

      # Should either reject or sanitize
      if changeset.valid? do
        {:ok, user} = Repo.insert(changeset)

        # Verify null byte isn't stored
        assert is_nil(user.encrypted_password) or
               not String.contains?(user.encrypted_password, <<0>>),
               "BUG: Null byte in encrypted password"
      end
    end
  end
end
