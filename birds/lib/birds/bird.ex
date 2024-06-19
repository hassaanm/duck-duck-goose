defmodule Birds.Bird do
  use GenServer

  @derive {Jason.Encoder, only: [:status, :type]}
  defstruct [:db, :port, :status, :type]

  #############
  # Constants #
  #############

  # Functionality
  @halt Application.compile_env(:birds, :halt)
  @halt_delay_ms 10
  @take_leadership_frequency_ms Application.compile_env(:birds, :take_leadership_frequency_ms)

  # Network
  @host "localhost"

  # DB
  @ttl_s 5
  @goose_key "goose"

  # Statuses
  @type status :: :online | :offline | :network_partitioned
  @status_online :online
  @status_offline :offline
  @status_network_partitioned :network_partitioned

  # Types
  @type type :: :duck | :goose
  @type_duck :duck
  @type_goose :goose

  ##################
  # Client methods #
  ##################

  @spec start_link(db: Birds.DB.Database.t(), port: integer()) ::
          :ignore | {:error, any()} | {:ok, pid()}
  def start_link(db: db, port: port) do
    GenServer.start_link(__MODULE__, {db, port}, name: port_atom(port))
  end

  @spec get_state(port :: atom() | integer()) :: %{status: status(), type: type()}
  def get_state(port) when is_integer(port), do: get_state(port_atom(port))

  def get_state(port) when is_atom(port) do
    internal_state = GenServer.call(port, :get_state)
    %{status: internal_state.status, type: internal_state.type}
  end

  @spec shutdown(port :: atom() | integer()) :: :ok
  def shutdown(port) when is_integer(port), do: shutdown(port_atom(port))
  def shutdown(port) when is_atom(port), do: GenServer.call(port, :shutdown)

  @spec fix_network(port :: atom() | integer()) :: :ok
  def fix_network(port) when is_integer(port), do: fix_network(port_atom(port))
  def fix_network(port) when is_atom(port), do: GenServer.call(port, :fix_network)

  @spec terminate_network(port :: atom() | integer()) :: :ok
  def terminate_network(port) when is_integer(port), do: terminate_network(port_atom(port))
  def terminate_network(port) when is_atom(port), do: GenServer.call(port, :terminate_network)

  ############################
  # GenServer implementation #
  ############################

  @impl true
  def init({db, port}) do
    # Kick of periodic attempt to steal leadership
    Process.send(self(), :try_to_take_leadership, [])

    # Create and return state
    state = %Birds.Bird{db: db, port: port, status: @status_online, type: @type_duck}
    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  @impl true
  def handle_call(:shutdown, _from, state) do
    # If halting, then halt after a short delay
    if @halt do
      Process.send_after(self(), :halt, @halt_delay_ms)
    end

    {:reply, :ok, %Birds.Bird{state | status: @status_offline}}
  end

  @impl true
  def handle_call(:fix_network, _from, state) do
    {:reply, :ok, %Birds.Bird{state | status: @status_online}}
  end

  @impl true
  def handle_call(:terminate_network, _from, state) do
    {:reply, :ok, %Birds.Bird{state | status: @status_network_partitioned}}
  end

  @impl true
  def handle_info(:halt, _state), do: System.halt(0)

  @impl true
  def handle_info(:try_to_take_leadership, state) do
    # Try to take leadership if duck / maintain leadership if goose
    url = "#{@host}:#{state.port}"
    become_goose = db_put_new(state, @goose_key, url, @ttl_s)
    type = if become_goose == :ok, do: @type_goose, else: @type_duck

    # Repeat after a delay
    Process.send_after(self(), :try_to_take_leadership, @take_leadership_frequency_ms)

    # Update type in state
    {:noreply, %Birds.Bird{state | type: type}}
  end

  ###################
  # Private helpers #
  ###################

  @spec port_atom(port :: integer()) :: atom()
  defp port_atom(port) do
    port
    |> Integer.to_string()
    |> String.to_atom()
  end

  @spec db_put_new(
          state :: %Birds.Bird{},
          key :: String.t(),
          value :: String.t(),
          ttl :: integer()
        ) :: :ok | :error
  defp db_put_new(state, key, value, ttl) do
    # Wrap calls to the DB to simulate network failure behavior
    if state.status == @status_online do
      state.db.put_new(key, value, ttl)
    else
      :error
    end
  end
end
