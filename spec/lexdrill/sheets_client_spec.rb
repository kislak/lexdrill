# frozen_string_literal: true

RSpec.describe Lexdrill::SheetsClient do
  let(:spreadsheet_id) { "abc123" }
  let(:token) { "at1" }

  def response(code, body)
    Lexdrill::HTTPClient::Response.new(code, JSON.generate(body))
  end

  describe ".clear" do
    it "POSTs to the :clear endpoint for the quoted, encoded sheet name" do
      allow(Lexdrill::HTTPClient).to receive(:json_post).and_return(response(200, {}))

      described_class.clear(spreadsheet_id, "Sheet1", token)

      expected_url = "https://sheets.googleapis.com/v4/spreadsheets/abc123/values/%27Sheet1%27:clear"
      expect(Lexdrill::HTTPClient).to have_received(:json_post)
        .with(expected_url, body: {}, headers: { "Authorization" => "Bearer at1" })
    end
  end

  describe ".update" do
    it "PUTs the rows as values with valueInputOption=RAW" do
      allow(Lexdrill::HTTPClient).to receive(:json_put).and_return(response(200, {}))
      rows = [["alpha", 3], ["beta", 1]]

      described_class.update(spreadsheet_id, "Sheet1", rows, token)

      expected_url = "https://sheets.googleapis.com/v4/spreadsheets/abc123/values/%27Sheet1%27?valueInputOption=RAW"
      expected_body = { "range" => "'Sheet1'", "majorDimension" => "ROWS", "values" => rows }
      expect(Lexdrill::HTTPClient).to have_received(:json_put)
        .with(expected_url, body: expected_body, headers: { "Authorization" => "Bearer at1" })
    end
  end

  describe ".read_column" do
    it "returns column A values, ignoring any other columns" do
      allow(Lexdrill::HTTPClient).to receive(:json_get)
        .and_return(response(200, "values" => [%w[alpha 3], %w[beta 1]]))

      words = described_class.read_column(spreadsheet_id, "Sheet1", token)

      expect(words).to eq(%w[alpha beta])
      expected_url = "https://sheets.googleapis.com/v4/spreadsheets/abc123/values/%27Sheet1%27"
      expect(Lexdrill::HTTPClient).to have_received(:json_get)
        .with(expected_url, headers: { "Authorization" => "Bearer at1" })
    end

    it "strips whitespace and skips blank cells" do
      allow(Lexdrill::HTTPClient).to receive(:json_get)
        .and_return(response(200, "values" => [["  alpha  "], [""], [], ["beta"]]))

      expect(described_class.read_column(spreadsheet_id, "Sheet1", token)).to eq(%w[alpha beta])
    end

    it "returns an empty array when the tab has no data" do
      allow(Lexdrill::HTTPClient).to receive(:json_get).and_return(response(200, {}))

      expect(described_class.read_column(spreadsheet_id, "Sheet1", token)).to eq([])
    end
  end

  describe ".overwrite_sheet" do
    def classify_post(url, body)
      return :clear if url.end_with?(":clear")
      return :add_sheet if body.dig("requests", 0, "addSheet")
      return :autofit if body.dig("requests", 0, "autoResizeDimensions")

      :unknown
    end

    it "clears, updates, then auto-fits column A, when the sheet already exists" do
      allow(Lexdrill::HTTPClient).to receive(:json_get)
        .and_return(response(200, "sheets" => [{ "properties" => { "title" => "Sheet1", "sheetId" => 42 } }]))
      calls = []
      allow(Lexdrill::HTTPClient).to receive(:json_post) do |url, body:, **|
        calls << classify_post(url, body)
        response(200, {})
      end
      allow(Lexdrill::HTTPClient).to receive(:json_put) do
        calls << :update
        response(200, {})
      end

      described_class.overwrite_sheet(spreadsheet_id, "Sheet1", [["a"]], token)

      expect(calls).to eq(%i[clear update autofit])
    end

    it "creates the tab first when it doesn't already exist, using the new sheet's id to auto-fit" do
      allow(Lexdrill::HTTPClient).to receive(:json_get)
        .and_return(response(200, "sheets" => [{ "properties" => { "title" => "OtherTab", "sheetId" => 0 } }]))
      calls = []
      allow(Lexdrill::HTTPClient).to receive(:json_post) do |url, body:, **|
        calls << classify_post(url, body)
        if body.dig("requests", 0, "addSheet")
          response(200, "replies" => [{ "addSheet" => { "properties" => { "sheetId" => 99, "title" => "NewTab" } } }])
        else
          response(200, {})
        end
      end
      allow(Lexdrill::HTTPClient).to receive(:json_put) do
        calls << :update
        response(200, {})
      end

      described_class.overwrite_sheet(spreadsheet_id, "NewTab", [["a"]], token)

      expect(calls).to eq(%i[add_sheet clear update autofit])
      expect(Lexdrill::HTTPClient).to have_received(:json_post).with(
        "https://sheets.googleapis.com/v4/spreadsheets/abc123:batchUpdate",
        body: {
          "requests" => [
            {
              "autoResizeDimensions" => {
                "dimensions" => { "sheetId" => 99, "dimension" => "COLUMNS", "startIndex" => 0, "endIndex" => 1 }
              }
            }
          ]
        },
        headers: { "Authorization" => "Bearer at1" }
      )
    end

    it "does not try to create the tab again when it already exists" do
      allow(Lexdrill::HTTPClient).to receive(:json_get)
        .and_return(response(200, "sheets" => [{ "properties" => { "title" => "Sheet1", "sheetId" => 42 } }]))
      post_bodies = []
      allow(Lexdrill::HTTPClient).to receive(:json_post) do |_url, body:, **|
        post_bodies << body
        response(200, {})
      end
      allow(Lexdrill::HTTPClient).to receive(:json_put).and_return(response(200, {}))

      described_class.overwrite_sheet(spreadsheet_id, "Sheet1", [["a"]], token)

      expect(post_bodies.none? { |body| body.dig("requests", 0, "addSheet") }).to be true
    end
  end

  describe "error handling" do
    it "raises ApiError with the status and Google's error message on a non-200 response" do
      allow(Lexdrill::HTTPClient).to receive(:json_post)
        .and_return(response(404, "error" => { "message" => "Requested entity was not found." }))

      expect { described_class.clear(spreadsheet_id, "Sheet1", token) }.to raise_error(
        an_instance_of(described_class::ApiError).and(having_attributes(
                                                        status: 404, message: "Requested entity was not found."
                                                      ))
      )
    end

    it "falls back to a generic HTTP message when the error body isn't JSON" do
      bad_response = Lexdrill::HTTPClient::Response.new(500, "not json")
      allow(Lexdrill::HTTPClient).to receive(:json_post).and_return(bad_response)

      expect { described_class.clear(spreadsheet_id, "Sheet1", token) }.to raise_error(
        an_instance_of(described_class::ApiError).and(having_attributes(status: 500, message: "HTTP 500"))
      )
    end
  end
end
