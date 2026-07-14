# frozen_string_literal: true

RSpec.describe Lexdrill::Config do
  describe ".path" do
    it "joins the given filename onto the config directory" do
      expect(described_class.path("words")).to eq(File.join(described_class::DIR, "words"))
    end
  end

  describe "DIR" do
    it "is a .drill directory under the home folder" do
      expect(described_class::DIR).to eq(File.join(Dir.home, ".drill"))
    end

    it "exists on disk" do
      expect(File.directory?(described_class::DIR)).to be true
    end
  end
end
