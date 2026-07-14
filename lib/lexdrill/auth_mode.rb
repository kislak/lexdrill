# frozen_string_literal: true

# Global "how to authenticate to Google Sheets" choice: "remote" (service
# account, no interactive sign-in) or "oauth" (personal Google login).
# Independent of which workbook is active — see Lexdrill::Workbooks for
# that. Set via `drill remote` / `drill oauth` (no arguments).
module Lexdrill::AuthMode
  PATH = Lexdrill::Config.path("auth-mode")
  REMOTE = "remote"
  OAUTH = "oauth"
  VALID = [REMOTE, OAUTH].freeze

  def self.set(mode)
    File.write(PATH, mode)
  end

  def self.current
    return nil unless File.exist?(PATH)

    value = File.read(PATH).strip
    VALID.include?(value) ? value : nil
  end
end
