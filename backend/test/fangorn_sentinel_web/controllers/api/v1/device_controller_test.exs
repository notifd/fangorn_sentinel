defmodule FangornSentinelWeb.API.V1.DeviceControllerTest do
  use FangornSentinelWeb.ConnCase

  alias FangornSentinel.Push.PushDevice
  alias FangornSentinel.Accounts.User
  alias FangornSentinel.Repo

  setup do
    # Create test user
    user =
      %User{}
      |> User.changeset(%{
        email: "test@example.com",
        name: "Test User",
        encrypted_password: "hashed_password"
      })
      |> Repo.insert!()

    {:ok, user: user}
  end

  describe "POST /api/v1/devices/register" do
    test "registers a new iOS device", %{conn: conn, user: user} do
      payload = %{
        "user_id" => user.id,
        "platform" => "ios",
        "device_token" => "ios_token_abc123",
        "device_name" => "iPhone 15 Pro",
        "app_version" => "1.0.0",
        "os_version" => "17.2"
      }

      conn = post(conn, ~p"/api/v1/devices/register", payload)

      assert json_response(conn, 200) == %{
               "status" => "registered",
               "platform" => "ios"
             }

      # Verify device was created in database
      device = Repo.get_by(PushDevice, device_token: "ios_token_abc123")
      assert device != nil
      assert device.platform == "ios"
      assert device.device_name == "iPhone 15 Pro"
      assert device.user_id == user.id
      assert device.enabled == true
    end

    test "registers a new Android device", %{conn: conn, user: user} do
      payload = %{
        "user_id" => user.id,
        "platform" => "android",
        "device_token" => "fcm_token_xyz789",
        "device_name" => "Pixel 8",
        "app_version" => "1.0.0",
        "os_version" => "14"
      }

      conn = post(conn, ~p"/api/v1/devices/register", payload)

      assert json_response(conn, 200) == %{
               "status" => "registered",
               "platform" => "android"
             }

      device = Repo.get_by(PushDevice, device_token: "fcm_token_xyz789")
      assert device != nil
      assert device.platform == "android"
    end

    test "updates existing device if token already registered", %{conn: conn, user: user} do
      # Create existing device
      {:ok, _existing} =
        %PushDevice{}
        |> PushDevice.changeset(%{
          user_id: user.id,
          platform: "ios",
          device_token: "existing_token",
          device_name: "Old iPhone"
        })
        |> Repo.insert()

      # Register same token with updated info
      payload = %{
        "user_id" => user.id,
        "platform" => "ios",
        "device_token" => "existing_token",
        "device_name" => "New iPhone",
        "app_version" => "2.0.0"
      }

      conn = post(conn, ~p"/api/v1/devices/register", payload)

      assert json_response(conn, 200) == %{
               "status" => "registered",
               "platform" => "ios"
             }

      # Verify device was updated
      device = Repo.get_by(PushDevice, device_token: "existing_token")
      assert device.device_name == "New iPhone"
      assert device.app_version == "2.0.0"

      # Should still be only one device with this token
      assert Repo.aggregate(PushDevice, :count, :id) == 1
    end

    test "requires user_id", %{conn: conn} do
      payload = %{
        "platform" => "ios",
        "device_token" => "token123"
      }

      conn = post(conn, ~p"/api/v1/devices/register", payload)

      assert json_response(conn, 400) == %{
               "error" => "Invalid device registration"
             }
    end

    test "requires platform", %{conn: conn, user: user} do
      payload = %{
        "user_id" => user.id,
        "device_token" => "token123"
      }

      conn = post(conn, ~p"/api/v1/devices/register", payload)

      assert json_response(conn, 400) == %{
               "error" => "Invalid device registration"
             }
    end

    test "requires device_token", %{conn: conn, user: user} do
      payload = %{
        "user_id" => user.id,
        "platform" => "ios"
      }

      conn = post(conn, ~p"/api/v1/devices/register", payload)

      assert json_response(conn, 400) == %{
               "error" => "Invalid device registration"
             }
    end

    test "validates platform is ios or android", %{conn: conn, user: user} do
      payload = %{
        "user_id" => user.id,
        "platform" => "windows",
        "device_token" => "token123"
      }

      conn = post(conn, ~p"/api/v1/devices/register", payload)

      assert json_response(conn, 400) == %{
               "error" => "Invalid device registration"
             }
    end
  end

  describe "DELETE /api/v1/devices/unregister" do
    test "unregisters a device by token", %{conn: conn, user: user} do
      # Create device
      {:ok, _device} =
        %PushDevice{}
        |> PushDevice.changeset(%{
          user_id: user.id,
          platform: "ios",
          device_token: "token_to_delete"
        })
        |> Repo.insert()

      payload = %{"device_token" => "token_to_delete"}

      conn = delete(conn, ~p"/api/v1/devices/unregister", payload)

      assert json_response(conn, 200) == %{
               "status" => "unregistered"
             }

      # Verify device was deleted
      device = Repo.get_by(PushDevice, device_token: "token_to_delete")
      assert device == nil
    end

    test "returns ok even if device doesn't exist", %{conn: conn} do
      payload = %{"device_token" => "nonexistent_token"}

      conn = delete(conn, ~p"/api/v1/devices/unregister", payload)

      assert json_response(conn, 200) == %{
               "status" => "unregistered"
             }
    end
  end
end
