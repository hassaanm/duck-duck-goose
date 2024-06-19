defmodule BirdsTest do
  use ExUnit.Case
  doctest Birds.Bird

  #############
  # Constants #
  #############

  # Aliases
  alias Birds.DB.TestDB, as: TestDB

  # Bird behavior
  @take_leadership_frequency_ms Application.compile_env(:birds, :take_leadership_frequency_ms)

  # Network
  @host "localhost"
  @port_counter :port_counter

  # Types
  @type path :: :status | :shutdown | :fix_network | :terminate_network
  @path_status :status
  @path_shutdown :shutdown
  @path_fix_network :fix_network
  @path_terminate_network :terminate_network

  ###########
  # Helpers #
  ###########

  @spec start_port_counter() :: none()
  defp start_port_counter(), do: Agent.start_link(fn -> 5000 end, name: @port_counter)

  @spec get_next_port() :: integer()
  defp get_next_port(), do: Agent.get_and_update(@port_counter, fn port -> {port, port + 1} end)

  @spec start_bird() :: integer()
  defp start_bird() do
    port = get_next_port()
    Bandit.start_link(%{plug: Birds.Router, scheme: :http, port: port})
    Birds.Bird.start_link(db: TestDB, port: port)
    port
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

  @spec shutdown_bird(port :: integer()) :: any()
  defp shutdown_bird(port) do
    shutdown_url = url(port, @path_shutdown)
    HTTPoison.post!(shutdown_url, "{}")
  end

  @spec terminate_network_bird(port :: integer()) :: any()
  defp terminate_network_bird(port) do
    terminate_network_url = url(port, @path_terminate_network)
    HTTPoison.post!(terminate_network_url, "{}")
  end

  @spec fix_network_bird(port :: integer()) :: any()
  defp fix_network_bird(port) do
    fix_network_url = url(port, @path_fix_network)
    HTTPoison.post!(fix_network_url, "{}")
  end

  @spec advance_db_time_and_sleep(db_advance_time :: integer(), sleep_time :: integer()) :: :ok
  defp advance_db_time_and_sleep(db_advance_time, sleep_time \\ @take_leadership_frequency_ms * 2) do
    TestDB.advance_time(db_advance_time)

    # TODO: Avoid relying on sleep and instead pass in mocked time like TestDB
    # It's currently ok since @take_leadership_frequency_ms is very short for tests
    :timer.sleep(sleep_time)

    :ok
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
    port = start_bird()

    {200, bird_status} = get_bird_status(port)
    assert Map.get(bird_status, "type") == "goose"
    assert Map.get(bird_status, "status") == "online"
  end

  test "ducks that join after there is a goose remain ducks" do
    # Start bird nodes
    goose_port = start_bird()
    duck_1_port = start_bird()
    duck_2_port = start_bird()

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

  describe "when the goose goes offline" do
    test "the goose is unavailable" do
      # Start bird nodes
      goose_port = start_bird()
      duck_1_port = start_bird()
      duck_2_port = start_bird()

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
      goose_port = start_bird()
      duck_1_port = start_bird()
      duck_2_port = start_bird()

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

      # Advance time to expire leadership ttl and wait a bit to ensure ducks attempt to take leadership
      advance_db_time_and_sleep(20)

      # Ensure one of the previous ducks is now the goose
      {200, duck_1_status} = get_bird_status(duck_1_port)
      {200, duck_2_status} = get_bird_status(duck_2_port)

      assert Map.get(duck_1_status, "type") == "goose" or
               Map.get(duck_2_status, "type") == "goose"
    end
  end

  describe "when the goose gets a network partition" do
    test "the goose becomes a duck" do
      # Start bird nodes
      goose_port = start_bird()
      duck_1_port = start_bird()
      duck_2_port = start_bird()

      # Get bird statuses
      {200, goose_status} = get_bird_status(goose_port)
      {200, duck_1_status} = get_bird_status(duck_1_port)
      {200, duck_2_status} = get_bird_status(duck_2_port)

      # Assert type of bird nodes
      assert Map.get(goose_status, "type") == "goose"
      assert Map.get(duck_1_status, "type") == "duck"
      assert Map.get(duck_2_status, "type") == "duck"

      # Terminate network for goose
      terminate_network_bird(goose_port)

      # Ensure goose is offline
      {resp_code, _goose_status} = get_bird_status(goose_port)
      assert resp_code == 404
    end

    test "another duck becomes the goose" do
      # Start bird nodes
      goose_port = start_bird()
      duck_1_port = start_bird()
      duck_2_port = start_bird()

      # Get bird statuses
      {200, goose_status} = get_bird_status(goose_port)
      {200, duck_1_status} = get_bird_status(duck_1_port)
      {200, duck_2_status} = get_bird_status(duck_2_port)

      # Assert type of bird nodes
      assert Map.get(goose_status, "type") == "goose"
      assert Map.get(duck_1_status, "type") == "duck"
      assert Map.get(duck_2_status, "type") == "duck"

      # Terminate network for goose
      terminate_network_bird(goose_port)

      # Advance time to expire leadership ttl and wait a bit to ensure ducks attempt to take leadership
      advance_db_time_and_sleep(20)

      # Ensure one of the previous ducks is now the goose
      {200, duck_1_status} = get_bird_status(duck_1_port)
      {200, duck_2_status} = get_bird_status(duck_2_port)

      assert Map.get(duck_1_status, "type") == "goose" or
               Map.get(duck_2_status, "type") == "goose"
    end

    test "the goose becomes and remains a duck even after network is fixed" do
      # Start bird nodes
      goose_port = start_bird()
      duck_1_port = start_bird()
      duck_2_port = start_bird()

      # Get bird statuses
      {200, goose_status} = get_bird_status(goose_port)
      {200, duck_1_status} = get_bird_status(duck_1_port)
      {200, duck_2_status} = get_bird_status(duck_2_port)

      # Assert type of bird nodes
      assert Map.get(goose_status, "type") == "goose"
      assert Map.get(duck_1_status, "type") == "duck"
      assert Map.get(duck_2_status, "type") == "duck"

      # Terminate network for goose
      terminate_network_bird(goose_port)

      # Advance time to expire leadership ttl and wait a bit to ensure ducks attempt to take leadership
      advance_db_time_and_sleep(20)

      # Fix network for old goose
      fix_network_bird(goose_port)

      # Ensure previous goose is now a duck
      {200, goose_status} = get_bird_status(goose_port)
      assert Map.get(goose_status, "type") == "duck"
    end
  end
end
