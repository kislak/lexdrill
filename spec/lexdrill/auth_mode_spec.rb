# frozen_string_literal: true

RSpec.describe Lexdrill::AuthMode do
  around do |example|
    Dir.mktmpdir("lexdrill-auth-mode-spec") do |dir|
      @path = File.join(dir, ".drill.auth-mode")
      example.run
    end
  end

  before { stub_const("Lexdrill::AuthMode::PATH", @path) }

  describe ".current" do
    it "is nil when never set" do
      expect(described_class.current).to be_nil
    end

    it "reflects the persisted mode after .set" do
      described_class.set("remote")
      expect(described_class.current).to eq("remote")
    end

    it "is nil for a corrupt/unknown value" do
      File.write(@path, "bogus")
      expect(described_class.current).to be_nil
    end
  end
end
