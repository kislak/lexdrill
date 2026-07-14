# frozen_string_literal: true

RSpec.describe Lexdrill::Color do
  around do |example|
    Dir.mktmpdir("lexdrill-color-spec") do |dir|
      @path = File.join(dir, ".drill.color")
      example.run
    end
  end

  before { stub_const("Lexdrill::Color::PATH", @path) }

  describe ".current" do
    it "defaults to default" do
      expect(described_class.current).to eq("default")
    end

    it "reflects the persisted mode after .set" do
      described_class.set("random")
      expect(described_class.current).to eq("random")
    end

    it "falls back to default for a corrupt/unknown value" do
      File.write(@path, "bogus")
      expect(described_class.current).to eq("default")
    end
  end

  describe ".random?" do
    it "is false by default" do
      expect(described_class.random?).to be false
    end

    it "is true once set to random" do
      described_class.set("random")
      expect(described_class.random?).to be true
    end
  end
end
