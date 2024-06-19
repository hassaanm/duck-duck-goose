defmodule Birds.Bird do
  use GenServer

  @derive {Jason.Encoder, only: [:status, :type]}
  defstruct [:db, :port, :status, :type]

  #############
  # Constants #
  #############

  # Network
  @host "localhost"
  @halt Application.compile_env(:birds, :halt)

  # DB
  @ttl 10
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
  def shutdown(port)
  def shutdown(port) when is_integer(port), do: shutdown(port_atom(port))
  def shutdown(port) when is_atom(port), do: GenServer.call(port, :shutdown)

  ############################
  # GenServer implementation #
  ############################

  @impl true
  def init({db, port}) do
    url = "#{@host}:#{port}"
    become_goose = db.put_new(@goose_key, url, @ttl)
    type = if become_goose == :ok, do: @type_goose, else: @type_duck

    state = %Birds.Bird{db: db, port: port, status: @status_online, type: type}
    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  @impl true
  def handle_call(:shutdown, _from, state) do
    # If halting, then halt after a short delay
    if @halt do
      Process.send_after(self(), :halt, 10)
    end

    {:reply, :ok, %Birds.Bird{state | status: @status_offline}}
  end

  @impl true
  def handle_info(:halt, _state), do: System.halt(0)

  ###################
  # Private helpers #
  ###################

  @spec port_atom(port :: integer()) :: atom()
  defp port_atom(port) do
    port
    |> Integer.to_string()
    |> String.to_atom()
  end
end
