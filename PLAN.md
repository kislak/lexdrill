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

### 2. Word list source (plain text file)
- Reader for a simple `.txt` file: one word/phrase per line.
- Configurable file path (env var), with a sensible default location.
- Handles blank lines / surrounding whitespace sensibly.
- **Verify:** unit tests covering parsing edge cases (blank lines,
  whitespace, empty file).

### 3. Local interaction store (`~/.cache/lexdrill`)
- A state file recording per-word interaction data: at minimum a view
  counter and last-shown time.
- File format **TBD** (JSON is the likely default, open to discussion).
- Tolerant of a missing or corrupt state file — never crashes, self-heals.
- **Verify:** unit tests for load/save round-trip and corruption recovery.

### 4. `lexdrill next` command
- Combines the word list (milestone 2) and the interaction store
  (milestone 3): picks the next word, prints it, increments its counter,
  persists the update.
- Selection strategy for this first pass **TBD** together (simplest
  options: round-robin through the file, or least-recently/least-shown
  first).
- **Verify:** unit tests + a manual run showing the counter advancing
  across repeated invocations.

### Later milestones (not detailed yet — revisit after milestone 4)
- Shell hook integration (zsh/bash, fires before each prompt).
- Throttling and any spaced-repetition scheduling refinement.
- Google Sheets–backed word list (the original vision), replacing/
  extending the plain text file source.
- Actual publish to rubygems.org.

## Status

- [x] Milestone 1 — Gem scaffold + quality tooling
- [ ] Milestone 2 — Word list source
- [ ] Milestone 3 — Local interaction store
- [ ] Milestone 4 — `lexdrill next` command
