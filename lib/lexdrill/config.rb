# frozen_string_literal: true

module Lexdrill::Config
  FILENAME = ".drill.txt"
  COUNTER_FILENAME = ".drill.counter"
  STATS_FILENAME = ".drill.stats"

  def self.dir_path
    cwd = Dir.pwd
    cwd if File.exist?(File.join(cwd, FILENAME))
  end

  def self.base_path
    ENV.fetch("LEXDRILL_PATH", nil) || dir_path || Dir.home
  end

  def self.home_drill_path
    File.join(Dir.home, FILENAME)
  end

  DRILL_PATH = File.join(base_path, FILENAME)
  COUNTER_PATH = File.join(base_path, COUNTER_FILENAME)
  STATS_PATH = File.join(base_path, STATS_FILENAME)
end
