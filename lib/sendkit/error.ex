defmodule SendKit.Error do
  @moduledoc """
  Error returned by the SendKit API.
  """

  defexception [:name, :message, :status_code]

  @type t :: %__MODULE__{
          name: String.t(),
          message: String.t(),
          status_code: integer() | nil
        }

  @impl true
  def message(%__MODULE__{name: name, message: message, status_code: nil}) do
    "#{name}: #{message}"
  end

  def message(%__MODULE__{name: name, message: message, status_code: status_code}) do
    "#{name} (#{status_code}): #{message}"
  end
end
