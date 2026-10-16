Here is a cheat sheet for the `micro` editor, covering its default keybindings, command-line options, and common commands.

---

## 🚀 Getting Started

| Command | Description |
|---|---|
| `micro textfile.txt` | Open a file |
| `micro file1.txt file2.txt` | Open multiple files |
| `micro -diff file1 file2` | Diff two files |
| `Ctrl + q` | Quit (or close current tab/split) |
| `Ctrl + s` | Save current file |
| `Ctrl + o` | Open a file |
| `Ctrl + g` | Open the help menu |
| `Ctrl + e` | Open the command bar |
| `Alt + g` | Show what every key does in a bar at the bottom |



---

## 🧭 Navigation

| Key | Description |
|---|---|
| `Ctrl + Left` | Move to previous word |
| `Ctrl + Right` | Move to next word |
| `Alt + {` | Move to previous paragraph |
| `Alt + }` | Move to next paragraph |
| `Home` | Move to beginning of line |
| `End` | Move to end of line |
| `Ctrl + Home` | Move to start of file |
| `Ctrl + End` | Move to end of file |
| `Ctrl + e` then `goto 42` | Jump to line 42 |



---

## 📝 Selection

| Key | Description |
|---|---|
| `Shift + Arrow` | Extend selection by one character or line |
| `Ctrl + Shift + Left` | Select to previous word |
| `Ctrl + Shift + Right` | Select to next word |
| `Shift + Home` | Select to beginning of line |
| `Shift + End` | Select to end of line |
| `Ctrl + a` | Select all text |



---

## ✏️ Editing

| Key | Description |
|---|---|
| `Ctrl + z` | Undo |
| `Ctrl + y` | Redo |
| `Ctrl + c` | Copy selected text |
| `Ctrl + x` | Cut selected text |
| `Ctrl + v` | Paste from clipboard |
| `Ctrl + k` | Cut the current line |
| `Ctrl + d` | Duplicate the current line |
| `Tab` | Indent selection or insert tab |
| `Shift + Tab` | Unindent selection |
| `Ctrl + u` | Start/stop recording a macro |
| `Ctrl + j` | Play the recorded macro |



---

## 🔍 Search and Replace

| Key / Command | Description |
|---|---|
| `Ctrl + f` | Find (incremental search) |
| `Ctrl + n` | Find next match |
| `Ctrl + p` | Find previous match |
| `Alt + F` | Find literal (no regex) |
| `Ctrl + e` then `replace "search" "replacement"` | Replace with confirmation |
| `Ctrl + e` then `replace -a "search" "replacement"` | Replace all occurrences |



---

## 🖱️ Multiple Cursors

| Key | Description |
|---|---|
| `Ctrl + Click` | Place an additional cursor |
| `Alt + n` | Spawn a cursor at the next match of the current word |
| `Alt + x` | Skip the current match |
| `Alt + p` | Remove the last added cursor |
| `Alt + c` | Remove all extra cursors |
| `Alt + m` | Spawn a cursor on every match |



---

## 🗂️ Tabs and Splits

| Key / Command | Description |
|---|---|
| `Ctrl + t` | Open a new tab |
| `Alt + ,` | Switch to previous tab |
| `Alt + .` | Switch to next tab |
| `Ctrl + w` | Jump to the next split |
| `Ctrl + q` | Close the current split or tab |
| `Ctrl + e` then `vsplit other.txt` | Vertical split |
| `Ctrl + e` then `hsplit notes.txt` | Horizontal split |
| `Ctrl + e` then `tab third.txt` | Open in a new tab |



---

## ⌨️ Command Bar (`Ctrl + e`)

| Command | Description |
|---|---|
| `save ['filename']` | Save current buffer (optionally as) |
| `quit` | Quit micro |
| `goto 'line[:col]'` | Go to absolute line (and optional column) |
| `jump 'line[:col]'` | Go to relative line from current |
| `replace 'search' 'value' [-a] [-l]` | Replace text (`-a` = all, `-l` = literal) |
| `replaceall 'search' 'value'` | Replace all without confirmation |
| `set 'option' 'value'` | Set an option (persists to settings.json) |
| `setlocal 'option' 'value'` | Set an option locally (current buffer only) |
| `toggle 'option'` | Toggle a two-value option |
| `bind 'key' 'action'` | Create a keybinding |
| `help ['topic']` | Open help topic (e.g., `help defaultkeys`) |



---

## ⚙️ Command-Line Options

| Option | Description |
|---|---|
| `micro -clean` | Clean the configuration directory and exit |
| `micro -config-dir dir` | Specify a custom configuration directory |
| `micro -options` | Show all options and exit |
| `micro -debug` | Enable debug mode (logging to `./log.txt`) |
| `micro -version` | Show version information |
| `micro +LINE:COL file` | Open file at a specific line and column |
| `micro +/REGEX file` | Open file and search for a regex |
| `micro -plugin install [PLUGIN]` | Install plugin(s) |
| `micro -plugin remove [PLUGIN]` | Remove plugin(s) |
| `micro -plugin update` | Update all plugins |
| `micro -plugin list` | List installed plugins |
| `micro -option value file` | Set an option for the session (e.g., `-syntax off`) |



---

## 🛠️ Configuration

- **Configuration directory**: `~/.config/micro` (or `$MICRO_CONFIG_HOME` / `$XDG_CONFIG_HOME/micro`)
- **Settings file**: `~/.config/micro/settings.json`
- **Keybindings file**: `~/.config/micro/bindings.json`
- **Lua config**: `~/.config/micro/init.lua`

**Example** — bind `Ctrl-r` to redo in `bindings.json`:

```json
{
    "Ctrl-r": "Redo"
}
```



---

## 🆘 Getting Help Inside micro

| Command | Description |
|---|---|
| `Ctrl + g` | Open the help menu |
| `Ctrl + e` then `help` | Open the main help page |
| `Ctrl + e` then `help defaultkeys` | List default keybindings |
| `Ctrl + e` then `help commands` | List all commands |
| `Ctrl + e` then `help options` | List all options |
| `Ctrl + e` then `help tutorial` | Open the tutorial |
| `Ctrl + e` then `help plugins` | Learn about the plugin system |



---

This cheat sheet covers the essentials to get you productive with `micro`. For a complete reference, use the built-in help system (`Ctrl + g`) or run `> help` from the command bar.

---

