# frozen_string_literal: true

RSpec.describe Lexdrill::Beat do
  around do |example|
    Dir.mktmpdir("lexdrill-beat-spec") do |dir|
      @path = File.join(dir, ".drill.beat")
      example.run
    end
  end

  before { stub_const("Lexdrill::Beat::PATH", @path) }

  describe ".configured?" do
    it "is false until .set is called" do
      expect(described_class.configured?).to be false
    end

    it "is true after .set, and false again after .clear" do
      described_class.set(3, 2)
      expect(described_class.configured?).to be true

      described_class.clear
      expect(described_class.configured?).to be false
    end
  end

  describe ".loop_size and .repetitions" do
    it "round-trip the persisted values" do
      described_class.set(4, 5)
      expect(described_class.loop_size).to eq(4)
      expect(described_class.repetitions).to eq(5)
    end
  end

  describe ".valid_loop_size?" do
    it "accepts 2 through 8" do
      (2..8).each { |n| expect(described_class.valid_loop_size?(n)).to be true }
    end

    it "rejects anything outside 2..8" do
      expect(described_class.valid_loop_size?(1)).to be false
      expect(described_class.valid_loop_size?(9)).to be false
    end
  end

  describe ".cycle_length" do
    it "is just the word count when not configured" do
      expect(described_class.cycle_length(6)).to eq(6)
    end

    it "is loop_size * repetitions per full chunk, summed across all chunks" do
      described_class.set(3, 2)
      # 6 words, loop_size 3 -> two full chunks of 3, each shown 2x = 3*2 + 3*2
      expect(described_class.cycle_length(6)).to eq(12)
    end

    it "accounts for a shorter final chunk" do
      described_class.set(3, 2)
      # 7 words, loop_size 3 -> chunks of [3, 3, 1] -> 3*2 + 3*2 + 1*2
      expect(described_class.cycle_length(7)).to eq(14)
    end
  end

  describe ".index_for" do
    it "returns the step unchanged when not configured" do
      expect(described_class.index_for(6, 4)).to eq(4)
    end

    it "repeats each loop_size-word chunk repetitions times before advancing" do
      described_class.set(3, 2)
      # word list [a,b,c,d,e,f] (indices 0..5) -> a,b,c,a,b,c,d,e,f,d,e,f
      expected_indexes = [0, 1, 2, 0, 1, 2, 3, 4, 5, 3, 4, 5]
      actual_indexes = (0...12).map { |step| described_class.index_for(6, step) }
      expect(actual_indexes).to eq(expected_indexes)
    end

    it "cycles the final short chunk using its own (smaller) size" do
      described_class.set(3, 2)
      # word list of 7: chunks [0,1,2] [3,4,5] [6] -> ...,6,6 (repeats index 6 twice)
      steps = (12...14)
      expect(steps.map { |step| described_class.index_for(7, step) }).to eq([6, 6])
    end
  end
end
