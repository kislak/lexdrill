# frozen_string_literal: true

RSpec.describe Lexdrill::ShellSnippet do
  describe ".for" do
    it "returns the zsh snippet with a precmd hook, a toggle check, and an idempotency guard" do
      snippet = described_class.for("zsh")
      expect(snippet).to include("precmd_functions+=(lexdrill_precmd)")
      expect(snippet).to include("command lexdrill next 2>/dev/null")
      expect(snippet).to include('[[ -f "$HOME/.drill.disabled" ]] && return')
    end

    it "returns the bash snippet with a PROMPT_COMMAND hook, a toggle check, and an idempotency guard" do
      snippet = described_class.for("bash")
      expect(snippet).to include('PROMPT_COMMAND="lexdrill_precmd;${PROMPT_COMMAND}"')
      expect(snippet).to include("command lexdrill next 2>/dev/null")
      expect(snippet).to include('[ -f "$HOME/.drill.disabled" ] && return')
    end

    it "raises for an unsupported shell" do
      expect { described_class.for("fish") }.to raise_error(ArgumentError, /fish/)
    end
  end
end
