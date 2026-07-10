# frozen_string_literal: true

# Wraps text in an ANSI color code.
module Lexdrill::Colorizer
  CODES = [31, 32, 33, 34, 35, 36, 91, 92, 93, 94, 95, 96].freeze
  BLUE = 34

  def self.paint(text)
    wrap(text, CODES.sample)
  end

  def self.paint_blue(text)
    wrap(text, BLUE)
  end

  def self.wrap(text, code)
    "\e[#{code}m#{text}\e[0m"
  end
  private_class_method :wrap
end
