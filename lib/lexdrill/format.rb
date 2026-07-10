# frozen_string_literal: true

# Global display mode for `next`'s output: "full" (position + loop info) or
# "simple" (just the word). Lives at ~/.drill.format; defaults to "full".
module Lexdrill::Format
  PATH = File.join(Dir.home, ".drill.format")
  SIMPLE = "simple"
  FULL = "full"
  VALID = [SIMPLE, FULL].freeze

  def self.current
    return FULL unless File.exist?(PATH)

    value = File.read(PATH).strip
    VALID.include?(value) ? value : FULL
  end

  def self.set(mode)
    File.write(PATH, mode)
  end

  def self.simple?
    current == SIMPLE
  end
end
