defmodule Cartograph.CartographParser do
  @moduledoc """
  Struct that defines a query param parsing configuration.
  """

  @enforce_keys [:handler, :keys]
  defstruct [:handler, :keys]

  @type param_handler() :: (Phoenix.LiveView.Socket.t(),
                            Phoenix.LiveView.unsigned_params(),
                            atom() ->
                              Phoenix.LiveView.Socket.t())

  @type t :: %__MODULE__{
          handler: param_handler(),
          keys: [atom()],
        }
end
