# frozen_string_literal: true

# Reads vocabulary words/phrases from the words file, one per line, and
# advances a persisted counter to show "the current word" each time. On a
# fresh install, seeds the file with a default starter list instead of
# coming up empty. Words that have graduated (see Lexdrill::Stats) are
# excluded from `.next` but remain in `.words` for `list`/`stats` to report.
class Lexdrill::WordList
  PATH = Lexdrill::Config.path("words")
  COUNTER_PATH = Lexdrill::Config.path("counter")

  def self.words
    seed_default
    @words ||= File.exist?(PATH) && File.readlines(PATH, encoding: "UTF-8").map(&:strip).reject(&:empty?)
    @words ||= []
  end

  def self.seed_default
    return if File.exist?(PATH)

    File.write(PATH, Lexdrill::DefaultWords::TEXT, encoding: "UTF-8")
  end
  private_class_method :seed_default

  def self.next
    active = active_words
    return nil if active.empty?

    word = Lexdrill::Beat.rand? ? active.sample : active[take_index(active.size)]
    Lexdrill::Stats.record(word)
    word
  end

  def self.active_words
    words.reject { |word| Lexdrill::Stats.graduated?(word) }
  end

  def self.take_index(size)
    counter = Lexdrill::Counter.new(COUNTER_PATH)
    cycle_length = Lexdrill::Beat.cycle_length(size)
    step = counter.bounded_value(cycle_length)
    counter.increment
    Lexdrill::Beat.index_for(size, step)
  end
end
