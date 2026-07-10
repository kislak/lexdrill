# frozen_string_literal: true

RSpec.describe Lexdrill::Colorizer do
  describe ".paint_blue" do
    it "always wraps the text in the fixed blue code" do
      expect(described_class.paint_blue("hello")).to eq("\e[34mhello\e[0m")
    end
  end

  describe ".paint_by_count" do
    context "when the count is odd (gradient)" do
      it "is pure blue at count 1 (bucket 0)" do
        expect(described_class.paint_by_count("hello", 1)).to eq("\e[38;2;0;0;255mhello\e[0m")
      end

      it "stays in the same bucket for any odd count within the first 100 shows" do
        expect(described_class.paint_by_count("hello", 1)).to eq(described_class.paint_by_count("hello", 99))
      end

      it "moves to the next bucket every Stats::BUCKET_SIZE shows" do
        first_bucket = described_class.paint_by_count("hello", 1)
        second_bucket = described_class.paint_by_count("hello", 101)
        expect(first_bucket).not_to eq(second_bucket)
      end

      it "is pure red at the last bucket, at or beyond graduation" do
        at_threshold = described_class.paint_by_count("hello", Lexdrill::Stats::GRADUATION_THRESHOLD - 99)
        beyond_threshold = described_class.paint_by_count("hello", Lexdrill::Stats::GRADUATION_THRESHOLD + 501)

        expect(at_threshold).to eq("\e[38;2;255;0;0mhello\e[0m")
        expect(beyond_threshold).to eq("\e[38;2;255;0;0mhello\e[0m")
      end
    end

    context "when the count is even (random)" do
      it "uses a random hue instead of the gradient" do
        allow(Kernel).to receive(:rand).with(360).and_return(0)
        expect(described_class.paint_by_count("hello", 0)).to eq("\e[38;2;255;0;0mhello\e[0m")
      end

      it "produces a different color for a different random draw" do
        allow(Kernel).to receive(:rand).with(360).and_return(120)
        expect(described_class.paint_by_count("hello", 2)).to eq("\e[38;2;0;255;0mhello\e[0m")
      end

      it "ignores the gradient entirely, even at a count that would otherwise be pure blue" do
        allow(Kernel).to receive(:rand).with(360).and_return(300)
        expect(described_class.paint_by_count("hello", 0)).not_to eq("\e[38;2;0;0;255mhello\e[0m")
      end
    end
  end
end
