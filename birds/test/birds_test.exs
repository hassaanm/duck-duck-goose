defmodule BirdsTest do
  use ExUnit.Case
  doctest Birds

  test "greets the world" do
    assert Birds.hello() == :world
  end
end
