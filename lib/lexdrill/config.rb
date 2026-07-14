# frozen_string_literal: true

require "fileutils"

# All of lexdrill's persisted state lives under this one directory in the
# user's home folder — a single global config, with no per-project or
# per-directory overrides.
module Lexdrill::Config
  DIR = File.join(Dir.home, ".drill")

  # 0700: this directory can hold real secrets (OAuth refresh token, service
  # account key), same reasoning as their own individual 0600 chmods.
  FileUtils.mkdir_p(DIR, mode: 0o700)

  def self.path(filename)
    File.join(DIR, filename)
  end
end
