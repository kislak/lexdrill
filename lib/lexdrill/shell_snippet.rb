# frozen_string_literal: true

# Generates the zsh/bash shell integration snippet for `lexdrill hook`.
module Lexdrill::ShellSnippet
  ZSH = <<~SNIPPET
    lexdrill_precmd() {
      command lexdrill next 2>/dev/null
    }
    if [[ -z "${precmd_functions[(r)lexdrill_precmd]}" ]]; then
      precmd_functions+=(lexdrill_precmd)
    fi
  SNIPPET

  BASH = <<~SNIPPET
    lexdrill_precmd() {
      command lexdrill next 2>/dev/null
    }
    case ";${PROMPT_COMMAND:-};" in
      *";lexdrill_precmd;"*) ;;
      *) PROMPT_COMMAND="lexdrill_precmd;${PROMPT_COMMAND}" ;;
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
