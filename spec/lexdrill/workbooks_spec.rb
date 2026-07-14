# frozen_string_literal: true

RSpec.describe Lexdrill::Workbooks do
  around do |example|
    Dir.mktmpdir("lexdrill-workbooks-spec") do |dir|
      @path = File.join(dir, ".drill.workbooks.json")
      example.run
    end
  end

  before { stub_const("Lexdrill::Workbooks::PATH", @path) }

  describe ".extract_id" do
    it "parses the spreadsheet id out of a normal share URL" do
      url = "https://docs.google.com/spreadsheets/d/1opBP4APL5SUvepm9qwjIYRNtDZdoY1Ee87F5PWdxaMg/edit?usp=sharing"
      expect(described_class.extract_id(url)).to eq("1opBP4APL5SUvepm9qwjIYRNtDZdoY1Ee87F5PWdxaMg")
    end

    it "returns nil for a URL with no spreadsheet id" do
      expect(described_class.extract_id("https://example.com/not-a-sheet")).to be_nil
    end
  end

  describe "adding, listing, using, and removing" do
    it "starts empty, with no current workbook" do
      expect(described_class.names).to eq([])
      expect(described_class.current_name).to be_nil
      expect(described_class.current_id).to be_nil
    end

    it "makes the first added workbook current automatically" do
      described_class.add("NLP", "abc123")

      expect(described_class.names).to eq(["NLP"])
      expect(described_class.current_name).to eq("NLP")
      expect(described_class.current_id).to eq("abc123")
      expect(described_class.url_for("NLP")).to eq("https://docs.google.com/spreadsheets/d/abc123/edit")
    end

    it "does not switch current when a second workbook is added" do
      described_class.add("NLP", "abc123")
      described_class.add("gcp", "def456")

      expect(described_class.names).to eq(%w[NLP gcp])
      expect(described_class.current_name).to eq("NLP")
    end

    it "switches current via .use" do
      described_class.add("NLP", "abc123")
      described_class.add("gcp", "def456")

      expect(described_class.use("gcp")).to be true
      expect(described_class.current_name).to eq("gcp")
      expect(described_class.current_id).to eq("def456")
    end

    it ".use returns false for an unknown name, without changing current" do
      described_class.add("NLP", "abc123")

      expect(described_class.use("nope")).to be false
      expect(described_class.current_name).to eq("NLP")
    end

    it "removes a workbook, clearing current if it was the active one" do
      described_class.add("NLP", "abc123")

      expect(described_class.remove("NLP")).to be true
      expect(described_class.names).to eq([])
      expect(described_class.current_name).to be_nil
    end

    it "removing a non-current workbook leaves current untouched" do
      described_class.add("NLP", "abc123")
      described_class.add("gcp", "def456")

      expect(described_class.remove("gcp")).to be true
      expect(described_class.current_name).to eq("NLP")
    end

    it ".remove returns false for an unknown name" do
      expect(described_class.remove("nope")).to be false
    end
  end

  describe "current sheet tracking" do
    it "is nil before any workbook is added" do
      expect(described_class.current_sheet).to be_nil
      expect(described_class.current_sheet_id).to be_nil
    end

    it "sets and reports the current sheet for the active workbook" do
      described_class.add("NLP", "abc123")

      expect(described_class.set_current_sheet("Sheet1", 42)).to be true
      expect(described_class.current_sheet).to eq("Sheet1")
      expect(described_class.current_sheet_id).to eq(42)
    end

    it "tracks sheet selection independently per workbook" do
      described_class.add("NLP", "abc123")
      described_class.set_current_sheet("Sheet1", 0)
      described_class.add("gcp", "def456")
      described_class.use("gcp")

      expect(described_class.current_sheet).to be_nil

      described_class.set_current_sheet("Tab2", 7)
      described_class.use("NLP")

      expect(described_class.current_sheet).to eq("Sheet1")
    end

    it "returns false when there is no current workbook" do
      expect(described_class.set_current_sheet("Sheet1", 0)).to be false
    end
  end
end
