# frozen_string_literal: true

require "fileutils"

# Global pause/resume switch for the shell hook. Enabled by default; the
# marker file's presence means stopped.
module Lexdrill::Toggle
  PATH = Lexdrill::Config.path("disabled")

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
