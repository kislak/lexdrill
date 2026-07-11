# frozen_string_literal: true

RSpec.describe Lexdrill::Remote do
  around do |example|
    Dir.mktmpdir("lexdrill-remote-spec") do |dir|
      @path = File.join(dir, ".drill.remote")
      example.run
    end
  end

  before { stub_const("Lexdrill::Remote::PATH", @path) }

  describe ".extract_id" do
    it "parses the spreadsheet id out of a normal share URL" do
      url = "https://docs.google.com/spreadsheets/d/1opBP4APL5SUvepm9qwjIYRNtDZdoY1Ee87F5PWdxaMg/edit?usp=sharing"
      expect(described_class.extract_id(url)).to eq("1opBP4APL5SUvepm9qwjIYRNtDZdoY1Ee87F5PWdxaMg")
    end

    it "parses the id regardless of trailing query/fragment" do
      url = "https://docs.google.com/spreadsheets/d/abcXYZ123-_/edit?gid=0#gid=0"
      expect(described_class.extract_id(url)).to eq("abcXYZ123-_")
    end

    it "returns nil for a URL with no spreadsheet id" do
      expect(described_class.extract_id("https://example.com/not-a-sheet")).to be_nil
    end
  end

  describe ".set" do
    it "persists the extracted id" do
      described_class.set("https://docs.google.com/spreadsheets/d/abc123/edit")
      expect(described_class.spreadsheet_id).to eq("abc123")
    end

    it "raises ArgumentError for a URL with no spreadsheet id" do
      expect { described_class.set("https://example.com/nope") }.to raise_error(ArgumentError, /no spreadsheet id/)
    end
  end

  describe ".configured?" do
    it "is false until .set is called" do
      expect(described_class.configured?).to be false
    end

    it "is true after .set" do
      described_class.set("https://docs.google.com/spreadsheets/d/abc123/edit")
      expect(described_class.configured?).to be true
    end
  end

  describe ".spreadsheet_id" do
    it "is nil when unset" do
      expect(described_class.spreadsheet_id).to be_nil
    end
  end
end
