# frozen_string_literal: true

RSpec.describe Lexdrill::LineFormatter do
  around do |example|
    Dir.mktmpdir("lexdrill-line-formatter-spec") do |dir|
      @dir = dir
      example.run
    end
  end

  before do
    stub_const("Lexdrill::WordList::PATH", File.join(@dir, ".drill.txt"))
    stub_const("Lexdrill::WordList::COUNTER_PATH", File.join(@dir, ".drill.counter"))
    stub_const("Lexdrill::Beat::PATH", File.join(@dir, ".drill.beat"))
    Lexdrill::WordList.instance_variable_set(:@words, nil)
  end

  describe ".format" do
    it "formats current/total followed by the separator, a newline, then the word" do
      File.write(Lexdrill::WordList::PATH, "alpha\nbeta\ngamma\n")
      Lexdrill::WordList.next # advances the counter to 1

      expect(described_class.format("alpha")).to eq("1/3⟳\nalpha")
    end

    it "shows the word's own position (not the raw beat step) when a beat is configured" do
      File.write(Lexdrill::WordList::PATH, "a\nb\nc\nd\ne\nf\n")
      Lexdrill::Beat.set(3, 2) # loop of 3, repeated 2x: a,b,c,a,b,c,d,e,f,d,e,f

      # format must be called immediately after each next, matching real usage -
      # it reads the *current* counter value, so batching next calls first
      # would only reflect the final step.
      lines = Array.new(4) do
        word = Lexdrill::WordList.next
        described_class.format(word)
      end

      expect(lines).to eq(["1/6⟳\na", "2/6⟳\nb", "3/6⟳\nc", "1/6⟳\na"])
    end
  end
end
