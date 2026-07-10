# frozen_string_literal: true

RSpec.describe Lexdrill::Stats do
  around do |example|
    Dir.mktmpdir("lexdrill-stats-spec") do |dir|
      @path = File.join(dir, ".drill.stats")
      example.run
    end
  end

  before { stub_const("Lexdrill::Stats::PATH", @path) }

  describe ".counts" do
    it "is empty when no stats file exists yet" do
      expect(described_class.counts).to eq({})
    end

    it "falls back to empty for a corrupt stats file" do
      File.write(@path, "not json")
      expect(described_class.counts).to eq({})
    end
  end

  describe ".record" do
    it "starts a word at 1 the first time it's shown" do
      described_class.record("alpha")
      expect(described_class.counts).to eq("alpha" => 1)
    end

    it "increments the count on repeated shows" do
      3.times { described_class.record("alpha") }
      expect(described_class.counts).to eq("alpha" => 3)
    end

    it "tracks multiple words independently" do
      described_class.record("alpha")
      2.times { described_class.record("beta") }
      expect(described_class.counts).to eq("alpha" => 1, "beta" => 2)
    end

    it "persists across separate loads" do
      described_class.record("alpha")
      expect(JSON.parse(File.read(@path))).to eq("alpha" => 1)
    end
  end
end
