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
      Toggle:        #{toggle_summary}
      LEXDRILL_PATH: #{ENV.fetch('LEXDRILL_PATH', '(not set)')}
    REPORT
  end

  def self.words_summary
    return "missing" unless File.exist?(Lexdrill::WordList::PATH)

    "#{Lexdrill::WordList.words.size} word(s)"
  end

  def self.counter_value
    Lexdrill::Counter.new(Lexdrill::WordList::COUNTER_PATH).value
  end

  def self.toggle_summary
    return "enabled" if Lexdrill::Toggle.enabled?

    "stopped (#{Lexdrill::Toggle::PATH})"
  end
end
