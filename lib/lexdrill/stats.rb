# frozen_string_literal: true

require "json"

# Tracks how many times each word/phrase has been shown by `next`, persisted
# as a word => count JSON object at `.drill.stats` (same base path as
# `.drill.txt`/`.drill.counter`).
module Lexdrill::Stats
  PATH = Lexdrill::Config::STATS_PATH

  def self.record(word)
    data = load
    data[word] = data.fetch(word, 0) + 1
    save(data)
  end

  def self.counts
    load
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
