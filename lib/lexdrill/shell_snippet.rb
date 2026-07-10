# frozen_string_literal: true

# Generates the zsh/bash shell integration snippet for `drill hook`.
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

  BASH = <<~SNIPPET
    drill_precmd() {
      [ -f "$HOME/.drill.disabled" ] && return
      command drill next 2>/dev/null
    }
    case ";${PROMPT_COMMAND:-};" in
      *";drill_precmd;"*) ;;
      *) PROMPT_COMMAND="drill_precmd;${PROMPT_COMMAND}" ;;
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
