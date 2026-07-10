# frozen_string_literal: true

module Lexdrill::Config
  FILENAME = ".drill.txt"
  COUNTER_FILENAME = ".drill.counter"

  def self.dir_path
    cwd = Dir.pwd
    cwd if File.exist?(File.join(cwd, FILENAME))
  end

  def self.base_path
    ENV.fetch("LEXDRILL_PATH", nil) || dir_path || Dir.home
  end

  DRILL_PATH = File.join(base_path, FILENAME)
  COUNTER_PATH = File.join(base_path, COUNTER_FILENAME)
end
