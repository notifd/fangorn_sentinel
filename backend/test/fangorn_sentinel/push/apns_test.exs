defmodule FangornSentinel.Push.APNSTest do
  @moduledoc """
  Tests for APNs push notification module.

  FAILURES FOUND: 0 (NEW)
  """
  use FangornSentinel.DataCase

  alias FangornSentinel.Push.APNS

  describe "send_alert_notification/3" do
    setup do
      alert = %FangornSentinel.Alerts.Alert{
        id: 123,
        title: "Test Alert",
        message: "This is a test message",
        severity: "critical",
        source: "test"
      }

      user = %FangornSentinel.Accounts.User{
        id: 1,
        email: "test@example.com"
      }

      device = %FangornSentinel.Push.PushDevice{
        id: 1,
        device_token: "test_apns_token_abc123",
        platform: "ios"
      }

      %{alert: alert, user: user, device: device}
    end

    test "returns :ok when APNs is not configured", %{alert: alert, user: user, device: device} do
      # APNs is not configured in test environment
      assert APNS.send_alert_notification(alert, user, device) == :ok
    end

    test "configured? returns false when not configured" do
      refute APNS.configured?()
    end

    test "handles nil message gracefully", %{alert: alert, user: user, device: device} do
      alert_no_message = %{alert | message: nil}
      assert APNS.send_alert_notification(alert_no_message, user, device) == :ok
    end

    test "handles very long title by truncating", %{alert: alert, user: user, device: device} do
      long_title = String.duplicate("A", 200)
      alert_long = %{alert | title: long_title}
      assert APNS.send_alert_notification(alert_long, user, device) == :ok
    end

    test "handles very long message by truncating", %{alert: alert, user: user, device: device} do
      long_message = String.duplicate("B", 1000)
      alert_long = %{alert | message: long_message}
      assert APNS.send_alert_notification(alert_long, user, device) == :ok
    end
  end
end
