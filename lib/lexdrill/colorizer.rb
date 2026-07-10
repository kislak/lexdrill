# frozen_string_literal: true

# Wraps text in a randomly-picked ANSI color code from a fixed palette.
module Lexdrill::Colorizer
  CODES = [31, 32, 33, 34, 35, 36, 91, 92, 93, 94, 95, 96].freeze

  def self.paint(text)
    "\e[#{CODES.sample}m#{text}\e[0m"
  end
end
