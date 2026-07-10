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
    Lexdrill::WordList.instance_variable_set(:@words, nil)
  end

  describe ".format" do
    it "formats current:total, a tab, then the word" do
      File.write(Lexdrill::WordList::PATH, "alpha\nbeta\ngamma\n")
      Lexdrill::WordList.next # advances the counter to 1

      expect(described_class.format("alpha")).to eq("1:3\talpha")
    end
  end
end
