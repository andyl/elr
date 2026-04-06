defmodule EslrTest do
  use ExUnit.Case

  test "version/0 returns the project version" do
    assert Eslr.version() == Eslr.MixProject.project()[:version]
  end
end
