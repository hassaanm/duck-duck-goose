defmodule Birds.BirdTest do
  use ExUnit.Case
  doctest Birds.Bird

  alias Birds.DB.TestDB, as: TestDB

  setup_all do
    # Start test db at the start of the test suite
    now = :os.system_time(:seconds)
    TestDB.start(now)

    :ok
  end

  setup do
    # Reset test db before each test
    TestDB.reset()
    :ok
  end

  test "first duck to join becomes the goose" do
    port = 1234
    Birds.Bird.start_link(db: TestDB, port: port)
    goose_status = Birds.Bird.get_state(port)
    assert Map.get(goose_status, :type) == :goose
  end

  test "ducks that join after there is a goose remain ducks" do
    goose_port = 1234
    duck_1_port = 1235
    duck_2_port = 1236

    Birds.Bird.start_link(db: TestDB, port: goose_port)
    Birds.Bird.start_link(db: TestDB, port: duck_1_port)
    Birds.Bird.start_link(db: TestDB, port: duck_2_port)

    goose_status = Birds.Bird.get_state(goose_port)
    duck_1_status = Birds.Bird.get_state(duck_1_port)
    duck_2_status = Birds.Bird.get_state(duck_2_port)

    assert Map.get(goose_status, :type) == :goose
    assert Map.get(duck_1_status, :type) == :duck
    assert Map.get(duck_2_status, :type) == :duck
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
