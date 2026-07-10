# frozen_string_literal: true

# Global display mode for `next`'s output: "simple" (the drill sign + word)
# or "full" (position + loop info). Lives at ~/.drill.format; defaults to
# "simple".
module Lexdrill::Format
  PATH = File.join(Dir.home, ".drill.format")
  SIMPLE = "simple"
  FULL = "full"
  VALID = [SIMPLE, FULL].freeze

  def self.current
    return SIMPLE unless File.exist?(PATH)

    value = File.read(PATH).strip
    VALID.include?(value) ? value : SIMPLE
  end

  def self.set(mode)
    File.write(PATH, mode)
  end

  def self.simple?
    current == SIMPLE
  end
end
