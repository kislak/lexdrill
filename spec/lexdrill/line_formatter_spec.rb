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
    stub_const("Lexdrill::Stats::PATH", File.join(@dir, ".drill.stats"))
    stub_const("Lexdrill::Color::PATH", File.join(@dir, ".drill.color"))
    Lexdrill::WordList.instance_variable_set(:@words, nil)
  end

  describe ".format" do
    it "is the counter/total and the drill sign in yellow, a space, then the word colored by its show count" do
      File.write(Lexdrill::WordList::PATH, "alpha\nbeta\n")
      Lexdrill::WordList.next # advances the counter to 1, records one show of "alpha"

      result = described_class.format("alpha")
      expected_prefix = Lexdrill::Colorizer.paint_yellow("1/2⟳")
      expected_word = Lexdrill::Colorizer.paint_by_count("alpha", 1)
      expect(result).to eq("#{expected_prefix} #{expected_word}")
    end

    it "shows the word's own position when a beat is configured" do
      File.write(Lexdrill::WordList::PATH, "a\nb\nc\nd\ne\nf\n")
      Lexdrill::Beat.set(3, 2) # loop of 3, repeated 2x: a,b,c,a,b,c,d,e,f,d,e,f

      # format must be called immediately after each next, matching real usage -
      # it reads the *current* counter value, so batching next calls first
      # would only reflect the final step.
      indexes = Array.new(4) do
        word = Lexdrill::WordList.next
        described_class.format(word)[%r{\d+/\d+}]
      end

      expect(indexes).to eq(%w[1/6 2/6 3/6 1/6])
    end
  end
end
