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
    stub_const("Lexdrill::Format::PATH", File.join(@dir, ".drill.format"))
    Lexdrill::WordList.instance_variable_set(:@words, nil)
  end

  describe ".format" do
    it "in full mode (the default), formats counter/total, the drill sign, [chunk], a newline, the word" do
      File.write(Lexdrill::WordList::PATH, "alpha\nbeta\ngamma\n")
      Lexdrill::WordList.next # advances the counter to 1

      expect(described_class.format("alpha")).to eq("1/3⟳[1-3]\nalpha")
    end

    it "shows the word's own position and current loop range when a beat is configured" do
      File.write(Lexdrill::WordList::PATH, "a\nb\nc\nd\ne\nf\n")
      Lexdrill::Beat.set(3, 2) # loop of 3, repeated 2x: a,b,c,a,b,c,d,e,f,d,e,f

      # format must be called immediately after each next, matching real usage -
      # it reads the *current* counter value, so batching next calls first
      # would only reflect the final step.
      lines = Array.new(4) do
        word = Lexdrill::WordList.next
        described_class.format(word)
      end

      expect(lines).to eq(
        [
          "1/6⟳[1-3]\na",
          "2/6⟳[1-3]\nb",
          "3/6⟳[1-3]\nc",
          "1/6⟳[1-3]\na"
        ]
      )
    end

    it "in simple mode, is the blue drill sign, a space, then the word in a random color, on one line" do
      File.write(Lexdrill::WordList::PATH, "alpha\nbeta\n")
      Lexdrill::Format.set("simple")
      Lexdrill::WordList.next

      result = described_class.format("alpha")
      expect(result).to match(/\A\e\[34m⟳\e\[0m \e\[\d+malpha\e\[0m\z/)

      word_code = result.match(/ \e\[(\d+)malpha/)[1].to_i
      expect(Lexdrill::Colorizer::CODES).to include(word_code)
    end
  end
end
