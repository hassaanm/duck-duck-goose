defmodule BirdWatcher.DB do
  use Agent

  ##################
  # Client methods #
  ##################

  @spec start_link(_opts :: any()) :: {:error, any()} | {:ok, pid()}
  def start_link(_opts) do
    Agent.start(fn -> %{} end, name: __MODULE__)
  end

  @spec get_all() :: map()
  def get_all() do
    Agent.get(__MODULE__, fn state -> state end)
  end

  @spec get(key :: String.t()) :: any()
  def get(key) do
    curr_time = curr_time()

    Agent.get(__MODULE__, fn state ->
      case Map.get(state, key) do
        {value, nil} ->
          value

        {value, expires_at} ->
          if curr_time < expires_at do
            value
          end

        _ ->
          nil
      end
    end)
  end

  @spec put(key :: String.t(), value :: any(), ttl :: integer() | nil) :: :ok
  def put(key, value, ttl) do
    expires_at = ttl && curr_time() + ttl
    Agent.update(__MODULE__, fn state -> Map.put(state, key, {value, expires_at}) end)
  end

  @spec put_new(key :: String.t(), value :: any(), ttl :: integer() | nil) :: :ok | :error
  def put_new(key, value, ttl) do
    curr_value = get(key)

    if curr_value == nil or curr_value == value do
      expires_at = ttl && curr_time() + ttl
      Agent.update(__MODULE__, fn state -> Map.put(state, key, {value, expires_at}) end)
    else
      :error
    end
  end

  ###################
  # Private helpers #
  ###################

  @spec curr_time() :: integer()
  defp curr_time() do
    :os.system_time(:seconds)
  end
end
