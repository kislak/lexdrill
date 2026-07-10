# frozen_string_literal: true

# Reads vocabulary words/phrases from a `.drill.txt` file, one per line, and
# advances a persisted counter to show "the current word" each time. On a
# fresh install with no project-local or LEXDRILL_PATH-overridden list, seeds
# ~/.drill.txt with a default starter list instead of coming up empty.
class Lexdrill::WordList
  PATH = Lexdrill::Config::DRILL_PATH
  COUNTER_PATH = Lexdrill::Config::COUNTER_PATH
  HOME_PATH = Lexdrill::Config.home_drill_path

  def self.words
    seed_default_at_home
    @words ||= File.exist?(PATH) && File.readlines(PATH, encoding: "UTF-8").map(&:strip).reject(&:empty?)
    @words ||= []
  end

  def self.seed_default_at_home
    return if PATH != HOME_PATH || File.exist?(PATH)

    File.write(PATH, Lexdrill::DefaultWords::TEXT, encoding: "UTF-8")
  end
  private_class_method :seed_default_at_home

  def self.next
    return nil if words.empty?

    word = words[take_index(words.size)]
    Lexdrill::Stats.record(word)
    word
  end

  def self.take_index(size)
    counter = Lexdrill::Counter.new(COUNTER_PATH)
    cycle_length = Lexdrill::Beat.cycle_length(size)
    step = counter.bounded_value(cycle_length)
    counter.increment
    Lexdrill::Beat.index_for(size, step)
  end
end
