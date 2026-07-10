# lexdrill — implementation plan

## Vision

`lexdrill` is a command-line vocabulary drill tool, distributed as a Ruby
gem, that surfaces one word/phrase at a time while you work in the
terminal — eventually hooking into the shell prompt and drawing its word
list from a Google Sheet. We're building it incrementally: this plan
starts with the smallest useful slice (a local word list + a `next`
command) and defers the shell hook and Google Sheets integration to later
milestones, once the core is solid.

## Working agreement

- One milestone at a time. Each is small enough to review in a single
  sitting before we move to the next.
- Code quality is a first-class requirement, not cleanup at the end:
  RuboCop and Reek are configured in milestone 1 and must stay clean
  (no new offenses) at the end of every milestone from then on.
- Every milestone ships a working, tested slice — no half-finished code
  carried over to the next step.
- Design decisions marked **TBD** below are intentionally left for us to
  decide together when we get there, not pre-decided.

## Milestones

### 1. Gem scaffold + quality tooling
- Minimal gem skeleton: gemspec, Gemfile, Rakefile, `bin/lexdrill`.
- RuboCop config (`.rubocop.yml`) and Reek config (`.reek.yml`), wired into
  `rake` (e.g. `rake lint` running both).
- First working commands: `lexdrill version`, `lexdrill help`.
- Publish-readiness housekeeping: LICENSE, gemspec metadata (summary,
  homepage, authors), `.gitignore`.
- **Verify:** `gem build` succeeds, `gem install --local` works end to end,
  `rake lint` is clean, `rake spec` runs (empty suite) green.

### 2. Word list source (`.drill.txt`)
- `Lexdrill::WordList` reads one word/phrase per line from a `.drill.txt`
  file.
- Discovery: `.drill.txt` in the current directory takes precedence;
  falls back to `$HOME/.drill.txt` if the current directory has none. This
  lets a project directory carry its own list while still having a
  personal default.
- Handles blank lines / surrounding whitespace sensibly; missing/empty
  file → empty list, never crashes.
- **Verify:** unit tests covering discovery (cwd vs `$HOME`) and parsing
  edge cases (blank lines, whitespace, empty file).

### 3. Local interaction store (per-word-file counter)
- `Lexdrill::Counter` reads/writes a single integer counter as a plain
  text file — no JSON, matches the plain-text simplicity of the word list
  itself.
- Lives at `.drill.counter`, always a sibling of whichever `.drill.txt` was
  found (cwd or `$HOME`) — the counter travels with its word list rather
  than living in one global location.
- Tolerant of a missing or non-numeric file (treated as `0`) — never
  crashes, self-heals.
- **Verify:** unit tests for read/write round-trip and corruption
  recovery.

### 4. `lexdrill next` command
- `Lexdrill::WordList#next` combines the word list (milestone 2) and its
  counter (milestone 3): the counter is a plain index into the list
  (`counter % word_count`), so `next` always shows "the current word" and
  then advances the counter by one.
- Selection strategy: simple round-robin, wrapping back to the first word
  once the list is exhausted (decided together — no least-recently-shown
  logic for this first pass).
- **Verify:** unit tests + a manual run showing the word advancing (and
  wrapping) across repeated invocations.

### 5. Shell hook integration (zsh/bash)
- `Lexdrill::ShellSnippet` generates the integration snippet for
  `lexdrill hook zsh|bash`.
- zsh: registers a `precmd_functions` entry; bash: prepends to
  `PROMPT_COMMAND`. Both call `command lexdrill next 2>/dev/null` (bypasses
  aliases, swallows stderr so a misconfigured/missing `.drill.txt` doesn't
  spam every prompt) and are idempotent if the rc file gets sourced twice.
- Usage: `eval "$(lexdrill hook zsh)"` (or `bash`) added to `.zshrc`/
  `.bashrc`.
- **Verify:** unit tests for the generated snippets + a manual run
  simulating `precmd_functions`/`PROMPT_COMMAND` firing in real zsh/bash
  processes, confirming the word advances on each simulated prompt and
  double-sourcing doesn't double-register.

### 6. Global start/stop toggle
- `Lexdrill::Toggle` is a marker file at `~/.drill.disabled`; enabled by
  default, `lexdrill stop` creates it and `lexdrill start` removes it.
- The toggle only gates the **shell hook** (the generated zsh/bash
  snippet checks for the marker file before ever calling
  `command lexdrill next`) — not the `next` command itself, since a
  hook-triggered call and a manual `lexdrill next` are indistinguishable
  to the Ruby code. So `lexdrill next` always works when run directly;
  `stop`/`start` only control whether the *automatic* per-prompt calls
  happen. Independent of whichever project's `.drill.txt` is active
  (it's a global switch, not per-project).
- **Verify:** unit tests + a manual run confirming manual `next` prints
  even while stopped, while the zsh/bash hooks stay silent until
  `start`.

### 7. `lexdrill inspect`
- `Lexdrill::Inspector` reports the currently-active `.drill.txt`/
  `.drill.counter` paths (and whether the words file actually exists,
  and how many words it has), the live counter value, the toggle state
  (enabled/stopped, with the marker path), and the `LEXDRILL_PATH` env
  var if set.
- Motivated directly by real confusion during development: it wasn't
  obvious which installed version/paths were actually active. This
  makes that state visible on demand instead of guessing.
- **Verify:** unit tests + a manual run before/after `next`/`stop`.

### Later milestones (not detailed yet)
- Throttling and any spaced-repetition scheduling refinement.
- Google Sheets–backed word list (the original vision), replacing/
  extending the plain text file source.

## Status

- [x] Milestone 1 — Gem scaffold + quality tooling
- [x] Milestone 2 — Word list source
- [x] Milestone 3 — Local interaction store
- [x] Milestone 4 — `lexdrill next` command
- [x] Milestone 5 — Shell hook integration
- [x] Milestone 6 — Global start/stop toggle
- [x] Milestone 7 — `lexdrill inspect`
- [x] Published to rubygems.org (`lexdrill` 0.2.0, `0.3.0` pending)
