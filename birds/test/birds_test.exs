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
  @type path :: :status | :shutdown | :terminate_network
  @path_status :status
  @path_shutdown :shutdown
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

  @spec get_bird_status(port :: integer()) :: {200, map()} | {integer(), nil}
  defp get_bird_status(port) do
    status_url = url(port, @path_status)
    resp = HTTPoison.get!(status_url)

    if resp.status_code == 200 do
      {resp.status_code, Jason.decode!(resp.body)}
    else
      {resp.status_code, nil}
    end
  end

  defp shutdown_bird(port) do
    shutdown_url = url(port, @path_shutdown)
    resp = HTTPoison.post!(shutdown_url, "{}")
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

    {200, bird_status} = get_bird_status(port)
    assert Map.get(bird_status, "type") == "goose"
    assert Map.get(bird_status, "status") == "online"
  end

  test "ducks that join after there is a goose remain ducks" do
    # Start bird nodes
    {goose_port, goose_pids} = start_bird()
    {duck_1_port, duck_1_pids} = start_bird()
    {duck_2_port, duck_2_pids} = start_bird()

    # Get bird statuses
    {200, goose_status} = get_bird_status(goose_port)
    {200, duck_1_status} = get_bird_status(duck_1_port)
    {200, duck_2_status} = get_bird_status(duck_2_port)

    # Assert type and status of bird nodes
    assert Map.get(goose_status, "type") == "goose"
    assert Map.get(duck_1_status, "type") == "duck"
    assert Map.get(duck_2_status, "type") == "duck"

    assert Map.get(goose_status, "status") == "online"
    assert Map.get(duck_1_status, "status") == "online"
    assert Map.get(duck_2_status, "status") == "online"
  end

  test "all birds have a list of the ducks and the goose" do
    # Not required, so I'll probably cut
  end

  describe "when the goose goes offline" do
    test "the goose is unavailable" do
      # Start bird nodes
      {goose_port, goose_pids} = start_bird()
      {duck_1_port, duck_1_pids} = start_bird()
      {duck_2_port, duck_2_pids} = start_bird()

      # Get bird statuses
      {200, goose_status} = get_bird_status(goose_port)
      {200, duck_1_status} = get_bird_status(duck_1_port)
      {200, duck_2_status} = get_bird_status(duck_2_port)

      # Assert type of bird nodes
      assert Map.get(goose_status, "type") == "goose"
      assert Map.get(duck_1_status, "type") == "duck"
      assert Map.get(duck_2_status, "type") == "duck"

      # Shutdown goose
      shutdown_bird(goose_port)

      # Ensure goose is offline
      {resp_code, _goose_status} = get_bird_status(goose_port)
      assert resp_code == 404
    end

    test "another duck becomes the goose" do
      # Start bird nodes
      {goose_port, goose_pids} = start_bird()
      {duck_1_port, duck_1_pids} = start_bird()
      {duck_2_port, duck_2_pids} = start_bird()

      # Get bird statuses
      {200, goose_status} = get_bird_status(goose_port)
      {200, duck_1_status} = get_bird_status(duck_1_port)
      {200, duck_2_status} = get_bird_status(duck_2_port)

      # Assert type of bird nodes
      assert Map.get(goose_status, "type") == "goose"
      assert Map.get(duck_1_status, "type") == "duck"
      assert Map.get(duck_2_status, "type") == "duck"

      # Shutdown goose
      shutdown_bird(goose_port)

      # Ensure a new goose is selected
      {200, duck_1_status} = get_bird_status(duck_1_port)
      {200, duck_2_status} = get_bird_status(duck_2_port)

      assert Map.get(duck_1_status, "type") == "goose" or
               Map.get(duck_2_status, "type") == "goose"
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
