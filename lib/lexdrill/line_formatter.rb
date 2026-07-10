# frozen_string_literal: true

# Formats a shown word as "{line_number}/{total}:\t{word}". The just-advanced
# counter value equals the 1-based position of the word that was shown.
module Lexdrill::LineFormatter
  def self.format(word)
    total = Lexdrill::WordList.words.size
    line_number = Lexdrill::Counter.new(Lexdrill::WordList::COUNTER_PATH).value
    "#{line_number}/#{total}:\t#{word}"
  end
end
