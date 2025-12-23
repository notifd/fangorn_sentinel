defmodule FangornSentinel.Workers.NotifierValidationTest do
  @moduledoc """
  Validation tests for Notifier worker.

  FAILURES FOUND: 2
  - Bug #21: nil alert_id crashes with ArgumentError
  - Bug #22: nil user_id crashes with ArgumentError
  """
  use FangornSentinel.DataCase
  use Oban.Testing, repo: FangornSentinel.Repo

  alias FangornSentinel.Workers.Notifier
  alias FangornSentinel.Alerts
  alias FangornSentinel.Push

  describe "notifier validation" do
    setup do
      {:ok, user} = FangornSentinel.Accounts.create_user(%{
        email: "notifier_test@example.com",
        password: "password123"
      })
      {:ok, alert} = Alerts.create_alert(%{
        title: "Test Alert",
        message: "Test message",
        severity: "critical",
        source: "test",
        status: "firing",
        fired_at: DateTime.utc_now()
      })
      %{user: user, alert: alert}
    end

    # FAILURES FOUND: 0
    test "handles non-existent alert_id" do
      result = perform_job(Notifier, %{alert_id: 999999, user_id: 1})

      assert result == {:error, :alert_not_found}
    end

    # FAILURES FOUND: 0
    test "handles non-existent user_id", %{alert: alert} do
      result = perform_job(Notifier, %{alert_id: alert.id, user_id: 999999})

      assert result == {:error, :user_not_found}
    end

    # FAILURES FOUND: 1 (Bug #21 - ArgumentError on nil ID)
    test "handles nil alert_id", %{user: user} do
      result = perform_job(Notifier, %{alert_id: nil, user_id: user.id})

      assert {:error, :invalid_alert_id} = result
    end

    # FAILURES FOUND: 1 (Bug #22 - ArgumentError on nil ID)
    test "handles nil user_id", %{alert: alert} do
      result = perform_job(Notifier, %{alert_id: alert.id, user_id: nil})

      assert {:error, :invalid_user_id} = result
    end

    # FAILURES FOUND: 0
    test "handles user with no devices", %{alert: alert, user: user} do
      # User has no push devices registered
      result = perform_job(Notifier, %{alert_id: alert.id, user_id: user.id})

      # Should not crash, just complete with no notifications
      assert result == :ok
    end

    # FAILURES FOUND: 0
    test "handles user with disabled devices", %{alert: alert, user: user} do
      # Register device then disable it
      {:ok, _device} = Push.register_device(%{
        user_id: user.id,
        device_token: "disabled_device_token",
        platform: "ios",
        enabled: false
      })

      result = perform_job(Notifier, %{alert_id: alert.id, user_id: user.id})

      # Should complete without errors (disabled devices filtered)
      assert result == :ok
    end

    # FAILURES FOUND: 0
    test "handles user with unknown platform device", %{alert: alert, user: user} do
      # Bypass validation to insert device with unknown platform
      device = %FangornSentinel.Push.PushDevice{
        user_id: user.id,
        device_token: "unknown_platform_token",
        platform: "blackberry",  # Not ios or android
        enabled: true
      }
      FangornSentinel.Repo.insert!(device)

      result = perform_job(Notifier, %{alert_id: alert.id, user_id: user.id})

      # Should not crash on unknown platform
      assert result == :ok
    end
  end
end
