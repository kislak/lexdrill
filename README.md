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

If you don't create one, `drill next` seeds `~/.drill.txt` with a default
starter list (a set of NLP presuppositions) the first time it runs, so
there's always something to drill.

Run `drill next` to print the current word and advance to the next one.
There are two output styles (`drill format simple|full`, `simple` is the
default):

**simple** — the drill sign (always blue), a space, then the word (colored
by its show count — see "Mastery" below), all on one line:
```
⟳ apple
```

**full** — `counter/total⟳[loop_start-loop_end]` on one line, the word on
the next, colored by the word's show count:
```
1/6⟳[1-3]
apple
```
(word 1 of 6 total; currently in the loop spanning words 1-3)

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

#### Word only shows once per session, then stops (bash)

The bash hook works by appending a `$(drill_precmd)` command substitution to
`PS1`, which bash re-evaluates on every prompt render — this is deliberate,
since some environments (notably Google Cloud Shell's `bashrc.google`)
snapshot and unconditionally overwrite `PROMPT_COMMAND` after your `.bashrc`
runs, silently dropping anything hooked in that way. If you installed an
older version of the hook and see the word print exactly once and never
again, re-run `drill hook bash` and update the line in your `.bashrc` to the
current snippet.

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

### Frequency (`rand`)

`next` fires on every single prompt by default via the shell hook, which can
feel noisy in a busy session. `drill rand <n>` makes it actually show a word
only approximately 1-in-`n` times instead:

```bash
drill rand 10   # roughly one in every ten calls
drill rand 1    # back to every time (the default)
```

This is a **global** setting applied inside `drill next` itself — unlike
`start`/`stop`, it affects *every* call, hook-triggered or manually typed.
On a "skip", `next` silently does nothing (no output, nothing advances) and
exits 0.

### Mastery (color by show count)

Every time `next` shows a word it's tracked in `.drill.stats` (see
[`drill stats`](#commands) below). On an **odd** show count, the word's
color follows a blue → red gradient, one step per 100 shows — so at a
glance, blue words are fresh and red words are heavily drilled. On an
**even** show count, it's a vivid random color instead, just for visual
variety. Once a word hits 1200 shows it's considered mastered and `next`
stops selecting it (it still appears in `drill list`/`drill stats`, just no
longer comes up automatically). If every word in the list has been
mastered, `next` reports that on stderr and exits 1 instead of showing
anything.

### Google Sheets export

`drill export <sheet-name>` mirrors your word list (text only, no stats)
into a tab of a Google Sheet you own; `drill import <sheet-name>` reads it
back. There are two ways to authenticate — pick whichever you prefer:

- **`drill remote <url>`** — a **service account** you create yourself. No
  interactive sign-in, ever; you share the spreadsheet with the service
  account's email address once, and `drill` uses a local private key file
  to sign its own requests.
- **`drill oauth <url>`** — your **personal Google login**, via a one-time
  interactive OAuth approval. No GCP service account needed, but you (or
  anyone using the gem) has to click through a sign-in flow once.

If both are configured, whichever you set **more recently** wins — running
`drill oauth <url>` after `drill remote <url>` switches `export`/`import`
over to the personal-login flow, and vice versa.

Either way, `export` always **overwrites** the named tab (creating it
first if it doesn't exist yet) with the current word list, one phrase per
row, so it stays an exact mirror even if the list shrinks. `import` is the
reverse: it reads column A of the tab (ignoring any other columns, like an
old export's show counts) and **replaces** your local `.drill.txt` —
useful for editing the list in Sheets and pulling changes back down, or
seeding a fresh machine from an existing sheet.

#### Option A: service account (`drill remote`)

No embedded secret, no interactive consent screen — but it does require a
one-time Google Cloud Console setup, and the resulting private key file is
a real secret you must keep local.

1. Go to <https://console.cloud.google.com>, select a project (reuse the
   one from Option B if you've already set that up), and make sure
   **Google Sheets API** is enabled (**APIs & Services → Library**).
2. **IAM & Admin → Service Accounts → "+ CREATE SERVICE ACCOUNT"**. Name it
   anything (e.g. `lexdrill-export`); skip granting it any project-level
   roles — it doesn't need any, since access comes from sharing the
   document directly.
3. Click into the new service account → **Keys → Add Key → Create new key
   → JSON → Create**. This downloads a `.json` file — **this is a real
   secret**, equivalent to a password. Never commit it, publish it, or
   share it with anyone.
4. Note the service account's email (looks like
   `name@your-project-id.iam.gserviceaccount.com` — also the `client_email`
   field in the downloaded JSON).
5. Open your target Google Sheet → **Share** → paste that email → grant
   **Editor** access → uncheck "Notify people" → Share.
6. Save the downloaded key file to `~/.drill.gcp-service-account.json` on
   your machine (`drill` reads it from that fixed path and sets it to mode
   `0600`; it's never embedded in the gem or committed anywhere).

```bash
drill remote 'https://docs.google.com/spreadsheets/d/1opBP4APL5SUvepm9qwjIYRNtDZdoY1Ee87F5PWdxaMg/edit?usp=sharing'
drill export Sheet1
```

No sign-in prompt — every call authenticates silently by signing a fresh,
short-lived JWT with the local key file.

#### Option B: personal login (`drill oauth`)

Uses the OAuth 2.0 **Device Authorization Grant** ("visit this URL, enter
this code," the same style of flow `gcloud auth login` uses) — you approve
access to your own account once, and the resulting token is cached locally
at `~/.drill.gcp-token.json` (mode `0600`), never published or shared.

The OAuth client id/secret embedded in `lib/lexdrill/google_auth.rb` are
**not** secret for this use — Google's own docs say client credentials for
"TVs and Limited Input devices" / installed-app clients aren't treated as
confidential (this is fundamentally different from the service account's
private key above, which genuinely is a secret). The actual secret is your
personal refresh token, generated only after you interactively approve.

1. Go to <https://console.cloud.google.com>, create or select a project,
   enable **Google Sheets API**.
2. **APIs & Services → OAuth consent screen**: User type **External**;
   publishing status **Testing** is fine — add your own Google account
   under "Test users".
3. **APIs & Services → Credentials → Create Credentials → OAuth client
   ID** → Application type **"TVs and Limited Input devices"** (no redirect
   URI needed). Copy the generated Client ID and Client secret into
   `CLIENT_ID`/`CLIENT_SECRET` in `lib/lexdrill/google_auth.rb`.
4. "Testing" publishing status has historically imposed a 7-day
   refresh-token expiry for some scopes. If `drill export` starts asking
   you to re-authorize every week, switch the consent screen to **"In
   production"** — for the `spreadsheets` scope (not a "restricted" scope)
   this just adds an "unverified app" click-through on first consent, no
   Google review required.

```bash
drill oauth 'https://docs.google.com/spreadsheets/d/1opBP4APL5SUvepm9qwjIYRNtDZdoY1Ee87F5PWdxaMg/edit?usp=sharing'
drill export Sheet1
```

The first `export`/`import` prints a URL and a short code — visit it, sign
in with the Google account that has edit access to that spreadsheet, and
approve. Every call after that is silent (the cached token refreshes
itself automatically).

### Commands

| Command | What it does |
|---|---|
| `drill next` | Print the current word and advance |
| `drill start` / `drill stop` | Pause/resume the automatic per-prompt hook (doesn't affect manual `next`) |
| `drill inspect` | Show the active `.drill.txt`/`.drill.counter`/`.drill.stats` paths, word count, counter value, toggle, beat, and rand state |
| `drill hook zsh\|bash` | Print the shell integration snippet (used above) |
| `drill beat <2-8> <repetitions>` / `drill beat none` | Set or disable the rhythm |
| `drill polka\|waltz\|rock\|jazz\|jiga\|balkan\|samba <repetitions>` | Shorthand for a fixed loop size (see table above) |
| `drill format simple\|full` | Set the output style (`simple` is the default) |
| `drill add <text>` | Append a new item to the end of the list |
| `drill list` | Show how many times each item has been shown, numbered |
| `drill open` | Open the list file in `$EDITOR`/`$VISUAL` (falls back to `vi`) |
| `drill stats` | Print all items as `<count>\t<phrase>` (tab-separated), sorted by show count, highest first |
| `drill rand <n>` | `drill next` shows a word ~1-in-`n` times (`n=1` is every time, the default) |
| `drill go <number>` | Jump so the next `drill next` shows item `<number>` (1-based, see `drill list`) — prints nothing itself; refuses a graduated item; has no effect while `drill beat rand` is active, since that mode ignores the counter entirely |
| `drill remote <url>` | Set the Google Sheet used by the service account flow (global, parses the spreadsheet id out of a normal share URL); whichever of `drill remote`/`drill oauth` was set more recently wins |
| `drill oauth <url>` | Set the Google Sheet used by the OAuth (personal-login) flow (global, parses the spreadsheet id out of a normal share URL); whichever of `drill remote`/`drill oauth` was set more recently wins |
| `drill export <sheet-name>` | Export the word list text to the named tab (created if it doesn't exist), overwriting it; uses whichever of `drill remote`/`drill oauth` was configured most recently (first OAuth use triggers a one-time Google device-flow sign-in) |
| `drill import <sheet-name>` | Replace the local word list with column A of the named tab |
