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

**zsh** — add to `~/.zshrc`:
```zsh
eval "$(lexdrill hook zsh)"
```

**bash** — add to `~/.bashrc`:
```bash
eval "$(lexdrill hook bash)"
```

Then open a new shell (or `source ~/.zshrc` / `source ~/.bashrc`) to pick it up.

### Commands

| Command | What it does |
|---|---|
| `lexdrill next` | Print the current word and advance |
| `lexdrill start` / `lexdrill stop` | Pause/resume the automatic per-prompt hook (doesn't affect manual `next`) |
| `lexdrill inspect` | Show the active `.drill.txt`/`.drill.counter` paths, word count, counter value, and toggle state |
| `lexdrill hook zsh\|bash` | Print the shell integration snippet (used above) |
