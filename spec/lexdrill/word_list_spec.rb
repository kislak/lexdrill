# frozen_string_literal: true

RSpec.describe Lexdrill::WordList do
  around do |example|
    Dir.mktmpdir("lexdrill-word-list-spec") do |dir|
      @dir = dir
      example.run
    end
  end

  before do
    stub_const("Lexdrill::WordList::PATH", File.join(@dir, ".drill.txt"))
    stub_const("Lexdrill::WordList::COUNTER_PATH", File.join(@dir, ".drill.counter"))
    # Isolate from any real ~/.drill.beat so .next exercises plain (unconfigured) rhythm.
    stub_const("Lexdrill::Beat::PATH", File.join(@dir, ".drill.beat"))
    stub_const("Lexdrill::Stats::PATH", File.join(@dir, ".drill.stats"))
    # .words memoizes into a class-level ivar; reset it so each example starts
    # fresh instead of seeing a previous example's cached word list.
    described_class.instance_variable_set(:@words, nil)
  end

  def write_words(contents)
    File.write(described_class::PATH, contents)
  end

  def counter_value
    Lexdrill::Counter.new(described_class::COUNTER_PATH).value
  end

  describe ".words" do
    it "reads one word per line" do
      write_words("hello\nworld\n")
      expect(described_class.words).to eq(%w[hello world])
    end

    it "strips surrounding whitespace" do
      write_words("  hello  \n\tworld\t\n")
      expect(described_class.words).to eq(%w[hello world])
    end

    it "skips blank lines" do
      write_words("hello\n\n\nworld\n")
      expect(described_class.words).to eq(%w[hello world])
    end

    it "returns an empty list for an empty file" do
      write_words("")
      expect(described_class.words).to eq([])
    end

    it "returns an empty list when the file does not exist" do
      expect(described_class.words).to eq([])
    end

    it "seeds the default starter list when PATH is the ~/.drill.txt fallback and it's missing" do
      home_path = File.join(@dir, ".drill.txt")
      stub_const("Lexdrill::WordList::PATH", home_path)
      stub_const("Lexdrill::WordList::HOME_PATH", home_path)

      expect(described_class.words).to eq(Lexdrill::DefaultWords::WORDS)
      expect(File.read(home_path)).to eq(Lexdrill::DefaultWords::TEXT)
    end

    it "does not seed when PATH is a project-local or overridden list, even if missing" do
      described_class.words

      expect(File.exist?(described_class::PATH)).to be false
    end
  end

  describe ".next" do
    it "returns nil when the word list is empty" do
      write_words("")
      expect(described_class.next).to be_nil
    end

    it "returns the first word and advances the counter on the first call" do
      write_words("alpha\nbeta\ngamma\n")
      expect(described_class.next).to eq("alpha")
      expect(counter_value).to eq(1)
    end

    it "advances through the list on successive calls" do
      write_words("alpha\nbeta\ngamma\n")
      expect(described_class.next).to eq("alpha")
      expect(described_class.next).to eq("beta")
      expect(described_class.next).to eq("gamma")
    end

    it "wraps back to the first word once the list is exhausted" do
      write_words("alpha\nbeta\n")
      3.times { described_class.next } # alpha, beta, alpha
      expect(described_class.next).to eq("beta")
    end

    it "resets the persisted counter instead of letting it grow past the word count" do
      write_words("alpha\nbeta\n")
      5.times { described_class.next }
      expect(counter_value).to be <= 2
    end

    it "records a show in Stats for each word returned" do
      write_words("alpha\nbeta\n")
      described_class.next
      described_class.next
      described_class.next

      expect(Lexdrill::Stats.counts).to eq("alpha" => 2, "beta" => 1)
    end

    it "excludes graduated words from selection" do
      write_words("alpha\nbeta\n")
      File.write(Lexdrill::Stats::PATH, JSON.generate("alpha" => Lexdrill::Stats::GRADUATION_THRESHOLD))

      5.times { expect(described_class.next).to eq("beta") }
    end

    it "returns nil once every word has graduated" do
      write_words("alpha\nbeta\n")
      graduated = { "alpha" => Lexdrill::Stats::GRADUATION_THRESHOLD, "beta" => Lexdrill::Stats::GRADUATION_THRESHOLD }
      File.write(Lexdrill::Stats::PATH, JSON.generate(graduated))

      expect(described_class.next).to be_nil
    end

    it "ignores the counter/rhythm and only picks from the active words when beat rand is set" do
      write_words("alpha\nbeta\ngamma\n")
      Lexdrill::Beat.set_rand

      picks = Array.new(30) { described_class.next }
      expect(picks.uniq.sort).to eq(%w[alpha beta gamma])
      expect(counter_value).to eq(0)
    end

    it "still excludes graduated words when beat rand is set" do
      write_words("alpha\nbeta\n")
      Lexdrill::Beat.set_rand
      File.write(Lexdrill::Stats::PATH, JSON.generate("alpha" => Lexdrill::Stats::GRADUATION_THRESHOLD))

      10.times { expect(described_class.next).to eq("beta") }
    end
  end
end
