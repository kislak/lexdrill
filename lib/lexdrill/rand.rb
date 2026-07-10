# frozen_string_literal: true

# Global "how often to actually show a word" setting, applied by
# `drill next` itself (both automatic hook-triggered calls and manual
# invocations respect it equally). Lives at ~/.drill.rand as a plain
# integer; defaults to 1 (show every time).
module Lexdrill::Rand
  PATH = File.join(Dir.home, ".drill.rand")
  DEFAULT = 1

  def self.value
    return DEFAULT unless File.exist?(PATH)

    denominator = File.read(PATH).strip.to_i
    denominator.positive? ? denominator : DEFAULT
  end

  def self.set(denominator)
    File.write(PATH, denominator.to_s)
  end

  # True with probability (n-1)/n: "skip this show".
  def self.skip?
    denominator = value
    return false if denominator <= 1

    Kernel.rand(denominator) != 0
  end
end
