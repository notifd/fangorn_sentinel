defmodule FangornSentinel.Push.FCMDispatcher do
  @moduledoc """
  Pigeon dispatcher for Firebase Cloud Messaging (FCM).

  This module is only started if FCM is configured in the environment.
  """
  use Pigeon.Dispatcher, otp_app: :fangorn_sentinel
end
