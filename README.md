# micromux

A tiny terminal IDE: **micro** as the editor, **tmux** for a split layout, and **flake8** linting on save — all in one launcher.

```
┌─────────────────────────────┐
│  micro  (edit your code)    │
│  • saves with Ctrl+S        │
│  • flake8 lints on save     │
├─────────────────────────────┤
│  shell  (run your code)     │
│  • python3 myfile.py        │
└─────────────────────────────┘
```

## Why

Thonny and other GUI IDEs are heavy for a VM. This setup is light, runs entirely in the terminal, shows lint errors on save, and keeps a shell one keystroke away.

Great for:
- Beginners learning Python
- Remote dev over SSH
- Anyone on a low-RAM VirtualBox VM

## What you get

- **micro** with Python linting via **flake8** — errors appear at the bottom of the editor on save
- **tmux** with Alt+arrow pane switching and pane-number borders
- **`micromux`** — one command to open the whole layout

## Install

### One-shot

```bash
git clone https://github.com/AlexPhoenix42/micromux.git
cd micromux
./install.sh
```

Restart your shell (or `source ~/.bashrc`).

### Install flags

The installer prompts before overwriting any existing config and saves a
timestamped backup first. If you already have a tmux or micro config you
care about, these flags let you control what happens.

| Flag | What it does |
|---|---|
| *(none)* | Prompt before overwriting each existing config; back up first |
| `--keep-existing` | Never touch existing configs; install binaries + launcher only |
| `--force` | Overwrite without prompting (still backs up) |
| `--dry-run` | Print what would happen; change nothing |
| `-h`, `--help` | Show usage |

Examples:

```bash
./install.sh --keep-existing   # add micromux without touching my dotfiles
./install.sh --dry-run         # preview before committing
./install.sh --force           # CI / scripted install
```

### Installing via pipe

If you prefer `curl | bash`, you **must** pass a flag, because the installer
can't prompt for existing configs when stdin is a pipe:

```bash
curl -fsSL https://raw.githubusercontent.com/AlexPhoenix42/micromux/main/install.sh \
  | bash -s -- --keep-existing
```

Without a flag, the installer will refuse to run and explain the alternatives.

### Already have a tmux config?

tmux reads configs in this order:

1. `/etc/tmux.conf`
2. `~/.tmux.conf`
3. `~/.config/tmux/tmux.conf`

The first one found wins. `install.sh` detects which location your system
actually uses and installs there — it does **not** install to both. If you
somehow have configs in both `~/.tmux.conf` and `~/.config/tmux/tmux.conf`,
the installer will warn you and only touch the one tmux reads.

### Manual

1. Install `micro`, `tmux`, and `flake8`:
   - **Ubuntu/Debian**: `sudo apt install tmux flake8`, then [install micro](https://github.com/zyedidia/micro#installation)
   - **Void**: `sudo xbps-install tmux micro flake8`
2. Copy `configs/micro-settings.json` to `~/.config/micro/settings.json`
3. Copy `configs/tmux.conf` to `~/.tmux.conf` (or `~/.config/tmux/tmux.conf`)
4. Copy `micromux` somewhere on your `PATH` and `chmod +x` it

## Usage

```bash
micromux myfile.py
```

- Top pane: micro on `myfile.py`
- Bottom pane: a shell where you can run `python3 myfile.py`

### Keys

| Key | Action |
|---|---|
| `Ctrl+S` | Save in micro (triggers lint) |
| `Ctrl+Q` | Quit micro |
| `Alt+↑` / `Alt+↓` | Switch pane |
| `Ctrl+B` then `d` | Detach tmux (session keeps running) |
| `tmux attach -t micromux` | Reattach |

## Linting

`micromux` ships with **flake8** as the Python linter, configured in
`~/.config/micro/settings.json`:

```json
{
    "linter": true,
    "linter.python": "flake8"
}
```

- **`linter: true`** turns on micro's built-in linter plugin — it ships with
  micro, no extra install needed.
- **`linter.python: flake8`** tells micro to run `flake8` on `.py` files.
  When you save, errors appear at the bottom of the screen.

### flake8 flags two kinds of things

- **Logical errors** (unused imports, undefined names, redefinitions)
- **Style issues** (line length, whitespace around operators, indentation)

For a beginner, both are useful. If the style noise feels overwhelming, swap
to **pyflakes**, which only reports logical errors:

1. Install pyflakes: `python3 -m pip install --user pyflakes`
2. Edit `~/.config/micro/settings.json` and change
   `"linter.python": "flake8"` to `"linter.python": "pyflakes"`

### Jumping between lint errors

Micro places the cursor on the first error after save. To cycle through them,
press `Alt+,` and `Alt+.`.

## ⚠️ Gotchas

- **`Ctrl+W` in a browser terminal closes the tab.** If you're using `sshx` or
  a web SSH client, don't use `Ctrl+W` inside micro — it kills your session.
  Use `Ctrl+S` to save instead.
- **micro lints on save, not as you type.** Save with `Ctrl+S` and errors
  appear at the bottom.
- **flake8 is opinionated.** It flags style, not just bugs. See the Linting
  section for how to switch to pyflakes.
- **Backups from `install.sh`** are named `<config>.bak.YYYYMMDD-HHMMSS`. The
  installer prints the restore command for each one it creates.

## Uninstall

```bash
rm ~/.config/micro/settings.json
rm ~/.tmux.conf            # or ~/.config/tmux/tmux.conf
rm ~/bin/micromux
```

Then remove `micro`, `tmux`, and `flake8` with your package manager.

If you have timestamped backups (e.g. `~/.tmux.conf.bak.20261016-143022`),
restore whichever one you want:

```bash
mv ~/.tmux.conf.bak.20261016-143022 ~/.tmux.conf
```

## License

GPL-3.0 — see [LICENSE](LICENSE).

