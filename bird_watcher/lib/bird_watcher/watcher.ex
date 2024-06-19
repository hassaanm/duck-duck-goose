defmodule BirdWatcher.Watcher do
  use GenServer

  defstruct [:bird_statuses]

  #############
  # Constants #
  #############

  @polling_frequency 1000

  ##################
  # Client methods #
  ##################

  @spec start_link(_opts :: any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @spec get_statuses() :: map()
  def get_statuses() do
    state = GenServer.call(__MODULE__, :get_state)
    state.bird_statuses
  end

  ############################
  # GenServer implementation #
  ############################

  @impl true
  def init(_) do
    # Kick of polling updates
    schedule_polling()

    {:ok, %BirdWatcher.Watcher{bird_statuses: %{}}}
  end

  @impl true
  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  @impl true
  def handle_info(:poll_status, _state) do
    # Fetch bird urls
    bird_urls =
      BirdWatcher.DB.get_all()
      |> Map.values()
      |> Stream.map(fn {value, _ttl} -> value end)
      |> Stream.filter(fn value -> String.match?(value, ~r/localhost:\d+/) end)
      |> Enum.to_list()

    # Fetch status for each bird
    bird_statuses =
      bird_urls
      |> Map.new(fn bird_url ->
        case HTTPoison.get("#{bird_url}/status") do
          {:ok, resp = %HTTPoison.Response{status_code: 200}} ->
            {bird_url, Jason.decode!(resp.body)}

          _ ->
            {bird_url, %{"status" => "unavailable", "type" => "unknown"}}
        end
      end)

    # Broadcast updated statuses
    broadcast_statuses(bird_statuses)

    # Repeat after a delay
    schedule_polling()

    # Update state with new statuses
    {:noreply, %BirdWatcher.Watcher{bird_statuses: bird_statuses}}
  end

  ###################
  # Private helpers #
  ###################

  @spec schedule_polling() :: any()
  defp schedule_polling() do
    Process.send_after(self(), :poll_status, @polling_frequency)
  end

  @spec broadcast_statuses(statuses :: map()) :: any()
  defp broadcast_statuses(statuses) do
    Phoenix.PubSub.broadcast(BirdWatcher.PubSub, "status_updates", {:update, statuses})
  end
end
