# frozen_string_literal: true

# Formats a shown word for display. In "simple" mode: the drill sign (in
# blue), a space, then the word (colored by its show count, blue -> red as
# it's drilled more), all on one line. In "full" mode (the default):
# "{counter}/{total}{SEPARATOR}[{loop_start}-{loop_end}]\n{word}" — counter
# is the word's own 1-based position in the list, re-derived through
# Lexdrill::Beat so it stays meaningful even when a rhythm repeats steps.
module Lexdrill::LineFormatter
  SEPARATOR = "⟳"

  def self.format(word)
    return simple(word) if Lexdrill::Format.simple?

    full(word)
  end

  def self.simple(word)
    count = Lexdrill::Stats.counts.fetch(word, 0)
    "#{Lexdrill::Colorizer.paint_blue(SEPARATOR)} #{Lexdrill::Colorizer.paint_by_count(word, count)}"
  end

  def self.full(word)
    total = Lexdrill::WordList.words.size
    info = loop_info(total)
    "#{info.index + 1}/#{total}#{SEPARATOR}[#{info.chunk_start}-#{info.chunk_end}]\n#{word}"
  end

  def self.loop_info(total)
    counter = Lexdrill::Counter.new(Lexdrill::WordList::COUNTER_PATH)
    step_used = counter.value - 1
    Lexdrill::Beat.loop_info(total, step_used)
  end
end
