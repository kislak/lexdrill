# frozen_string_literal: true

RSpec.describe Lexdrill::Toggle do
  around do |example|
    Dir.mktmpdir("lexdrill-toggle-spec") do |dir|
      @path = File.join(dir, ".drill.disabled")
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
end
