defmodule Elr.Runner do
  @moduledoc """
  Executes escripts and scripts as subprocesses.
  """

  alias Elr.Output

  @spec run({:escript, String.t()} | {:script, String.t()}, Elr.Ref.t(), [String.t()]) ::
          :ok | {:error, String.t()}

  def run({:escript, path}, _ref, argv) do
    Output.verbose("Running escript: #{path}")
    run_command(path, argv)
  end

  def run({:script, path}, _ref, argv) do
    Output.verbose("Running script: #{path}")
    run_command("elixir", [path | argv])
  end

  defp run_command(cmd, args) when is_list(args) do
    port =
      Port.open({:spawn_executable, System.find_executable(cmd)}, [
        :binary,
        :exit_status,
        :stderr_to_stdout,
        args: args
      ])

    stream_port(port)
  end

  defp run_command(cmd, argv) do
    port =
      Port.open({:spawn_executable, cmd}, [
        :binary,
        :exit_status,
        :stderr_to_stdout,
        args: argv
      ])

    stream_port(port)
  end

  defp stream_port(port) do
    receive do
      {^port, {:data, data}} ->
        IO.write(data)
        stream_port(port)

      {^port, {:exit_status, 0}} ->
        :ok

      {^port, {:exit_status, code}} ->
        {:error, "process exited with status #{code}"}
    end
  end
end
