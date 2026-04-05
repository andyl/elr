defmodule ElrTest do
  use ExUnit.Case
  doctest Elr

  test "greets the world" do
    assert Elr.hello() == :world
  end
end
