# Dotfiles

This repository collects the custom configurations I use for coding and
everyday tools so they can be shared, versioned, and reproduced across
machines.

## Included configuration

- Cursor editor settings, keybindings, extensions list, agent permissions, and hooks
- Global agent skills list (`home/.agents/skills.txt`) installed via [skills.sh](https://skills.sh/)
- Shared destructive-command guard hook (`home/.agents/hooks/guard-destructive.sh`)
- Global `AGENTS.md` instructions shared with Claude via `CLAUDE.md` import
- Claude settings (default Bash allow for `gh` / `acli`, ask rules for destructive commands, PreToolUse guard) and status line (official `code-review` plugin disabled in favor of Matt Pocock's skill)
- herdr key bindings and UI preferences
- WezTerm appearance and key bindings

Files under `home/` are organized by application. The manifest maps them to
the appropriate home-directory destinations on macOS and Linux.

### Agent command permissions

Claude Code and Cursor use different permission models, so this repo configures
both deliberately:

| Tool | Default allow | Destructive guard |
|------|---------------|-------------------|
| Claude Code | `permissions.allow` for `Bash(gh *)` and `Bash(acli *)` | `permissions.ask` for destructive patterns (ask beats allow), plus a PreToolUse hook |
| Cursor | `autoRun.allow_instructions` for routine `gh` / `acli` (Auto-review mode) | `autoRun.block_instructions` plus a fail-closed `beforeShellExecution` hook |

Cursor's recommended run mode is Auto-review. This repo intentionally does
**not** set `terminalAllowlist` in `permissions.json`, because that key
replaces the in-app terminal allowlist and can prevent selecting Auto-review.

The shared hook script asks before destructive `rm`/`git`/`gh`/`acli`
patterns. It is installed to both `~/.agents/hooks/` and `~/.cursor/hooks/`.

The application requested as "herdr" is installed on this machine with that
exact lowercase name and stores its configuration in `~/.config/herdr`.

## Setup

Run from the repository root:

```sh
./scripts/setup.sh --dry-run
./scripts/setup.sh
```

Setup uses symlinks by default. Use `--copy` to install independent copies:

```sh
./scripts/setup.sh --copy
```

Existing destination files are never discarded. Before replacement they are
moved under `~/.dotfiles-backups/<timestamp>-<pid>/`. Re-running setup is safe:
already-current copies and links are skipped.

Claude's status line requires `jq`. Cursor extensions are installed from
`home/.cursor/extensions.txt` when the `cursor` CLI is on `PATH`. Agent skills
from `home/.agents/skills.txt` are optional - pass `--skills` to install or
refresh them via `npx skills` (needs Node.js, `jq`, and `python3`).

Each skills line is `<owner/repo> <skill> <mode>` using Claude Code's
[`skillOverrides`](https://code.claude.com/docs/en/skills) values:

| Mode | Claude Code | Cursor |
|------|-------------|--------|
| `on` | name + description; model may invoke | same via frontmatter |
| `name-only` | name listed only | treated like `on` (no Cursor equivalent) |
| `user-invocable-only` | slash-only (`/skill`) | `disable-model-invocation: true` |
| `off` | hidden | not installed for Cursor |

`--skills` runs `npx skills update`, installs missing skills, writes Claude
`skillOverrides` into `home/.claude/settings.json`, and re-applies Cursor
frontmatter so Matt Pocock (and other) skill updates stay compatible.

```sh
./scripts/setup.sh --skills
./scripts/setup.sh --dry-run --skills
```

The other applications must be installed separately.
Script output is colorized in a terminal. Set `NO_COLOR=1` for plain logs.
Set `VERBOSE=1` to print low-level shell commands during dry runs.

Shared helpers live under `scripts/lib/` and are sourced by the entry scripts;
they are not meant to be run directly.

## Updating the repository

After changing local application settings, preview and collect the allowlisted
files:

```sh
./scripts/update.sh --dry-run
./scripts/update.sh
```

`scripts/lib/manifest.sh` is the single allowlist used in both directions.
The update script refuses files that match common credential patterns and
copies through a temporary file before replacing repository content.

## Deliberate exclusions

Only portable, user-controlled configuration is included. In particular:

- `.cursor/mcp.json` is excluded because the local file contains a credential.
- `.cursor/permissions.json` steers Auto-review via `autoRun` (allow routine
  `gh` / `acli`, block destructive patterns). It does not set
  `terminalAllowlist`.
- `.cursor/hooks.json` and the shared guard script enforce approval for
  destructive shell commands.
- Cursor and Claude histories, sessions, plans, project state, telemetry,
  databases, OAuth state, extension/plugin caches, and generated IDE state are
  excluded.
- `.cursor/argv.json` is excluded because it contains generated crash-reporting
  state and a machine identifier.
- Claude's externally managed skill symlinks under `~/.claude/skills/` are
  excluded; install them via `home/.agents/skills.txt` and `scripts/setup.sh`.
- herdr logs, Unix sockets, `session.json`, and `release-notes.json` are
  excluded.
- WezTerm's generated `check_update` state is excluded.

Do not add credentials directly to this repository. Configure secrets locally
after setup.

## License

This project is available under the [MIT License](LICENSE).
