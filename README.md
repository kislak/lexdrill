# lexdrill

The `lexdrill` gem installs a `drill` command that prints a vocabulary word or
phrase on demand, tracking how often each one has been shown.

## Installation

```bash
gem install lexdrill
```

### `drill: command not found` after install?

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

Run `drill next` to print the current word and advance to the next one.
There are two output styles (`drill format simple|full`, `full` is the
default):

**full** — `counter/total⟳[loop_start-loop_end]` on one line, the word on
the next, in a randomly-picked color:
```
1/6⟳[1-3]
apple
```
(word 1 of 6 total; currently in the loop spanning words 1-3)

**simple** — three drill signs (always blue), then the word on its own
line in a separately-picked random color:
```
⟳⟳⟳
apple
```

### Shell integration (one-time setup)

Add one line to your shell's rc file so the current word prints automatically
before each prompt. This is a **one-time step** — the line stays in your rc file
and takes effect in every new shell session from then on; you never need to run it
again by hand.

Add it near the **end** of the file, after anything that sets up your `PATH`
(rvm/rbenv init, Homebrew, etc.) — otherwise the shell may not know where
`drill` lives yet when this line runs. Guarding it with `command -v` also
means it never errors, even on a machine/session where `drill` isn't on
`PATH` for some reason.

**zsh** — add to `~/.zshrc`:
```zsh
if command -v drill >/dev/null 2>&1; then
  eval "$(drill hook zsh)"
fi
```

**bash** — add to `~/.bashrc`:
```bash
if command -v drill >/dev/null 2>&1; then
  eval "$(drill hook bash)"
fi
```

Then open a new shell (or `source ~/.zshrc` / `source ~/.bashrc`) to pick it up.

#### Hook not firing in new terminal windows/tabs (rvm users)?

Run `drill inspect` first — if it shows `Toggle: enabled` and a valid words
file, the tool itself is fine and the problem is that the hook function never
got registered in that session.

A common cause with rvm: rvm's installer sometimes puts its actual
PATH-loading line (`[[ -s "$HOME/.rvm/scripts/rvm" ]] && source
"$HOME/.rvm/scripts/rvm"`) in `~/.zlogin` (zsh) or `~/.bash_profile` (bash).
Those files only run for **login shells** — but many terminal emulators
(e.g. kitty) open new windows/tabs as **non-login** interactive shells, which
only source `~/.zshrc`/`~/.bashrc`. So rvm's gemset `bin/` directory (where
`drill` lives) never makes it onto `PATH` in those sessions, even though
everything looks correctly configured.

**Fix:** move that line into `~/.zshrc` / `~/.bashrc` (before the `drill`
hook block above, so it runs first) instead of relying on it only being in
`~/.zlogin` / `~/.bash_profile`. It's safe to leave it in both places.

### Rhythm (`beat`)

By default `next` just advances one word at a time. You can instead have it
repeat loops of consecutive words — e.g. a loop of 3 words shown twice each
before moving on:

```bash
drill beat 3 2     # loop size 3, repeat each loop 2 times
```

`drill beat none` turns it back off (plain word-by-word again). This is a
**global** setting — it applies everywhere, independent of which project's
`.drill.txt` is currently active.

There are also named shortcuts for common loop sizes, one word/phrase apart:

| Loop size | Alias    |
|-----------|----------|
| 2         | `polka`  |
| 3         | `waltz`  |
| 4         | `rock`   |
| 5         | `jazz`   |
| 6         | `jiga`   |
| 7         | `balkan` |
| 8         | `samba`  |

`drill waltz 16` is shorthand for `drill beat 3 16`. Repetitions default to
`8` if you leave them off — `drill jazz` alone is `drill beat 5 8`, and
`drill beat 4` alone is `drill beat 4 8`.

### Commands

| Command | What it does |
|---|---|
| `drill next` | Print the current word and advance |
| `drill start` / `drill stop` | Pause/resume the automatic per-prompt hook (doesn't affect manual `next`) |
| `drill inspect` | Show the active `.drill.txt`/`.drill.counter` paths, word count, counter value, toggle, and beat state |
| `drill hook zsh\|bash` | Print the shell integration snippet (used above) |
| `drill beat <2-8> <repetitions>` / `drill beat none` | Set or disable the rhythm |
| `drill polka\|waltz\|rock\|jazz\|jiga\|balkan\|samba <repetitions>` | Shorthand for a fixed loop size (see table above) |
| `drill format simple\|full` | Set the output style (`full` is the default) |
