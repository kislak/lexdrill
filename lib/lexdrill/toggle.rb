# frozen_string_literal: true

require "fileutils"

# Global pause/resume switch for the shell hook. Enabled by default; the
# marker file's presence means stopped.
module Lexdrill::Toggle
  PATH = Lexdrill::Config.path("disabled")
  LEGACY_PATH = File.join(Dir.home, ".drill.disabled")

  def self.enabled?
    return false if File.exist?(PATH)
    return false if use_legacy? && File.exist?(LEGACY_PATH)

    true
  end

  def self.start
    FileUtils.rm_f(PATH)
    FileUtils.rm_f(LEGACY_PATH) if use_legacy?
  end

  def self.stop
    File.write(PATH, "")
    File.write(LEGACY_PATH, "") if use_legacy?
  end

  def self.use_legacy?
    File.join(Dir.home, ".drill.disabled") != LEGACY_PATH || Lexdrill::Config.path("disabled") == PATH
  end
  private_class_method :use_legacy?
end
