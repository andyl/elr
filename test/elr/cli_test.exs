defmodule Elr.CLITest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  describe "--help" do
    test "prints help text" do
      output = capture_io(fn -> Elr.CLI.main(["--help"]) end)
      assert output =~ "elr — Elixir Load & Run"
      assert output =~ "Usage:"
      assert output =~ "--verbose"
    end
  end

  describe "--version" do
    test "prints version" do
      output = capture_io(fn -> Elr.CLI.main(["--version"]) end)
      assert output =~ "elr 0.1.0"
    end
  end

  describe "--cache dir" do
    test "prints cache directory path" do
      output = capture_io(fn -> Elr.CLI.main(["--cache", "dir"]) end)
      assert String.trim(output) != ""
    end
  end

  describe "local .exs script" do
    test "runs a local script" do
      tmp = Path.join(System.tmp_dir!(), "elr_test_script_#{:rand.uniform(100_000)}.exs")
      File.write!(tmp, ~s[IO.puts("hello from elr")])

      output = capture_io(fn -> Elr.CLI.main([tmp]) end)
      assert output =~ "hello from elr"

      File.rm!(tmp)
    end
  end

  describe "error handling" do
    test "invalid reference produces error" do
      output =
        capture_io(:stderr, fn ->
          try do
            Elr.CLI.main(["Invalid-Package!"])
          catch
            :exit, _ -> :ok
          end
        end)

      assert output =~ "error:"
    end
  end
end
