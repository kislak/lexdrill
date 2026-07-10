# frozen_string_literal: true

RSpec.describe Lexdrill::Counter do
  around do |example|
    Dir.mktmpdir("lexdrill-counter-spec") do |dir|
      @path = File.join(dir, ".drill.counter")
      example.run
    end
  end

  describe "#value" do
    it "is 0 when the config file does not exist" do
      expect(described_class.new(@path).value).to eq(0)
    end

    it "reads the persisted integer" do
      File.write(@path, "5")
      expect(described_class.new(@path).value).to eq(5)
    end

    it "is 0 for a blank or non-numeric file" do
      File.write(@path, "not-a-number")
      expect(described_class.new(@path).value).to eq(0)
    end
  end

  describe "#increment" do
    it "persists the value plus 1, readable by a fresh instance" do
      counter = described_class.new(@path)
      counter.increment
      expect(described_class.new(@path).value).to eq(1)

      counter.increment
      expect(described_class.new(@path).value).to eq(2)
    end
  end

  describe "#set" do
    it "persists the given value directly, readable by a fresh instance" do
      described_class.new(@path).set(7)
      expect(described_class.new(@path).value).to eq(7)
    end

    it "overwrites whatever was there before" do
      counter = described_class.new(@path)
      counter.increment
      counter.increment
      counter.set(3)
      expect(described_class.new(@path).value).to eq(3)
    end
  end
end
