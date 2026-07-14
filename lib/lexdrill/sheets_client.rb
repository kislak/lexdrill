# frozen_string_literal: true

require "uri"
require "json"

# Thin wrapper around the Google Sheets API v4 REST endpoints needed by
# `drill export`/`drill import`: create the target tab if it doesn't already
# exist, clear its contents, write new rows into it, then auto-fit column
# A's width to the content so long phrases aren't visually truncated; or,
# for import, read column A back out of an existing tab.
module Lexdrill::SheetsClient
  BASE_URL = "https://sheets.googleapis.com/v4/spreadsheets"

  class ApiError < StandardError
    attr_reader :status

    def initialize(status, message)
      @status = status
      super(message)
    end
  end

  def self.overwrite_sheet(spreadsheet_id, sheet_name, rows, access_token)
    sheet_id = ensure_sheet_exists(spreadsheet_id, sheet_name, access_token)
    clear(spreadsheet_id, sheet_name, access_token)
    update(spreadsheet_id, sheet_name, rows, access_token)
    autofit_first_column(spreadsheet_id, sheet_id, access_token)
  end

  def self.ensure_sheet_exists(spreadsheet_id, sheet_name, access_token)
    existing = find_sheet(spreadsheet_id, sheet_name, access_token)
    return existing["sheetId"] if existing

    add_sheet(spreadsheet_id, sheet_name, access_token)
  end
  private_class_method :ensure_sheet_exists

  def self.find_sheet(spreadsheet_id, sheet_name, access_token)
    url = "#{BASE_URL}/#{spreadsheet_id}?fields=sheets.properties"
    data = handle_response(Lexdrill::HTTPClient.json_get(url, headers: auth_header(access_token)))
    data.fetch("sheets", []).map { |sheet| sheet["properties"] }.find { |props| props["title"] == sheet_name }
  end
  private_class_method :find_sheet

  def self.add_sheet(spreadsheet_id, sheet_name, access_token)
    url = "#{BASE_URL}/#{spreadsheet_id}:batchUpdate"
    body = { "requests" => [{ "addSheet" => { "properties" => { "title" => sheet_name } } }] }
    result = handle_response(Lexdrill::HTTPClient.json_post(url, body: body, headers: auth_header(access_token)))
    result.dig("replies", 0, "addSheet", "properties", "sheetId")
  end
  private_class_method :add_sheet

  def self.autofit_first_column(spreadsheet_id, sheet_id, access_token)
    url = "#{BASE_URL}/#{spreadsheet_id}:batchUpdate"
    dimensions = { "sheetId" => sheet_id, "dimension" => "COLUMNS", "startIndex" => 0, "endIndex" => 1 }
    body = { "requests" => [{ "autoResizeDimensions" => { "dimensions" => dimensions } }] }
    handle_response(Lexdrill::HTTPClient.json_post(url, body: body, headers: auth_header(access_token)))
  end
  private_class_method :autofit_first_column

  def self.clear(spreadsheet_id, sheet_name, access_token)
    url = "#{BASE_URL}/#{spreadsheet_id}/values/#{encoded_range(sheet_name)}:clear"
    handle_response(Lexdrill::HTTPClient.json_post(url, body: {}, headers: auth_header(access_token)))
  end

  def self.update(spreadsheet_id, sheet_name, rows, access_token)
    url = "#{BASE_URL}/#{spreadsheet_id}/values/#{encoded_range(sheet_name)}?valueInputOption=RAW"
    body = { "range" => quoted_range(sheet_name), "majorDimension" => "ROWS", "values" => rows }
    handle_response(Lexdrill::HTTPClient.json_put(url, body: body, headers: auth_header(access_token)))
  end

  # Reads column A back out of an existing tab (ignoring any other
  # columns, e.g. show counts from an older export), skipping blank cells.
  def self.read_column(spreadsheet_id, sheet_name, access_token)
    url = "#{BASE_URL}/#{spreadsheet_id}/values/#{encoded_range(sheet_name)}"
    data = handle_response(Lexdrill::HTTPClient.json_get(url, headers: auth_header(access_token)))
    data.fetch("values", []).filter_map { |row| row[0]&.strip }.reject(&:empty?)
  end

  # The titles of every tab in the workbook, for `drill sheets`.
  def self.sheet_titles(spreadsheet_id, access_token)
    url = "#{BASE_URL}/#{spreadsheet_id}?fields=sheets.properties.title"
    data = handle_response(Lexdrill::HTTPClient.json_get(url, headers: auth_header(access_token)))
    data.fetch("sheets", []).map { |sheet| sheet.dig("properties", "title") }
  end

  def self.auth_header(token)
    { "Authorization" => "Bearer #{token}" }
  end
  private_class_method :auth_header

  # Quoting the sheet name defends against tab names containing spaces;
  # harmless for plain names too. The URL path and the request body's
  # "range" field must match exactly (Google rejects the request otherwise),
  # so both go through this same quoting.
  def self.quoted_range(sheet_name)
    "'#{sheet_name}'"
  end
  private_class_method :quoted_range

  def self.encoded_range(sheet_name)
    URI.encode_www_form_component(quoted_range(sheet_name))
  end
  private_class_method :encoded_range

  def self.handle_response(response)
    status = response.code
    return JSON.parse(response.body) if status == 200

    raise ApiError.new(status, error_message(response))
  end
  private_class_method :handle_response

  def self.error_message(response)
    status = response.code
    JSON.parse(response.body).dig("error", "message") || "HTTP #{status}"
  rescue JSON::ParserError
    "HTTP #{status}"
  end
  private_class_method :error_message
end
