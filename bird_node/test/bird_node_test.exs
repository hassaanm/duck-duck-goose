defmodule BirdNodeTest do
  use ExUnit.Case
  doctest BirdNode

  test "greets the world" do
    assert BirdNode.hello() == :world
  end
end
