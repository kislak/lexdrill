# frozen_string_literal: true

# Builds a human-readable snapshot of lexdrill's current config/state, for
# `drill inspect` — which files are active, how many words, the counter
# value, and whether drilling is currently stopped.
module Lexdrill::Inspector
  def self.report
    <<~REPORT
      drill #{Lexdrill::VERSION}

      Words file:    #{Lexdrill::WordList::PATH} (#{words_summary})
      Counter file:  #{Lexdrill::WordList::COUNTER_PATH} (value: #{counter_value})
      Stats file:    #{Lexdrill::Stats::PATH} (#{stats_summary})
      Toggle:        #{toggle_summary}
      Beat:          #{beat_summary}
      Rand:          #{rand_summary}
      Color:         #{Lexdrill::Color.current}
      Remote:        #{remote_summary}
      Config dir:    #{Lexdrill::Config::DIR}
    REPORT
  end

  def self.remote_summary
    Lexdrill::RemoteTarget.url || "not configured"
  end

  def self.words_summary
    return "missing" unless File.exist?(Lexdrill::WordList::PATH)

    words = Lexdrill::WordList.words
    total = words.size
    graduated = words.count { |word| Lexdrill::Stats.graduated?(word) }
    return "#{total} word(s)" if graduated.zero?

    "#{total} word(s), #{graduated} graduated"
  end

  def self.counter_value
    Lexdrill::Counter.new(Lexdrill::WordList::COUNTER_PATH).value
  end

  def self.stats_summary
    return "no data yet" unless File.exist?(Lexdrill::Stats::PATH)

    "#{Lexdrill::Stats.counts.size} item(s) tracked"
  end

  def self.toggle_summary
    return "enabled" if Lexdrill::Toggle.enabled?

    "stopped (#{Lexdrill::Toggle::PATH})"
  end

  def self.beat_summary
    return "random (ignores rhythm/counter)" if Lexdrill::Beat.rand?
    return "not set (plain word-by-word)" unless Lexdrill::Beat.configured?

    "loop #{Lexdrill::Beat.loop_size}, repeat #{Lexdrill::Beat.repetitions}"
  end

  def self.rand_summary
    denominator = Lexdrill::Rand.value
    return "every time (default)" if denominator == 1

    "approximately 1-in-#{denominator}"
  end
end
