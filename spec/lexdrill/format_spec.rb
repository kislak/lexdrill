# frozen_string_literal: true

RSpec.describe Lexdrill::Format do
  around do |example|
    Dir.mktmpdir("lexdrill-format-spec") do |dir|
      @path = File.join(dir, ".drill.format")
      example.run
    end
  end

  before { stub_const("Lexdrill::Format::PATH", @path) }

  describe ".current" do
    it "defaults to full" do
      expect(described_class.current).to eq("full")
    end

    it "reflects the persisted mode after .set" do
      described_class.set("simple")
      expect(described_class.current).to eq("simple")
    end

    it "falls back to full for a corrupt/unknown value" do
      File.write(@path, "bogus")
      expect(described_class.current).to eq("full")
    end
  end

  describe ".simple?" do
    it "is false by default" do
      expect(described_class.simple?).to be false
    end

    it "is true once set to simple" do
      described_class.set("simple")
      expect(described_class.simple?).to be true
    end
  end
end
