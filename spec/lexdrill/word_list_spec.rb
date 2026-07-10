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
  end
end
