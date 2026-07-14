# frozen_string_literal: true

# Global "how to color a shown word" setting: "default" colors by show
# count (see Lexdrill::Colorizer's blue -> red gradient); "random" picks a
# vivid random color every time instead. An absent file (or any
# unrecognized value) means "default".
module Lexdrill::Color
  PATH = Lexdrill::Config.path("color")
  RANDOM = "random"
  DEFAULT = "default"
  VALID = [RANDOM, DEFAULT].freeze

  def self.set(mode)
    File.write(PATH, mode)
  end

  def self.current
    return DEFAULT unless File.exist?(PATH)

    value = File.read(PATH).strip
    VALID.include?(value) ? value : DEFAULT
  end

  def self.random?
    current == RANDOM
  end
end
