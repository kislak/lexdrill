# frozen_string_literal: true

require "json"

# Tracks how many times each word/phrase has been shown by `next`, persisted
# as a word => count JSON object at `.drill.stats` (same base path as
# `.drill.txt`/`.drill.counter`). Every BUCKET_SIZE shows moves a word into
# the next display-color bucket (see Lexdrill::Colorizer); once a word
# reaches GRADUATION_THRESHOLD shows it's considered mastered and `next`
# stops selecting it.
module Lexdrill::Stats
  PATH = Lexdrill::Config::STATS_PATH
  BUCKET_SIZE = 100
  GRADUATION_THRESHOLD = 1200

  def self.record(word)
    data = load
    data[word] = data.fetch(word, 0) + 1
    save(data)
  end

  def self.counts
    load
  end

  def self.graduated?(word)
    counts.fetch(word, 0) >= GRADUATION_THRESHOLD
  end

  def self.load
    return {} unless File.exist?(PATH)

    JSON.parse(File.read(PATH, encoding: "UTF-8"))
  rescue JSON::ParserError
    {}
  end
  private_class_method :load

  def self.save(data)
    File.write(PATH, JSON.generate(data), encoding: "UTF-8")
  end
  private_class_method :save
end
