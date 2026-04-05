# Feature: Just Scripts

## Summary

Narrow the scope of `elr` to support only Elixir scripts, dropping all escript
support. Update script validation, reference parsing, and add a `--find` option
for discovering scripts in remote repos. Introduce a YAML-based cache datastore
for tracking script usage statistics. Redesign CLI argument handling to cleanly
separate `elr` options from script arguments.

## Motivation

The first iteration of `elr` supported both Elixir scripts and escripts.
Escripts already have mature tooling via `mix escript.build` and `mix
escript.install`, so supporting them in `elr` adds complexity without unique
value. By focusing exclusively on Elixir scripts (`.exs` files and executable
shebanged files that use `Mix.install`), the tool becomes easier to understand,
test, and maintain.

## User Stories

- As a developer, I want `elr` to only handle Elixir scripts so the tool has a clear, focused purpose.
- As a developer, I want to reference a script within a GitHub repo using glob patterns so I don't need to know the exact path.
- As a developer, I want a `--find` option to discover all scripts in a remote repo so I can see what's available before running anything.
- As a developer, I want `elr` to track script usage stats (install date, last run, run count) so I can see how I'm using my cached scripts.
- As a developer, I want to pass `--help` to my script without `elr` intercepting it, so script arguments stay separate from `elr` arguments.

## Functional Requirements

### Script Validation

- A valid script is one of:
  - A file ending in `.exs` that contains a call to `Mix.install`
  - An executable file with no extension that contains an Elixir shebang line and a call to `Mix.install`
- Invalid scripts (to be rejected with a clear error):
  - Files ending in `.md`, `.ex`, or other non-script extensions
  - Files ending in `.exs` that do not contain a call to `Mix.install`
  - Files with no extension that are not executable

### Drop Escript Support

- Remove all escript-related code paths, including escript detection, building, and execution.
- Remove all escript-related tests.
- Remove all escript references from documentation and help text.
- Remove Hex package references from supported reference types.

### Script Reference Updates

- Supported reference sources: URLs, GitHub repos, and local filesystem paths.
- Hex package references are no longer supported.
- References always point to a specific script file.
- Support glob-style pattern matching within repo references:
  - `github:andyl/tango:**/myscript` — recursive search for `myscript`
  - `github:andyl/tango:**/myscript.exs` — recursive search for `myscript.exs`
  - `github:andyl/tango:lib/**/myscript` — recursive search only under the `lib` directory

### Find Option

- Add a `--find` option that lists all valid scripts within a remote repo reference.
- Output should show each discovered script's path within the repo.

### Cache Datastore

- Store a YAML data file in the `elr` cache directory with one record per cached script.
- The YAML file should be a hidden file in the cache directory (eg `.script_directory.yml`)
- Each record contains:
  - Script name
  - Script source (reference string)
  - Script description (the first comment block from the first # until the first blank line)
  - Script dependencies (list of deps from `Mix.install`)
  - Install date
  - Last execution timestamp
  - Number of uses (run count)
- Update the datastore on each script install and execution.

### CLI Argument Separation

- Redesign the CLI interface to use `--` as a separator between `elr` options and script arguments.
- New usage format: `elr [elr_args] -- <script_reference> [script_args]`
- This prevents `elr` from intercepting flags like `--help` that are intended for the script.

## Non-Functional Requirements

- All existing tests related to escripts must be removed or rewritten to cover scripts only.
- Script validation must produce clear, actionable error messages for invalid files.
- The YAML datastore must be human-readable and editable.

## Acceptance Criteria

- [ ] Escript-related code, tests, and documentation are fully removed.
- [ ] Hex package references are no longer accepted; a helpful error is shown if attempted.
- [ ] `.exs` files with `Mix.install` are recognized as valid scripts.
- [ ] Executable no-extension files with an Elixir shebang and `Mix.install` are recognized as valid scripts.
- [ ] Invalid file types are rejected with clear error messages.
- [ ] Glob pattern matching resolves scripts within GitHub repo references.
- [ ] `--find` lists all valid scripts in a given remote repo.
- [ ] The YAML datastore is created and updated on script install and execution.
- [ ] `elr [elr_args] -- <script_ref> [script_args]` correctly separates argument contexts.
- [ ] Script-targeted flags like `--help` are forwarded to the script, not consumed by `elr`.

## Out of Scope

- Escript support of any kind.
- Hex package references.
- Authentication for private repositories.
- Windows-specific path handling.

## Dependencies

- A YAML library for Elixir (e.g. `yaml_elixir`) for reading/writing the cache datastore.
- `Mix.install/2` — core dependency resolution mechanism (stdlib).
