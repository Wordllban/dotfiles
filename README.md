# Dotfiles

This repository collects the custom configurations I use for coding and
everyday tools so they can be shared, versioned, and reproduced across
machines.

## Included configuration

- Cursor editor settings and keybindings
- Claude settings and status line
- herdr key bindings and UI preferences
- WezTerm appearance and key bindings

Files under `home/` are organized by application. The manifest maps them to
the appropriate home-directory destinations on macOS and Linux.

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

Claude's status line requires `jq`. The other applications must be installed
separately.

## Updating the repository

After changing local application settings, preview and collect the allowlisted
files:

```sh
./scripts/update.sh --dry-run
./scripts/update.sh
```

`scripts/config-manifest.sh` is the single allowlist used in both directions.
The update script refuses files that match common credential patterns and
copies through a temporary file before replacing repository content.

## Deliberate exclusions

Only portable, user-controlled configuration is included. In particular:

- `.cursor/mcp.json` is excluded because the local file contains a credential.
- Cursor and Claude histories, sessions, plans, project state, telemetry,
  databases, OAuth state, extension/plugin caches, and generated IDE state are
  excluded.
- `.cursor/argv.json` is excluded because it contains generated crash-reporting
  state and a machine identifier.
- Claude's externally managed `find-skills` symlink is excluded because its
  target lives outside `~/.claude`.
- herdr logs, Unix sockets, `session.json`, and `release-notes.json` are
  excluded.
- WezTerm's generated `check_update` state is excluded.

Do not add credentials directly to this repository. Configure secrets locally
after setup.

## License

This project is available under the [MIT License](LICENSE).
