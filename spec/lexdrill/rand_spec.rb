# frozen_string_literal: true

RSpec.describe Lexdrill::Rand do
  around do |example|
    Dir.mktmpdir("lexdrill-rand-spec") do |dir|
      @path = File.join(dir, ".drill.rand")
      example.run
    end
  end

  before { stub_const("Lexdrill::Rand::PATH", @path) }

  describe ".value" do
    it "defaults to 1 (every time) when unset" do
      expect(described_class.value).to eq(1)
    end

    it "reflects the persisted value after .set" do
      described_class.set(10)
      expect(described_class.value).to eq(10)
    end

    it "falls back to 1 for a corrupt/non-positive persisted value" do
      File.write(@path, "bogus")
      expect(described_class.value).to eq(1)

      described_class.set(0)
      expect(described_class.value).to eq(1)

      described_class.set(-5)
      expect(described_class.value).to eq(1)
    end
  end

  describe ".skip?" do
    it "never skips at the default (1-in-1)" do
      expect(described_class.skip?).to be false
    end

    it "never skips even if explicitly set to 1" do
      described_class.set(1)
      expect(described_class.skip?).to be false
    end

    it "skips when the random draw is nonzero" do
      described_class.set(5)
      allow(Kernel).to receive(:rand).with(5).and_return(3)

      expect(described_class.skip?).to be true
    end

    it "does not skip when the random draw lands on zero" do
      described_class.set(5)
      allow(Kernel).to receive(:rand).with(5).and_return(0)

      expect(described_class.skip?).to be false
    end
  end
end
