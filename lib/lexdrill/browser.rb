# frozen_string_literal: true

require "rbconfig"

# Opens a URL in the system's default browser, cross-platform, for
# `drill open`.
module Lexdrill::Browser
  def self.open(url)
    system(*open_command(url), out: File::NULL, err: File::NULL)
  end

  def self.open_command(url)
    case RbConfig::CONFIG["host_os"]
    when /darwin/ then ["open", url]
    when /mswin|mingw|cygwin/ then ["cmd", "/c", "start", "", url]
    else ["xdg-open", url]
    end
  end
  private_class_method :open_command
end
