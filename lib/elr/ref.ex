defmodule Elr.Ref do
  @moduledoc """
  Parses reference strings into structured types.
  """

  defstruct [:type, :name, :version, :url, :path, :git_ref]

  @type t :: %__MODULE__{
          type: :hex | :github | :git | :remote_script | :local,
          name: String.t() | nil,
          version: String.t() | nil,
          url: String.t() | nil,
          path: String.t() | nil,
          git_ref: String.t() | nil
        }

  @doc """
  Parses a reference string into `{:ok, %Elr.Ref{}}` or `{:error, reason}`.

  Parse order:
  1. Starts with `./` or `/` or ends with `.exs`/`.escript` → local file
  2. Starts with `https://` and ends with `.exs` → remote script
  3. Starts with `https://` or `http://` → error
  4. Starts with `github:` → GitHub shorthand
  5. Starts with `git+` → git URL
  6. Everything else → Hex package
  """
  @spec parse(String.t()) :: {:ok, t()} | {:error, String.t()}
  def parse(ref) when is_binary(ref) do
    cond do
      String.starts_with?(ref, "https://") and String.ends_with?(ref, ".exs") ->
        {:ok, %__MODULE__{type: :remote_script, url: ref, name: url_basename(ref)}}

      String.starts_with?(ref, "https://") or String.starts_with?(ref, "http://") ->
        {:error, "non-.exs URLs are not supported: #{ref}"}

      local_file?(ref) ->
        {:ok, %__MODULE__{type: :local, path: ref, name: Path.basename(ref, Path.extname(ref))}}

      String.starts_with?(ref, "github:") ->
        parse_github(ref)

      String.starts_with?(ref, "git+") ->
        parse_git(ref)

      true ->
        parse_hex(ref)
    end
  end

  def parse(_), do: {:error, "reference must be a string"}

  defp local_file?(ref) do
    String.starts_with?(ref, "./") or
      String.starts_with?(ref, "/") or
      String.ends_with?(ref, ".exs") or
      String.ends_with?(ref, ".escript")
  end

  defp url_basename(url) do
    url |> URI.parse() |> Map.get(:path) |> Path.basename(".exs")
  end

  defp parse_github("github:" <> rest) do
    case String.split(rest, "#", parts: 2) do
      [repo] -> build_github(repo, nil)
      [repo, git_ref] -> build_github(repo, git_ref)
    end
  end

  defp build_github(repo, git_ref) do
    case String.split(repo, "/", parts: 2) do
      [_user, name] when name != "" ->
        {:ok,
         %__MODULE__{
           type: :github,
           name: name,
           url: repo,
           git_ref: git_ref
         }}

      _ ->
        {:error, "invalid GitHub reference: github:#{repo}. Expected format: github:user/repo"}
    end
  end

  defp parse_git("git+" <> rest) do
    case String.split(rest, "#", parts: 2) do
      [url] -> build_git(url, nil)
      [url, git_ref] -> build_git(url, git_ref)
    end
  end

  defp build_git(url, git_ref) do
    name =
      url
      |> String.split("/")
      |> List.last()
      |> String.replace_suffix(".git", "")

    {:ok,
     %__MODULE__{
       type: :git,
       name: name,
       url: url,
       git_ref: git_ref
     }}
  end

  defp parse_hex(ref) do
    case String.split(ref, "@", parts: 2) do
      [name] ->
        if valid_hex_name?(name) do
          {:ok, %__MODULE__{type: :hex, name: name}}
        else
          {:error, "invalid Hex package name: #{name}"}
        end

      [name, version] ->
        if valid_hex_name?(name) do
          {:ok, %__MODULE__{type: :hex, name: name, version: version}}
        else
          {:error, "invalid Hex package name: #{name}"}
        end
    end
  end

  defp valid_hex_name?(name) do
    name != "" and Regex.match?(~r/^[a-z][a-z0-9_]*$/, name)
  end
end
