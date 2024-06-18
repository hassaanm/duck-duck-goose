defmodule BirdsTest do
  use ExUnit.Case, async: true
  doctest Birds.Bird

  #############
  # Constants #
  #############

  # Aliases
  alias Birds.DB.TestDB, as: TestDB

  # Network
  @host "localhost"
  @port_counter :port_counter

  # Types
  @type path :: :status | :kill | :terminate_network
  @path_status :status
  @path_kill :kill
  @path_terminate_network :terminate_network

  ###########
  # Helpers #
  ###########

  @spec start_port_counter() :: none()
  defp start_port_counter(), do: Agent.start_link(fn -> 5000 end, name: @port_counter)

  @spec get_next_port() :: integer()
  defp get_next_port(), do: Agent.get_and_update(@port_counter, fn port -> {port, port + 1} end)

  @spec start_bird() :: {integer(), [pid()]}
  defp start_bird() do
    port = get_next_port()
    {:ok, bandit_pid} = Bandit.start_link(%{plug: Birds.Router, scheme: :http, port: port})
    {:ok, bird_pid} = Birds.Bird.start_link(db: TestDB, port: port)

    {port, [bandit_pid, bird_pid]}
  end

  @spec url(port :: integer(), path :: path()) :: String.t()
  defp url(port, path), do: "#{@host}:#{port}/#{Atom.to_string(path)}"

  @spec get_bird_status(port :: integer()) :: map()
  defp get_bird_status(port) do
    status_url = url(port, @path_status)
    resp = HTTPoison.get!(status_url)
    Jason.decode!(resp.body)
  end

  #########
  # Setup #
  #########

  setup_all do
    # Start test db at the start of the test suite
    now = :os.system_time(:seconds)
    TestDB.start(now)

    # Start counter for ports to ensure ports aren't used between tests
    start_port_counter()

    :ok
  end

  setup do
    # Reset test db before each test
    TestDB.reset()
    :ok
  end

  #########
  # Tests #
  #########

  test "first duck to join becomes the goose" do
    {port, pids} = start_bird()

    bird_status = get_bird_status(port)
    assert Map.get(bird_status, "type") == "goose"
    assert Map.get(bird_status, "status") == "online"
  end

  test "ducks that join after there is a goose remain ducks" do
    # Start bird nodes
    {goose_port, goose_pids} = start_bird()
    {duck_1_port, duck_1_pids} = start_bird()
    {duck_2_port, duck_2_pids} = start_bird()

    # Get bird statuses
    goose_status = get_bird_status(goose_port)
    duck_1_status = get_bird_status(duck_1_port)
    duck_2_status = get_bird_status(duck_2_port)

    # Assert type and status of bird nodes
    assert Map.get(goose_status, "type") == "goose"
    assert Map.get(duck_1_status, "type") == "duck"
    assert Map.get(duck_2_status, "type") == "duck"

    assert Map.get(goose_status, "status") == "online"
    assert Map.get(duck_1_status, "status") == "online"
    assert Map.get(duck_2_status, "status") == "online"
  end

  test "all birds have a list of the ducks and the goose" do
  end

  describe "when the goose goes offline" do
    test "the goose becomes a duck" do
    end

    test "another duck becomes the goose" do
    end
  end

  describe "when the goose gets a network partition" do
    test "the goose becomes a duck" do
    end

    test "another duck becomes the goose" do
    end
  end

  describe "when a duck goes offline" do
    test "it is removed from the duck list" do
    end
  end

  describe "when a duck gets a network partition" do
    test "it is removed from the duck list" do
    end
  end
end
