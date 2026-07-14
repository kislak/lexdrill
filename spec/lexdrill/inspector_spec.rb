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
    stub_const("Lexdrill::Stats::PATH", File.join(@dir, ".drill.stats"))
    stub_const("Lexdrill::Toggle::PATH", File.join(@dir, ".drill.disabled"))
    stub_const("Lexdrill::Rand::PATH", File.join(@dir, ".drill.rand"))
    stub_const("Lexdrill::Beat::PATH", File.join(@dir, ".drill.beat"))
    stub_const("Lexdrill::Color::PATH", File.join(@dir, ".drill.color"))
    stub_const("Lexdrill::Remote::PATH", File.join(@dir, ".drill.remote"))
    stub_const("Lexdrill::OauthRemote::PATH", File.join(@dir, ".drill.oauth-remote"))
    Lexdrill::WordList.instance_variable_set(:@words, nil)
  end

  describe ".report" do
    it "reports a missing words file, a zero counter, and enabled by default" do
      report = described_class.report

      expect(report).to include(Lexdrill::WordList::PATH)
      expect(report).to include("missing")
      expect(report).to include("value: 0")
      expect(report).to include("enabled")
      expect(report).to include("no data yet")
      expect(report).to include("every time (default)")
    end

    it "reports the approximate frequency once rand is configured" do
      Lexdrill::Rand.set(10)

      expect(described_class.report).to include("approximately 1-in-10")
    end

    it "reports the tracked item count once stats exist" do
      Lexdrill::Stats.record("alpha")

      expect(described_class.report).to include("1 item(s) tracked")
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

    it "reports the beat as random when beat rand is set" do
      Lexdrill::Beat.set_rand

      expect(described_class.report).to include("random (ignores rhythm/counter)")
    end

    it "reports the color mode as default by default" do
      expect(described_class.report).to include("Color:         default")
    end

    it "reports the color mode once set to random" do
      Lexdrill::Color.set("random")

      expect(described_class.report).to include("Color:         random")
    end

    it "reports not configured when no remote is set" do
      expect(described_class.report).to include("Remote:        not configured")
    end

    it "reports the active spreadsheet URL once a remote is configured" do
      Lexdrill::Remote.set("https://docs.google.com/spreadsheets/d/abc123/edit")

      expect(described_class.report).to include("Remote:        https://docs.google.com/spreadsheets/d/abc123/edit")
    end

    it "reports the config directory" do
      expect(described_class.report).to include("Config dir:    #{Lexdrill::Config::DIR}")
    end
  end
end
