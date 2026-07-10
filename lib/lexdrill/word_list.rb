# frozen_string_literal: true

# Reads vocabulary words/phrases from a `.drill.txt` file, one per line, and
# advances a persisted counter to show "the current word" each time.
class Lexdrill::WordList
  PATH = Lexdrill::Config::DRILL_PATH
  COUNTER_PATH = Lexdrill::Config::COUNTER_PATH

  def self.words
    @words ||= File.exist?(PATH) && File.readlines(PATH).map(&:strip).reject(&:empty?)
    @words ||= []
  end

  def self.next
    return nil if words.empty?

    words[take_index(words.size)]
  end

  def self.take_index(size)
    counter = Lexdrill::Counter.new(COUNTER_PATH)
    cycle_length = Lexdrill::Beat.cycle_length(size)
    step = counter.bounded_value(cycle_length)
    counter.increment
    Lexdrill::Beat.index_for(size, step)
  end
end
