# lexdrill

lexdrill prints a vocabulary word or phrase on demand, tracking how often each one has been shown.

## Installation

```bash
gem install lexdrill
```

### `lexdrill: command not found` after install?

This happens when the gem's executable directory isn't on your `PATH` — common with a
plain system Ruby (no rbenv/rvm). Fix it in one step:

**bash**
```bash
echo "export PATH=\"$(ruby -e 'puts Gem.bindir'):\$PATH\"" >> ~/.bashrc
source ~/.bashrc
```

**zsh**
```zsh
echo "export PATH=\"$(ruby -e 'puts Gem.bindir'):\$PATH\"" >> ~/.zshrc
source ~/.zshrc
```

Using an rbenv-managed Ruby? Run `rbenv rehash` instead. Using rvm? You shouldn't hit
this — rvm keeps gem executable directories on `PATH` automatically.

## Usage

Create a `.drill.txt` file — one word or phrase per line — in your home directory,
or in a specific project directory to give that project its own list:

```
apple
banana
cherry
```

Run `lexdrill next` to print the current word and advance to the next one.

### Shell integration (one-time setup)

Add one line to your shell's rc file so the current word prints automatically
before each prompt. This is a **one-time step** — the line stays in your rc file
and takes effect in every new shell session from then on; you never need to run it
again by hand.

Add it near the **end** of the file, after anything that sets up your `PATH`
(rvm/rbenv init, Homebrew, etc.) — otherwise the shell may not know where
`lexdrill` lives yet when this line runs. Guarding it with `command -v` also
means it never errors, even on a machine/session where `lexdrill` isn't on
`PATH` for some reason.

**zsh** — add to `~/.zshrc`:
```zsh
if command -v lexdrill >/dev/null 2>&1; then
  eval "$(lexdrill hook zsh)"
fi
```

**bash** — add to `~/.bashrc`:
```bash
if command -v lexdrill >/dev/null 2>&1; then
  eval "$(lexdrill hook bash)"
fi
```

Then open a new shell (or `source ~/.zshrc` / `source ~/.bashrc`) to pick it up.

#### Hook not firing in new terminal windows/tabs (rvm users)?

Run `lexdrill inspect` first — if it shows `Toggle: enabled` and a valid words
file, the tool itself is fine and the problem is that the hook function never
got registered in that session.

A common cause with rvm: rvm's installer sometimes puts its actual
PATH-loading line (`[[ -s "$HOME/.rvm/scripts/rvm" ]] && source
"$HOME/.rvm/scripts/rvm"`) in `~/.zlogin` (zsh) or `~/.bash_profile` (bash).
Those files only run for **login shells** — but many terminal emulators
(e.g. kitty) open new windows/tabs as **non-login** interactive shells, which
only source `~/.zshrc`/`~/.bashrc`. So rvm's gemset `bin/` directory (where
`lexdrill` lives) never makes it onto `PATH` in those sessions, even though
everything looks correctly configured.

**Fix:** move that line into `~/.zshrc` / `~/.bashrc` (before the `lexdrill`
hook block above, so it runs first) instead of relying on it only being in
`~/.zlogin` / `~/.bash_profile`. It's safe to leave it in both places.

### Commands

| Command | What it does |
|---|---|
| `lexdrill next` | Print the current word and advance |
| `lexdrill start` / `lexdrill stop` | Pause/resume the automatic per-prompt hook (doesn't affect manual `next`) |
| `lexdrill inspect` | Show the active `.drill.txt`/`.drill.counter` paths, word count, counter value, and toggle state |
| `lexdrill hook zsh\|bash` | Print the shell integration snippet (used above) |
