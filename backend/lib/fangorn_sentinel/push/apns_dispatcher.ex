defmodule FangornSentinel.Push.APNSDispatcher do
  @moduledoc """
  Pigeon dispatcher for Apple Push Notification Service (APNs).

  This module is only started if APNs is configured in the environment.
  """
  use Pigeon.Dispatcher, otp_app: :fangorn_sentinel
end
