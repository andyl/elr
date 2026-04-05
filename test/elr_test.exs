defmodule ElrTest do
  use ExUnit.Case

  test "version/0 returns the project version" do
    assert Elr.version() == "0.1.0"
  end
end
