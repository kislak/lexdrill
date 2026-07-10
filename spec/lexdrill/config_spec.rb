# frozen_string_literal: true

RSpec.describe Lexdrill::Config do
  around do |example|
    Dir.mktmpdir("lexdrill-config-cwd") do |cwd|
      @cwd = File.realpath(cwd)
      Dir.chdir(@cwd) { with_env("LEXDRILL_PATH" => nil) { example.run } }
    end
  end

  describe ".dir_path" do
    it "returns the current directory when it has .drill.txt" do
      File.write(File.join(@cwd, ".drill.txt"), "a\n")
      expect(described_class.dir_path).to eq(@cwd)
    end

    it "returns nil when the current directory has no .drill.txt" do
      expect(described_class.dir_path).to be_nil
    end
  end

  describe ".base_path" do
    it "uses LEXDRILL_PATH when set, regardless of the current directory" do
      File.write(File.join(@cwd, ".drill.txt"), "a\n")
      with_env("LEXDRILL_PATH" => "/tmp/custom-base") do
        expect(described_class.base_path).to eq("/tmp/custom-base")
      end
    end

    it "prefers the current directory over $HOME when it has .drill.txt" do
      File.write(File.join(@cwd, ".drill.txt"), "a\n")
      expect(described_class.base_path).to eq(@cwd)
    end

    # DEFAULT_PATH is a constant fixed to the real Dir.home at load time, so
    # this deliberately checks against the real $HOME rather than faking it.
    it "falls back to $HOME when the current directory has none and LEXDRILL_PATH is unset" do
      expect(described_class.base_path).to eq(Dir.home)
    end
  end
end
