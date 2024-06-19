defmodule Birds.DB.Database do
  @callback get(key :: String.t()) :: String.t() | nil
  @callback put(key :: String.t(), value :: String.t(), ttl :: integer() | nil) :: :ok
  @callback put_new(key :: String.t(), value :: String.t(), ttl :: integer() | nil) ::
              :ok | :error

  @type t() :: module()
end
