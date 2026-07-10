# frozen_string_literal: true

# Generates the zsh/bash shell integration snippet for `drill hook`.
# Show-frequency throttling (`drill rand <n>`) lives entirely in `drill
# next` itself, not in these snippets, so it applies equally to
# hook-triggered and manually-run calls.
module Lexdrill::ShellSnippet
  ZSH = <<~SNIPPET
    drill_precmd() {
      [[ -f "$HOME/.drill.disabled" ]] && return
      command drill next 2>/dev/null
    }
    if [[ -z "${precmd_functions[(r)drill_precmd]}" ]]; then
      precmd_functions+=(drill_precmd)
    fi
  SNIPPET

  # Hooks via PS1 (re-evaluated on every prompt) rather than PROMPT_COMMAND,
  # since some environments (e.g. Google Cloud Shell's bashrc.google) snapshot
  # and overwrite PROMPT_COMMAND after the fact, silently dropping anything
  # appended to it. Output goes straight to /dev/tty so the word is never
  # captured into the PS1 string itself (which would need readline's `\[..\]`
  # non-printing markers to avoid cursor/line-wrap glitches from the color
  # codes).
  BASH = <<~SNIPPET
    drill_precmd() {
      [ -f "$HOME/.drill.disabled" ] && return
      command drill next >/dev/tty 2>/dev/null
    }
    case "$PS1" in
      *'$(drill_precmd)'*) ;;
      *) PS1="${PS1}"'$(drill_precmd)' ;;
    esac
  SNIPPET

  def self.for(shell_name)
    case shell_name.to_s
    when "zsh" then ZSH
    when "bash" then BASH
    else
      raise ArgumentError, "unsupported shell #{shell_name.inspect} (expected \"zsh\" or \"bash\")"
    end
  end
end
