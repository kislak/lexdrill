# frozen_string_literal: true

RSpec.describe Lexdrill::Inspector do
  around do |example|
    Dir.mktmpdir("lexdrill-inspector-spec") do |dir|
      @dir = dir
      example.run
    end
  end

  before do
    stub_const("Lexdrill::WordList::PATH", File.join(@dir, ".drill.txt"))
    stub_const("Lexdrill::WordList::COUNTER_PATH", File.join(@dir, ".drill.counter"))
    stub_const("Lexdrill::Toggle::PATH", File.join(@dir, ".drill.disabled"))
    Lexdrill::WordList.instance_variable_set(:@words, nil)
  end

  describe ".report" do
    it "reports a missing words file, a zero counter, and enabled by default" do
      report = described_class.report

      expect(report).to include(Lexdrill::WordList::PATH)
      expect(report).to include("missing")
      expect(report).to include("value: 0")
      expect(report).to include("enabled")
    end

    it "reports the word count once the words file exists" do
      File.write(Lexdrill::WordList::PATH, "alpha\nbeta\ngamma\n")

      expect(described_class.report).to include("3 word(s)")
    end

    it "reports the persisted counter value" do
      Lexdrill::Counter.new(Lexdrill::WordList::COUNTER_PATH).increment

      expect(described_class.report).to include("value: 1")
    end

    it "reports stopped, with the toggle marker path, once stopped" do
      Lexdrill::Toggle.stop

      report = described_class.report
      expect(report).to include("stopped")
      expect(report).to include(Lexdrill::Toggle::PATH)
    end

    it "reports LEXDRILL_PATH when set" do
      with_env("LEXDRILL_PATH" => "/tmp/custom-base") do
        expect(described_class.report).to include("/tmp/custom-base")
      end
    end
  end
end
