# frozen_string_literal: true

require "json"

# Global list of known Google Sheets workbooks (name => spreadsheet id),
# which one is currently active, and — per workbook — which tab is
# currently active within it. Lives at ~/.drill/workbooks.json. Names are
# the spreadsheet's own title (see `drill wb add`), not chosen by hand.
module Lexdrill::Workbooks
  PATH = Lexdrill::Config.path("workbooks.json")
  URL_PATTERN = %r{/spreadsheets/d/([a-zA-Z0-9_-]+)}

  def self.extract_id(url)
    url[URL_PATTERN, 1]
  end

  def self.names
    load.fetch("workbooks").keys
  end

  def self.add(name, spreadsheet_id)
    data = load
    data["workbooks"][name] = { "id" => spreadsheet_id }
    data["current"] ||= name
    save(data)
  end

  def self.remove(name)
    data = load
    return false unless data["workbooks"].delete(name)

    data["current"] = nil if data["current"] == name
    save(data)
    true
  end

  def self.use(name)
    data = load
    return false unless data["workbooks"].key?(name)

    data["current"] = name
    save(data)
    true
  end

  def self.current_name
    load["current"]
  end

  def self.current_id
    current_entry&.fetch("id")
  end

  def self.url_for(name)
    entry = load.fetch("workbooks")[name]
    entry && "https://docs.google.com/spreadsheets/d/#{entry.fetch('id')}/edit"
  end

  def self.current_url
    name = current_name
    name && url_for(name)
  end

  def self.set_current_sheet(sheet_name, sheet_id)
    data = load
    workbooks = data["workbooks"]
    name = data["current"]
    return false unless name && workbooks.key?(name)

    entry = workbooks[name]
    entry["current_sheet"] = sheet_name
    entry["current_sheet_id"] = sheet_id
    save(data)
    true
  end

  def self.current_sheet
    current_entry&.[]("current_sheet")
  end

  def self.current_sheet_id
    current_entry&.[]("current_sheet_id")
  end

  def self.current_entry
    name = current_name
    name && load.fetch("workbooks")[name]
  end
  private_class_method :current_entry

  def self.load
    return { "current" => nil, "workbooks" => {} } unless File.exist?(PATH)

    data = JSON.parse(File.read(PATH, encoding: "UTF-8"))
    data["workbooks"] ||= {}
    data
  rescue JSON::ParserError
    { "current" => nil, "workbooks" => {} }
  end
  private_class_method :load

  def self.save(data)
    File.write(PATH, JSON.generate(data), encoding: "UTF-8")
  end
  private_class_method :save
end
