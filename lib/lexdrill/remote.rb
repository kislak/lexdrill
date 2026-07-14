# frozen_string_literal: true

# Global "which Google Sheet to export to via a service account" setting.
# Stored as a plain spreadsheet id, parsed out of a normal Google Sheets
# share URL. Set via `drill remote <url>` — the user shares that
# spreadsheet with their service account's email directly in Google
# Sheets, so no interactive Google sign-in is needed at export/import time.
# See Lexdrill::OauthRemote for the separate, personal-login-based flow.
module Lexdrill::Remote
  PATH = Lexdrill::Config.path("remote")
  URL_PATTERN = %r{/spreadsheets/d/([a-zA-Z0-9_-]+)}

  def self.set(url)
    id = extract_id(url)
    raise ArgumentError, "no spreadsheet id found in #{url.inspect}" unless id

    File.write(PATH, id)
  end

  def self.extract_id(url)
    url[URL_PATTERN, 1]
  end

  def self.configured?
    File.exist?(PATH)
  end

  def self.spreadsheet_id
    File.read(PATH).strip if configured?
  end
end
