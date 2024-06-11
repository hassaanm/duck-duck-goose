defmodule Birds.DB.TestDB do
  @behaviour Birds.DB.Database

  use Agent

  @spec start(integer()) :: {:error, any()} | {:ok, pid()}
  def start(start_time) do
    Agent.start(fn -> %{time: start_time} end, name: __MODULE__)
  end

  @spec advance_time(integer()) :: :ok
  def advance_time(seconds) do
    Agent.update(__MODULE__, fn state -> Map.update!(state, :time, &(&1 + seconds)) end)
    :ok
  end

  @spec reset() :: :ok
  def reset() do
    time = curr_time()
    Agent.update(__MODULE__, fn _state -> %{time: time} end)
  end

  @impl Birds.DB.Database
  @spec get(String.t()) :: any()
  def get(key) do
    Agent.get(__MODULE__, fn state ->
      case Map.get(state, key) do
        {value, expires_at} ->
          if :os.system_time(:seconds) < expires_at do
            value
          end

        _ ->
          nil
      end
    end)
  end

  @impl Birds.DB.Database
  @spec put(String.t(), any(), integer()) :: :ok
  def put(key, value, ttl) do
    expires_at = curr_time() + ttl
    Agent.update(__MODULE__, fn state -> Map.put(state, key, {value, expires_at}) end)
  end

  @impl Birds.DB.Database
  @spec put_new(String.t(), any(), integer()) :: :ok | :error
  def put_new(key, value, ttl) do
    if get(key) == nil do
      expires_at = curr_time() + ttl
      Agent.update(__MODULE__, fn state -> Map.put(state, key, {value, expires_at}) end)
    else
      :error
    end
  end

  @spec curr_time() :: integer()
  defp curr_time() do
    Agent.get(__MODULE__, fn state -> Map.get(state, :time) end)
  end
end
