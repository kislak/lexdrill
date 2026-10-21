# frozen_string_literal: true

RSpec.describe Lexdrill::Toggle do
  around do |example|
    Dir.mktmpdir("lexdrill-toggle-spec") do |dir|
      @dir = dir
      @path = File.join(dir, "disabled")
      example.run
    end
  end

  before do
    stub_const("Lexdrill::Toggle::PATH", @path)
  end

  describe ".enabled?" do
    it "is true by default, before start/stop are ever called" do
      expect(described_class.enabled?).to be true
    end

    it "is false after .stop" do
      described_class.stop
      expect(described_class.enabled?).to be false
    end

    it "is true again after .start undoes a previous .stop" do
      described_class.stop
      described_class.start
      expect(described_class.enabled?).to be true
    end
  end

  describe ".start" do
    it "is a no-op when already enabled" do
      expect { described_class.start }.not_to raise_error
      expect(described_class.enabled?).to be true
    end
  end

  describe "legacy ~/.drill.disabled support" do
    let(:legacy_path) { File.join(@dir, "legacy.disabled") }

    before do
      stub_const("Lexdrill::Toggle::LEGACY_PATH", legacy_path)
    end

    it "is false when the legacy marker file exists" do
      File.write(legacy_path, "")
      expect(described_class.enabled?).to be false
    end

    it "creates and removes both marker files on stop and start" do
      described_class.stop
      expect(File.exist?(@path)).to be true
      expect(File.exist?(legacy_path)).to be true
      expect(described_class.enabled?).to be false

      described_class.start
      expect(File.exist?(@path)).to be false
      expect(File.exist?(legacy_path)).to be false
      expect(described_class.enabled?).to be true
    end
  end
end
