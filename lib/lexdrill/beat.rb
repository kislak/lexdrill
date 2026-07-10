# frozen_string_literal: true

require "fileutils"

# Global rhythm config: repeats loops of `loop_size` consecutive words
# `repetitions` times before advancing to the next loop. Lives at
# ~/.drill.beat, independent of whichever project's .drill.txt is active.
# Disabled (plain word-by-word advance) unless explicitly configured.
module Lexdrill::Beat
  PATH = File.join(Dir.home, ".drill.beat")
  MIN_LOOP_SIZE = 2
  MAX_LOOP_SIZE = 8
  DEFAULT_REPETITIONS = 8

  ALIASES = {
    "polka" => 2,
    "waltz" => 3,
    "rock" => 4,
    "jazz" => 5,
    "jiga" => 6,
    "balkan" => 7,
    "samba" => 8
  }.freeze

  def self.configured?
    File.exist?(PATH)
  end

  def self.set(loop_size, repetitions)
    File.write(PATH, "#{loop_size} #{repetitions}")
  end

  def self.clear
    FileUtils.rm_f(PATH)
  end

  def self.valid_loop_size?(value)
    (MIN_LOOP_SIZE..MAX_LOOP_SIZE).cover?(value)
  end

  def self.repetitions_or_default(value)
    value ? value.to_i : DEFAULT_REPETITIONS
  end

  def self.loop_size
    settings[0]
  end

  def self.repetitions
    settings[1]
  end

  # Total steps in one full cycle through the word list at the current
  # rhythm, or plain `word_count` when no beat is configured.
  def self.cycle_length(word_count)
    return word_count unless configured?

    chunk_sizes(word_count).sum { |size| size * repetitions }
  end

  # Maps a step (already bounded within cycle_length) to a word index.
  def self.index_for(word_count, step)
    return step unless configured?

    locate(chunk_sizes(word_count), step)
  end

  def self.locate(sizes, step)
    offset = 0
    sizes.each do |size|
      span = size * repetitions
      return offset + (step % size) if step < span

      step -= span
      offset += size
    end
    0
  end
  private_class_method :locate

  def self.settings
    return [nil, nil] unless configured?

    parts = File.read(PATH).strip.split
    [parts[0].to_i, parts[1].to_i]
  end
  private_class_method :settings

  def self.chunk_sizes(word_count)
    full, remainder = word_count.divmod(loop_size)
    sizes = Array.new(full, loop_size)
    sizes << remainder if remainder.positive?
    sizes
  end
  private_class_method :chunk_sizes
end
