# frozen_string_literal: true

RSpec.describe Lexdrill::Colorizer do
  describe ".paint" do
    it "wraps the text in an ANSI color code from the palette, reset at the end" do
      result = described_class.paint("hello")
      expect(result).to match(/\A\e\[\d+mhello\e\[0m\z/)

      code = result[/\e\[(\d+)m/, 1].to_i
      expect(described_class::CODES).to include(code)
    end
  end
end
