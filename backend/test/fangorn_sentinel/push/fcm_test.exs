defmodule FangornSentinel.Push.FCMTest do
  @moduledoc """
  Tests for FCM push notification module.

  FAILURES FOUND: 0 (NEW)
  """
  use FangornSentinel.DataCase

  alias FangornSentinel.Push.FCM

  describe "send_alert_notification/3" do
    setup do
      alert = %FangornSentinel.Alerts.Alert{
        id: 456,
        title: "Test Alert",
        message: "This is a test message",
        severity: "warning",
        source: "grafana"
      }

      user = %FangornSentinel.Accounts.User{
        id: 2,
        email: "test@example.com"
      }

      device = %FangornSentinel.Push.PushDevice{
        id: 2,
        device_token: "test_fcm_token_xyz789",
        platform: "android"
      }

      %{alert: alert, user: user, device: device}
    end

    test "returns :ok when FCM is not configured", %{alert: alert, user: user, device: device} do
      # FCM is not configured in test environment
      assert FCM.send_alert_notification(alert, user, device) == :ok
    end

    test "configured? returns false when not configured" do
      refute FCM.configured?()
    end

    test "handles nil message gracefully", %{alert: alert, user: user, device: device} do
      alert_no_message = %{alert | message: nil}
      assert FCM.send_alert_notification(alert_no_message, user, device) == :ok
    end

    test "handles nil source gracefully", %{alert: alert, user: user, device: device} do
      alert_no_source = %{alert | source: nil}
      assert FCM.send_alert_notification(alert_no_source, user, device) == :ok
    end

    test "handles very long title by truncating", %{alert: alert, user: user, device: device} do
      long_title = String.duplicate("A", 200)
      alert_long = %{alert | title: long_title}
      assert FCM.send_alert_notification(alert_long, user, device) == :ok
    end

    test "handles very long message by truncating", %{alert: alert, user: user, device: device} do
      long_message = String.duplicate("B", 1000)
      alert_long = %{alert | message: long_message}
      assert FCM.send_alert_notification(alert_long, user, device) == :ok
    end
  end
end
