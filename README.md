# vibe-env-init

Scaffold any project to run [opencode](https://opencode.ai) CLI inside a devcontainer, entirely from the terminal.

One command sets up `.devcontainer/`, `.opencode/`, and `mise.toml`.

## Quick Start

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Miskamyasa/vibe-env-init/main/init.sh) my-project
```

The script will:
1. Ask you to choose between **shared** and **sqlite** session modes
2. Create all configuration files with your project name
3. Skip any files that already exist (showing a diff so you can merge manually)

If no project name is given, the current directory name is used. The script normalizes it to a container-safe value (lowercase, `a-z0-9_.-`, separators collapsed to `-`).

If you need to test from a fork, override the template source:

```bash
VIBE_ENV_INIT_REPO="owner/repo" VIBE_ENV_INIT_BRANCH="branch" bash <(curl -fsSL https://raw.githubusercontent.com/Miskamyasa/vibe-env-init/main/init.sh) my-project
```

## Running opencode in a container

After scaffolding, use the [devcontainer CLI](https://github.com/devcontainers/cli) (installed via `mise`) to build and enter the container:

```bash
devcontainer up --workspace-folder .
devcontainer exec --workspace-folder . opencode
```

### Wrapper script

To avoid typing the full commands every time, save this script as `~/.local/bin/oc` (or any name you prefer):

```bash
#!/usr/bin/env bash
set -e

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# ensure container exists and is running
devcontainer up --workspace-folder "$ROOT" >/dev/null

exec devcontainer exec --workspace-folder "$ROOT" opencode
```

Then make it executable:

```bash
chmod +x ~/.local/bin/oc
```

Make sure `~/.local/bin` is in your `PATH` (add `export PATH="$HOME/.local/bin:$PATH"` to your shell profile if needed).

Now you can run `oc` from any scaffolded project directory to start opencode inside its container.

## Session Modes

### Shared

- Uses opencode **v1.1.63** (pre-SQLite)
- Shares opencode sessions between containers via a common `~/.local/share/opencode` mount
- Good when you want to continue conversations across different project containers

### SQLite

- Uses **latest** opencode
- Each project gets its own isolated opencode data directory at `~/.cache/containers/opencode-data/<project>`
- Auth credentials are mounted read-only from the host
- Good when you want full isolation between projects

## What Gets Created

```
your-project/
  .devcontainer/
    devcontainer.json     # Container config (shared or sqlite variant)
  .opencode/
    opencode.json         # opencode CLI configuration
    agents/
      investigate.md      # Read-only investigation agent
      review.md           # Code review agent
    commands/
      execute.md          # Implementation execution command
      plan.md             # Planning command
      review.md           # Review orchestration command
  mise.toml               # Tool versions (node, npm, devcontainer cli, opencode, gh)
```

## Conflict Handling

If a file already exists, the script will:
- Skip the file (never overwrites)
- Show a unified diff between your file and the template
- Print the template URL so you can review and merge changes manually

## Prerequisites

- macOS or Linux
- `curl` or `wget`
- Docker (or a compatible container runtime)
- [mise](https://mise.jdx.dev/) for tool management (installs `devcontainer` CLI, `opencode`, etc.)

## License

[MIT](LICENSE)
