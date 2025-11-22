defmodule FangornSentinel.Push.PushDeviceTest do
  use FangornSentinel.DataCase

  alias FangornSentinel.Push.PushDevice
  alias FangornSentinel.Accounts.User
  alias FangornSentinel.Repo

  setup do
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

  describe "changeset/2" do
    test "valid changeset with all required fields", %{user: user} do
      attrs = %{
        user_id: user.id,
        platform: "ios",
        device_token: "abc123token"
      }

      changeset = PushDevice.changeset(%PushDevice{}, attrs)

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :platform) == "ios"
      assert Ecto.Changeset.get_field(changeset, :device_token) == "abc123token"
      assert Ecto.Changeset.get_field(changeset, :enabled) == true
    end

    test "valid changeset with optional fields", %{user: user} do
      attrs = %{
        user_id: user.id,
        platform: "android",
        device_token: "fcm_token_xyz",
        device_name: "Pixel 8",
        app_version: "1.0.0",
        os_version: "14",
        enabled: false
      }

      changeset = PushDevice.changeset(%PushDevice{}, attrs)

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :device_name) == "Pixel 8"
      assert Ecto.Changeset.get_field(changeset, :app_version) == "1.0.0"
      assert Ecto.Changeset.get_field(changeset, :os_version) == "14"
      assert Ecto.Changeset.get_field(changeset, :enabled) == false
    end

    test "requires user_id" do
      attrs = %{
        platform: "ios",
        device_token: "token123"
      }

      changeset = PushDevice.changeset(%PushDevice{}, attrs)

      refute changeset.valid?
      assert %{user_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "requires platform" do
      attrs = %{
        user_id: 1,
        device_token: "token123"
      }

      changeset = PushDevice.changeset(%PushDevice{}, attrs)

      refute changeset.valid?
      assert %{platform: ["can't be blank"]} = errors_on(changeset)
    end

    test "requires device_token" do
      attrs = %{
        user_id: 1,
        platform: "ios"
      }

      changeset = PushDevice.changeset(%PushDevice{}, attrs)

      refute changeset.valid?
      assert %{device_token: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates platform is ios or android" do
      attrs = %{
        user_id: 1,
        platform: "windows",
        device_token: "token123"
      }

      changeset = PushDevice.changeset(%PushDevice{}, attrs)

      refute changeset.valid?
      assert %{platform: ["is invalid"]} = errors_on(changeset)
    end

    test "accepts ios platform", %{user: user} do
      attrs = %{
        user_id: user.id,
        platform: "ios",
        device_token: "token123"
      }

      changeset = PushDevice.changeset(%PushDevice{}, attrs)
      assert changeset.valid?
    end

    test "accepts android platform", %{user: user} do
      attrs = %{
        user_id: user.id,
        platform: "android",
        device_token: "token123"
      }

      changeset = PushDevice.changeset(%PushDevice{}, attrs)
      assert changeset.valid?
    end

    test "defaults enabled to true", %{user: user} do
      attrs = %{
        user_id: user.id,
        platform: "ios",
        device_token: "token123"
      }

      changeset = PushDevice.changeset(%PushDevice{}, attrs)

      assert Ecto.Changeset.get_field(changeset, :enabled) == true
    end
  end

  describe "database constraints" do
    test "enforces unique device_token", %{user: user} do
      attrs = %{
        user_id: user.id,
        platform: "ios",
        device_token: "unique_token_123"
      }

      {:ok, _device1} =
        %PushDevice{}
        |> PushDevice.changeset(attrs)
        |> Repo.insert()

      # Try to insert same token again
      assert {:error, changeset} =
               %PushDevice{}
               |> PushDevice.changeset(attrs)
               |> Repo.insert()

      assert %{device_token: ["has already been taken"]} = errors_on(changeset)
    end

    test "deletes device when user is deleted", %{user: user} do
      {:ok, device} =
        %PushDevice{}
        |> PushDevice.changeset(%{
          user_id: user.id,
          platform: "ios",
          device_token: "token_to_delete"
        })
        |> Repo.insert()

      # Delete user
      Repo.delete!(user)

      # Device should be deleted too
      assert is_nil(Repo.get(PushDevice, device.id))
    end
  end
end
