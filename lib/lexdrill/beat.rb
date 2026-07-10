# frozen_string_literal: true

require "fileutils"

# Global rhythm config: repeats loops of `loop_size` consecutive words
# `repetitions` times before advancing to the next loop. Lives at
# ~/.drill.beat, independent of whichever project's .drill.txt is active.
# Disabled (plain word-by-word advance) unless explicitly configured.
# `drill beat rand` selects a third mode (marked by the literal contents
# "rand") where WordList.next ignores the counter/rhythm entirely and picks
# a uniformly random word each time instead.
module Lexdrill::Beat
  PATH = File.join(Dir.home, ".drill.beat")
  MIN_LOOP_SIZE = 2
  MAX_LOOP_SIZE = 8
  DEFAULT_REPETITIONS = 8
  RAND_MARKER = "rand"

  ALIASES = {
    "polka" => 2,
    "waltz" => 3,
    "rock" => 4,
    "jazz" => 5,
    "jiga" => 6,
    "balkan" => 7,
    "samba" => 8
  }.freeze

  # index: 0-based word index. chunk_start/chunk_end: 1-based word positions
  # spanned by the current loop. loop_number: which repeat pass (1-based)
  # through the current loop. total_loops: the configured repetitions.
  LoopInfo = Struct.new(:index, :chunk_start, :chunk_end, :loop_number, :total_loops, keyword_init: true)

  def self.configured?
    File.exist?(PATH) && !rand?
  end

  def self.rand?
    File.exist?(PATH) && File.read(PATH).strip == RAND_MARKER
  end

  def self.set(loop_size, repetitions)
    File.write(PATH, "#{loop_size} #{repetitions}")
  end

  def self.set_rand
    File.write(PATH, RAND_MARKER)
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
    loop_info(word_count, step).index
  end

  # The inverse of index_for: the earliest step that lands on target_index,
  # for `drill go` to jump the counter straight to a specific word.
  def self.step_for_index(word_count, target_index)
    (0...cycle_length(word_count)).find { |step| index_for(word_count, step) == target_index }
  end

  # Full detail on where `step` falls: word index, the current loop's word
  # range, which repeat pass it is, and how many total. A single "loop"
  # spanning the whole list (shown once) when no beat is configured.
  def self.loop_info(word_count, step)
    unless configured?
      return LoopInfo.new(index: step, chunk_start: 1, chunk_end: word_count, loop_number: 1, total_loops: 1)
    end

    locate(word_count, step)
  end

  def self.locate(word_count, step)
    offset = 0
    chunk_sizes(word_count).each do |size|
      span = size * repetitions
      return locate_within(offset, size, step) if step < span

      step -= span
      offset += size
    end
    LoopInfo.new(index: 0, chunk_start: 1, chunk_end: word_count, loop_number: 1, total_loops: 1)
  end
  private_class_method :locate

  def self.locate_within(offset, size, step)
    LoopInfo.new(
      index: offset + (step % size),
      chunk_start: offset + 1,
      chunk_end: offset + size,
      loop_number: (step / size) + 1,
      total_loops: repetitions
    )
  end
  private_class_method :locate_within

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
