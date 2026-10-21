# frozen_string_literal: true

# Formats a shown word for display, on one line:
# "{SEPARATOR}{index}/{total} {word}" — index is the word's own 1-based
# position in the list, re-derived through Lexdrill::Beat so it stays
# meaningful even when a rhythm repeats steps. The separator and
# counter/total are painted yellow, as one unit; the word is colored by
# its show count (see Lexdrill::Colorizer).
module Lexdrill::LineFormatter
  SEPARATOR = "⟳"

  def self.format(word)
    total = Lexdrill::WordList.words.size
    count = Lexdrill::Stats.counts.fetch(word, 0)
    prefix = Lexdrill::Colorizer.paint_yellow("#{SEPARATOR}#{loop_index(total) + 1}/#{total}")
    "#{prefix} #{Lexdrill::Colorizer.paint_by_count(word, count)}"
  end

  def self.loop_index(total)
    counter = Lexdrill::Counter.new(Lexdrill::WordList::COUNTER_PATH)
    step_used = counter.value - 1
    Lexdrill::Beat.loop_info(total, step_used).index
  end
end
