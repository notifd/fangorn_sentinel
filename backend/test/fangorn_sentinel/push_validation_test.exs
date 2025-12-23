defmodule FangornSentinel.PushValidationTest do
  @moduledoc """
  Validation tests for Push device registration.

  FAILURES FOUND: 3
  - Bug #16: Nil device token crashes with ArgumentError
  - Bug #17: Long token crashes with string_data_right_truncation
  - Bug #18: Null bytes crash PostgreSQL with UTF8 encoding error
  """
  use FangornSentinel.DataCase

  alias FangornSentinel.Push
  alias FangornSentinel.Push.PushDevice

  describe "device registration validation" do
    setup do
      {:ok, user} = FangornSentinel.Accounts.create_user(%{
        email: "test@example.com",
        password: "password123"
      })
      %{user: user}
    end

    # FAILURES FOUND: 0
    test "rejects device with empty token", %{user: user} do
      result = Push.register_device(%{
        user_id: user.id,
        device_token: "",
        platform: "ios"
      })

      # BUG if this succeeds - empty token can't receive notifications
      assert {:error, changeset} = result
      assert "can't be blank" in errors_on(changeset).device_token ||
             changeset.errors[:device_token] != nil,
             "BUG: Empty device token accepted"
    end

    # FAILURES FOUND: 1 (Bug #16 - ArgumentError on nil comparison)
    test "rejects device with nil token", %{user: user} do
      result = Push.register_device(%{
        user_id: user.id,
        device_token: nil,
        platform: "ios"
      })

      assert {:error, _} = result
    end

    # FAILURES FOUND: 1 (Bug #17 - string_data_right_truncation crash)
    test "rejects device with extremely long token (DoS)", %{user: user} do
      # Real FCM/APNS tokens are ~150-250 chars
      huge_token = String.duplicate("A", 10_000)

      result = Push.register_device(%{
        user_id: user.id,
        device_token: huge_token,
        platform: "ios"
      })

      # Should either reject or truncate
      case result do
        {:error, _} -> :ok
        {:ok, device} ->
          assert byte_size(device.device_token) < 1000,
            "BUG: 10KB device token stored (should limit length)"
      end
    end

    # FAILURES FOUND: 0
    test "rejects device with invalid platform", %{user: user} do
      result = Push.register_device(%{
        user_id: user.id,
        device_token: "valid_token_123",
        platform: "windows"  # Not a valid mobile platform
      })

      assert {:error, changeset} = result
      assert changeset.errors[:platform] != nil, "BUG: Invalid platform 'windows' accepted"
    end

    # FAILURES FOUND: 1 (Bug #18 - UTF8 encoding error)
    test "rejects device with null bytes in token", %{user: user} do
      result = Push.register_device(%{
        user_id: user.id,
        device_token: "valid\u0000token",
        platform: "ios"
      })

      # Should either reject or sanitize
      case result do
        {:error, _} -> :ok
        {:ok, device} ->
          refute String.contains?(device.device_token, <<0>>),
            "BUG: Null byte stored in device token"
      end
    end

    # FAILURES FOUND: 0
    test "rejects device with non-existent user_id", %{user: _user} do
      result = Push.register_device(%{
        user_id: 999999,  # Doesn't exist
        device_token: "valid_token",
        platform: "ios"
      })

      # Should fail with foreign key error
      assert {:error, _} = result, "BUG: Device registered for non-existent user"
    end

    # FAILURES FOUND: 0
    test "rejects device with negative user_id" do
      result = Push.register_device(%{
        user_id: -1,
        device_token: "valid_token",
        platform: "ios"
      })

      assert {:error, _} = result, "BUG: Negative user_id accepted"
    end

    # FAILURES FOUND: 0
    test "handles concurrent registration of same token", %{user: user} do
      token = "concurrent_test_token"

      # Simulate concurrent registrations
      tasks = for _ <- 1..5 do
        Task.async(fn ->
          Push.register_device(%{
            user_id: user.id,
            device_token: token,
            platform: "ios"
          })
        end)
      end

      results = Task.await_many(tasks, 5000)

      # Should all succeed or some fail gracefully (no crashes)
      success_count = Enum.count(results, fn
        {:ok, _} -> true
        _ -> false
      end)

      assert success_count >= 1, "At least one registration should succeed"

      # Verify only one device record exists
      devices = Repo.all(from d in PushDevice, where: d.device_token == ^token)
      assert length(devices) == 1, "BUG: Multiple devices with same token: #{length(devices)}"
    end
  end
end
