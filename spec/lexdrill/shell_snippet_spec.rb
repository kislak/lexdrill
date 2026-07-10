# frozen_string_literal: true

require "tempfile"

RSpec.describe Lexdrill::ShellSnippet do
  def valid_syntax?(shell, snippet)
    Tempfile.create(["lexdrill-snippet", ".sh"]) do |file|
      file.write(snippet)
      file.flush
      system(shell, "-n", file.path, out: File::NULL, err: File::NULL)
    end
  end

  describe ".for" do
    it "returns the zsh snippet with a precmd hook, a toggle check, and an idempotency guard" do
      snippet = described_class.for("zsh")
      expect(snippet).to include("precmd_functions+=(drill_precmd)")
      expect(snippet).to include("command drill next 2>/dev/null")
      expect(snippet).to include('[[ -f "$HOME/.drill.disabled" ]] && return')
      expect(valid_syntax?("zsh", snippet)).to be true
    end

    it "returns the bash snippet with a PS1 hook, a toggle check, and an idempotency guard" do
      snippet = described_class.for("bash")
      expect(snippet).to include(%(PS1="${PS1}"'$(drill_precmd)'))
      expect(snippet).to include("command drill next >/dev/tty 2>/dev/null")
      expect(snippet).to include('[ -f "$HOME/.drill.disabled" ] && return')
      expect(valid_syntax?("bash", snippet)).to be true
    end

    it "raises for an unsupported shell" do
      expect { described_class.for("fish") }.to raise_error(ArgumentError, /fish/)
    end
  end
end
