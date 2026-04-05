defmodule Elr.RefTest do
  use ExUnit.Case, async: true

  alias Elr.Ref

  describe "local files" do
    test "relative path with ./" do
      assert {:ok, %Ref{type: :local, path: "./script.exs"}} = Ref.parse("./script.exs")
    end

    test "absolute path" do
      assert {:ok, %Ref{type: :local, path: "/tmp/script.exs"}} = Ref.parse("/tmp/script.exs")
    end

    test ".exs extension without path prefix" do
      assert {:ok, %Ref{type: :local, path: "script.exs"}} = Ref.parse("script.exs")
    end

    test ".escript extension" do
      assert {:ok, %Ref{type: :local, path: "./my_tool.escript"}} = Ref.parse("./my_tool.escript")
    end

    test "name is extracted from basename" do
      assert {:ok, %Ref{name: "script"}} = Ref.parse("./dir/script.exs")
    end
  end

  describe "remote scripts" do
    test "https URL ending in .exs" do
      url = "https://example.com/scripts/run.exs"
      assert {:ok, %Ref{type: :remote_script, url: ^url, name: "run"}} = Ref.parse(url)
    end
  end

  describe "non-.exs URLs" do
    test "https URL not ending in .exs returns error" do
      assert {:error, "non-.exs URLs are not supported:" <> _} =
               Ref.parse("https://example.com/page")
    end

    test "http URL returns error" do
      assert {:error, "non-.exs URLs are not supported:" <> _} =
               Ref.parse("http://example.com/page")
    end
  end

  describe "GitHub references" do
    test "basic github:user/repo" do
      assert {:ok, %Ref{type: :github, name: "my_lib", url: "user/my_lib"}} =
               Ref.parse("github:user/my_lib")
    end

    test "github:user/repo#ref" do
      assert {:ok, %Ref{type: :github, name: "repo", url: "user/repo", git_ref: "v1.0"}} =
               Ref.parse("github:user/repo#v1.0")
    end

    test "invalid github reference (no slash)" do
      assert {:error, "invalid GitHub reference:" <> _} = Ref.parse("github:noslash")
    end

    test "invalid github reference (empty repo)" do
      assert {:error, "invalid GitHub reference:" <> _} = Ref.parse("github:user/")
    end
  end

  describe "git URLs" do
    test "git+ URL" do
      assert {:ok, %Ref{type: :git, name: "my_dep", url: "https://example.com/my_dep.git"}} =
               Ref.parse("git+https://example.com/my_dep.git")
    end

    test "git+ URL with ref" do
      assert {:ok,
              %Ref{
                type: :git,
                name: "my_dep",
                url: "https://example.com/my_dep.git",
                git_ref: "main"
              }} = Ref.parse("git+https://example.com/my_dep.git#main")
    end

    test "strips .git suffix from name" do
      assert {:ok, %Ref{name: "repo"}} = Ref.parse("git+https://host.com/repo.git")
    end
  end

  describe "Hex packages" do
    test "bare package name" do
      assert {:ok, %Ref{type: :hex, name: "jason", version: nil}} = Ref.parse("jason")
    end

    test "package with version" do
      assert {:ok, %Ref{type: :hex, name: "jason", version: "~> 1.4"}} =
               Ref.parse("jason@~> 1.4")
    end

    test "invalid package name" do
      assert {:error, "invalid Hex package name:" <> _} = Ref.parse("Invalid-Name")
    end

    test "empty string" do
      assert {:error, "invalid Hex package name:" <> _} = Ref.parse("")
    end
  end
end
