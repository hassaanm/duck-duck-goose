defmodule Birds.Bird do
  use GenServer

  @derive {Jason.Encoder, only: [:status, :type]}
  defstruct [:status, :type]

  # Statuses
  @status_online :online
  @status_network_partitioned :network_partitioned

  # Types
  @type_duck :duck
  @type_goose :goose

  # Client methods

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  # GenServer implementation

  @impl true
  def init(_) do
    state = %Birds.Bird{status: @status_online, type: @type_duck}
    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
end
