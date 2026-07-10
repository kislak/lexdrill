# frozen_string_literal: true

# Formats a shown word as "{line_number}/{total}#{SEPARATOR}\n{word}".
# `line_number` is the word's own 1-based position in the list — re-derived
# through Lexdrill::Beat so it stays meaningful even when a rhythm repeats
# steps.
module Lexdrill::LineFormatter
  SEPARATOR = "⟳"

  def self.format(word)
    total = Lexdrill::WordList.words.size
    "#{line_number(total)}/#{total}#{SEPARATOR}\n#{word}"
  end

  def self.line_number(total)
    counter = Lexdrill::Counter.new(Lexdrill::WordList::COUNTER_PATH)
    step_used = counter.value - 1
    Lexdrill::Beat.index_for(total, step_used) + 1
  end
end
