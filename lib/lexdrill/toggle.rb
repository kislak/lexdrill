# frozen_string_literal: true

require "fileutils"

# Global pause/resume switch for the shell hook, independent of which
# project's .drill.txt is active. Enabled by default; the marker file's
# presence means stopped.
module Lexdrill::Toggle
  PATH = File.join(Dir.home, ".drill.disabled")

  def self.enabled?
    !File.exist?(PATH)
  end

  def self.start
    FileUtils.rm_f(PATH)
  end

  def self.stop
    File.write(PATH, "")
  end
end
