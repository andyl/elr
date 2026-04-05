# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**elr** (Elixir Load & Run) is a CLI tool — the Elixir equivalent of `npx`. It loads and runs Elixir scripts (`.exs`), escripts, and tools from Hex packages, git repos, or URLs with automatic dependency fetching via `Mix.install/2`. Distributed as an escript.

## Build & Development Commands

```bash
mix deps.get          # Fetch dependencies
mix compile           # Compile the project
mix test              # Run all tests
mix test test/elr_test.exs  # Run a single test file
mix test --only tag_name    # Run tests matching a tag
mix format            # Format code
mix format --check-formatted  # Check formatting without changing files
```

## Architecture

Pipeline: **parse → resolve → cache check → load → detect entrypoint → execute**

- **lib/elr.ex** — Main module, version info
- **lib/elr/cli.ex** — Escript entrypoint, argument parsing, option handling
- **lib/elr/ref.ex** — Reference string parsing into `%Elr.Ref{}` struct
- **lib/elr/resolver.ex** — Converts parsed refs into `Mix.install` dep specs or download targets
- **lib/elr/cache.ex** — Filesystem cache management (dir, lookup, store, delete, list, clean, prune)
- **lib/elr/loader.ex** — Calls `Mix.install/2` or downloads scripts, uses cache
- **lib/elr/runner.ex** — Entrypoint detection (escript config or `main/1`) and execution
- **lib/elr/output.ex** — User-facing output with color/verbosity support
- **lib/elr/http.ex** — HTTP client wrapper using Erlang's `:httpc`
- **_spec/designs/** — Design specifications
- **_spec/plans/** — Implementation plans

## Key Design Decisions (from spec)

- References are resolved as: Hex packages, GitHub repos (`github:user/repo`), git URLs, direct `.exs` URLs, or local files
- Prefers building/running escripts when a package defines one; otherwise calls `MainModule.main(argv)`
- Caches in `~/.cache/elr` (or `$XDG_CACHE_HOME/elr`), keyed by reference + Elixir/OTP version
- Cache management via `elr --cache {dir,list,clean,prune}` flags on the main binary
