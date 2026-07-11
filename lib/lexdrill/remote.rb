# frozen_string_literal: true

# Global "which Google Sheet to export to" setting. Lives at ~/.drill.remote
# as a plain spreadsheet id, parsed out of a normal Google Sheets share URL.
module Lexdrill::Remote
  PATH = File.join(Dir.home, ".drill.remote")
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
