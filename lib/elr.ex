defmodule Elr do
  @moduledoc """
  Elixir Load & Run — the Elixir equivalent of `npx`.

  Loads and runs Elixir scripts, escripts, and tools from Hex packages,
  git repos, or URLs with automatic dependency fetching via `Mix.install/2`.
  """

  @version Mix.Project.config()[:version]

  def version, do: @version
end
