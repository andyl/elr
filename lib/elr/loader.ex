defmodule Elr.Loader do
  @moduledoc """
  Clones repos, downloads scripts, and builds escripts. Uses cache when available.
  """

  alias Elr.{Cache, Http, Output, Ref, Resolver}

  @spec load(Ref.t(), keyword()) ::
          {:ok, {:escript, String.t()} | {:script, String.t()}} | {:error, String.t()}
  def load(%Ref{} = ref, opts \\ []) do
    no_cache = Keyword.get(opts, :no_cache, false)

    case Resolver.resolve(ref) do
      {:clone, url, git_ref} ->
        clone_and_build(ref, url, git_ref, no_cache)

      {:script, url} ->
        download_script(ref, url, no_cache)

      {:local, path} ->
        if File.exists?(path) do
          {:ok, {:script, Path.expand(path)}}
        else
          {:error, "file not found: #{path}"}
        end
    end
  end

  defp clone_and_build(ref, url, git_ref, no_cache) do
    cache_key = Cache.cache_key(ref)

    unless no_cache do
      case find_cached_escript(cache_key) do
        {:ok, escript_path} ->
          Output.verbose("Using cached escript: #{escript_path}")
          {:ok, {:escript, escript_path}}

        :miss ->
          do_clone_and_build(ref, url, git_ref, cache_key)
      end
    else
      do_clone_and_build(ref, url, git_ref, cache_key)
    end
  end

  defp do_clone_and_build(ref, url, git_ref, cache_key) do
    Output.verbose("Cloning #{url}...")

    tmp_dir = Path.join(System.tmp_dir!(), "elr_build_#{:rand.uniform(1_000_000)}")

    try do
      clone_args =
        case git_ref do
          nil -> ["clone", "--depth", "1", url, tmp_dir]
          ref -> ["clone", "--depth", "1", "--branch", ref, url, tmp_dir]
        end

      case System.cmd("git", clone_args, stderr_to_stdout: true) do
        {_, 0} ->
          build_escript(ref, tmp_dir, cache_key)

        {output, _} ->
          {:error, "git clone failed: #{String.trim(output)}"}
      end
    after
      File.rm_rf(tmp_dir)
    end
  end

  defp build_escript(ref, project_dir, cache_key) do
    Output.verbose("Building escript for #{ref.name}...")

    with {_, 0} <- System.cmd("mix", ["deps.get"], cd: project_dir, stderr_to_stdout: true),
         {_, 0} <- System.cmd("mix", ["escript.build"], cd: project_dir, stderr_to_stdout: true) do
      case find_built_escript(project_dir) do
        {:ok, escript_path} ->
          {:ok, cached_path} = Cache.store(cache_key, %{"ref" => ref.name, "type" => "escript"})
          dest = Path.join(cached_path, Path.basename(escript_path))
          File.cp!(escript_path, dest)
          File.chmod!(dest, 0o755)
          {:ok, {:escript, dest}}

        :not_found ->
          {:error, "no escript produced for #{ref.name} — package may not define an escript"}
      end
    else
      {output, _} ->
        {:error, "build failed: #{String.trim(output)}"}
    end
  end

  defp find_built_escript(project_dir) do
    # Escripts are built in the project root; find the executable file
    project_dir
    |> File.ls!()
    |> Enum.find_value(:not_found, fn file ->
      path = Path.join(project_dir, file)

      if not File.dir?(path) and executable?(path) and not String.contains?(file, ".") do
        {:ok, path}
      end
    end)
  end

  defp executable?(path) do
    case File.stat(path) do
      {:ok, %{access: access}} when access in [:read_write, :read] ->
        case System.cmd("file", [path], stderr_to_stdout: true) do
          {output, 0} -> String.contains?(output, "script") or String.contains?(output, "ELF")
          _ -> false
        end

      _ ->
        false
    end
  end

  defp find_cached_escript(cache_key) do
    case Cache.lookup(cache_key) do
      {:ok, path, _metadata} ->
        path
        |> File.ls!()
        |> Enum.find_value(:miss, fn file ->
          full = Path.join(path, file)

          if file != "metadata.json" and not File.dir?(full) do
            {:ok, full}
          end
        end)

      :miss ->
        :miss
    end
  end

  defp download_script(ref, url, no_cache) do
    cache_key = Cache.cache_key(ref)

    unless no_cache do
      case Cache.lookup(cache_key) do
        {:ok, path, _metadata} ->
          script_path = Path.join(path, "script.exs")

          if File.exists?(script_path) do
            Output.verbose("Using cached script: #{script_path}")
            {:ok, {:script, script_path}}
          else
            do_download(url, cache_key)
          end

        :miss ->
          do_download(url, cache_key)
      end
    else
      do_download(url, cache_key)
    end
  end

  defp do_download(url, cache_key) do
    Output.verbose("Downloading #{url}...")

    case Http.get(url) do
      {:ok, body} ->
        {:ok, cache_path} = Cache.store(cache_key, %{"url" => url})
        script_path = Path.join(cache_path, "script.exs")
        File.write!(script_path, body)
        {:ok, {:script, script_path}}

      {:error, reason} ->
        {:error, "failed to download script: #{reason}"}
    end
  end
end
