# frozen_string_literal: true

RSpec.describe Lexdrill::Colorizer do
  around do |example|
    Dir.mktmpdir("lexdrill-colorizer-spec") do |dir|
      @dir = dir
      example.run
    end
  end

  before { stub_const("Lexdrill::Color::PATH", File.join(@dir, ".drill.color")) }

  describe ".paint_yellow" do
    it "always wraps the text in the fixed yellow code" do
      expect(described_class.paint_yellow("hello")).to eq("\e[33mhello\e[0m")
    end
  end

  describe ".paint_by_count" do
    context "in default color mode (the default)" do
      it "is pure blue at count 1 (bucket 0)" do
        expect(described_class.paint_by_count("hello", 1)).to eq("\e[38;2;0;0;255mhello\e[0m")
      end

      it "stays in the same bucket for any count within the first Stats::BUCKET_SIZE shows" do
        expect(described_class.paint_by_count("hello", 1))
          .to eq(described_class.paint_by_count("hello", Lexdrill::Stats::BUCKET_SIZE - 1))
      end

      it "moves to the next bucket every Stats::BUCKET_SIZE shows" do
        first_bucket = described_class.paint_by_count("hello", 1)
        second_bucket = described_class.paint_by_count("hello", Lexdrill::Stats::BUCKET_SIZE + 1)
        expect(first_bucket).not_to eq(second_bucket)
      end

      it "is pure red at the last bucket, at or beyond graduation" do
        at_threshold = described_class.paint_by_count(
          "hello", Lexdrill::Stats::GRADUATION_THRESHOLD - Lexdrill::Stats::BUCKET_SIZE + 1
        )
        beyond_threshold = described_class.paint_by_count("hello", Lexdrill::Stats::GRADUATION_THRESHOLD + 501)

        expect(at_threshold).to eq("\e[38;2;255;0;0mhello\e[0m")
        expect(beyond_threshold).to eq("\e[38;2;255;0;0mhello\e[0m")
      end
    end

    context "when drill color random is set" do
      before { Lexdrill::Color.set("random") }

      it "uses a random hue instead of the gradient" do
        allow(Kernel).to receive(:rand).with(360).and_return(0)
        expect(described_class.paint_by_count("hello", 1)).to eq("\e[38;2;255;0;0mhello\e[0m")
      end

      it "produces a different color for a different random draw" do
        allow(Kernel).to receive(:rand).with(360).and_return(120)
        expect(described_class.paint_by_count("hello", 1)).to eq("\e[38;2;0;255;0mhello\e[0m")
      end

      it "ignores the gradient entirely, even at a count that would otherwise be pure blue" do
        allow(Kernel).to receive(:rand).with(360).and_return(300)
        expect(described_class.paint_by_count("hello", 1)).not_to eq("\e[38;2;0;0;255mhello\e[0m")
      end
    end
  end
end
