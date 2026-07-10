# frozen_string_literal: true

RSpec.describe Lexdrill::CLI do
  describe "#start" do
    it "prints the version" do
      expect { described_class.new(["version"]).start }.to output("#{Lexdrill::VERSION}\n").to_stdout
    end

    it "prints help and returns 0 when given no command" do
      exit_code = nil
      expect { exit_code = described_class.new([]).start }.to output(/Usage:/).to_stdout
      expect(exit_code).to eq(0)
    end

    it "reports unknown commands on stderr and returns 1" do
      exit_code = nil
      expect { exit_code = described_class.new(["bogus"]).start }.to output(/unknown command/).to_stderr
      expect(exit_code).to eq(1)
    end

    it "prints the current word and returns 0" do
      Dir.mktmpdir("lexdrill-cli-next-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        stub_const("Lexdrill::WordList::COUNTER_PATH", File.join(dir, ".drill.counter"))
        stub_const("Lexdrill::Toggle::PATH", File.join(dir, ".drill.disabled"))
        stub_const("Lexdrill::Beat::PATH", File.join(dir, ".drill.beat"))
        stub_const("Lexdrill::Format::PATH", File.join(dir, ".drill.format"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "alpha\nbeta\n")

        exit_code = nil
        expect do
          exit_code = described_class.new(["next"]).start
        end.to output(%r{\A\e\[\d+m⟳1/2/\[1-2\]\nalpha\e\[0m\n\z}).to_stdout
        expect(exit_code).to eq(0)
      end
    end

    it "reports on stderr and returns 1 when there are no words" do
      Dir.mktmpdir("lexdrill-cli-next-empty-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        stub_const("Lexdrill::WordList::COUNTER_PATH", File.join(dir, ".drill.counter"))
        stub_const("Lexdrill::Toggle::PATH", File.join(dir, ".drill.disabled"))
        stub_const("Lexdrill::Beat::PATH", File.join(dir, ".drill.beat"))
        stub_const("Lexdrill::Format::PATH", File.join(dir, ".drill.format"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "")

        exit_code = nil
        expect { exit_code = described_class.new(["next"]).start }.to output(/no words/).to_stderr
        expect(exit_code).to eq(1)
      end
    end

    it "still prints the current word when stopped (stop only gates the shell hook, not `next` itself)" do
      Dir.mktmpdir("lexdrill-cli-next-stopped-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        stub_const("Lexdrill::WordList::COUNTER_PATH", File.join(dir, ".drill.counter"))
        stub_const("Lexdrill::Toggle::PATH", File.join(dir, ".drill.disabled"))
        stub_const("Lexdrill::Beat::PATH", File.join(dir, ".drill.beat"))
        stub_const("Lexdrill::Format::PATH", File.join(dir, ".drill.format"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "alpha\nbeta\n")
        Lexdrill::Toggle.stop

        exit_code = nil
        expect do
          exit_code = described_class.new(["next"]).start
        end.to output(%r{\A\e\[\d+m⟳1/2/\[1-2\]\nalpha\e\[0m\n\z}).to_stdout
        expect(exit_code).to eq(0)
      end
    end

    it "prints the zsh hook snippet" do
      expect { described_class.new(%w[hook zsh]).start }.to output(/drill_precmd/).to_stdout
    end

    it "prints the bash hook snippet" do
      expect { described_class.new(%w[hook bash]).start }.to output(/drill_precmd/).to_stdout
    end

    it "reports usage on stderr and returns 1 when hook is given no shell" do
      exit_code = nil
      expect { exit_code = described_class.new(["hook"]).start }.to output(/usage/).to_stderr
      expect(exit_code).to eq(1)
    end

    it "reports the unsupported shell on stderr and returns 1" do
      exit_code = nil
      expect { exit_code = described_class.new(%w[hook fish]).start }.to output(/fish/).to_stderr
      expect(exit_code).to eq(1)
    end

    it "stops drilling" do
      Dir.mktmpdir("lexdrill-cli-stop-spec") do |dir|
        stub_const("Lexdrill::Toggle::PATH", File.join(dir, ".drill.disabled"))

        exit_code = described_class.new(["stop"]).start
        expect(exit_code).to eq(0)
        expect(Lexdrill::Toggle.enabled?).to be false
      end
    end

    it "starts drilling again after a stop" do
      Dir.mktmpdir("lexdrill-cli-start-spec") do |dir|
        stub_const("Lexdrill::Toggle::PATH", File.join(dir, ".drill.disabled"))
        Lexdrill::Toggle.stop

        exit_code = described_class.new(["start"]).start
        expect(exit_code).to eq(0)
        expect(Lexdrill::Toggle.enabled?).to be true
      end
    end

    it "prints the inspect report" do
      Dir.mktmpdir("lexdrill-cli-inspect-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        stub_const("Lexdrill::WordList::COUNTER_PATH", File.join(dir, ".drill.counter"))
        stub_const("Lexdrill::Toggle::PATH", File.join(dir, ".drill.disabled"))
        stub_const("Lexdrill::Beat::PATH", File.join(dir, ".drill.beat"))
        stub_const("Lexdrill::Format::PATH", File.join(dir, ".drill.format"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)

        exit_code = nil
        expect { exit_code = described_class.new(["inspect"]).start }.to output(/Words file:/).to_stdout
        expect(exit_code).to eq(0)
      end
    end

    it "sets the beat" do
      Dir.mktmpdir("lexdrill-cli-beat-spec") do |dir|
        stub_const("Lexdrill::Beat::PATH", File.join(dir, ".drill.beat"))

        exit_code = described_class.new(%w[beat 3 2]).start
        expect(exit_code).to eq(0)
        expect(Lexdrill::Beat.loop_size).to eq(3)
        expect(Lexdrill::Beat.repetitions).to eq(2)
      end
    end

    it "clears the beat with `beat none`" do
      Dir.mktmpdir("lexdrill-cli-beat-none-spec") do |dir|
        stub_const("Lexdrill::Beat::PATH", File.join(dir, ".drill.beat"))
        Lexdrill::Beat.set(3, 2)

        exit_code = described_class.new(%w[beat none]).start
        expect(exit_code).to eq(0)
        expect(Lexdrill::Beat.configured?).to be false
      end
    end

    it "reports usage on stderr and returns 1 when beat is given no args" do
      exit_code = nil
      expect { exit_code = described_class.new(["beat"]).start }.to output(/usage/).to_stderr
      expect(exit_code).to eq(1)
    end

    it "rejects a loop size outside 2..8" do
      Dir.mktmpdir("lexdrill-cli-beat-invalid-spec") do |dir|
        stub_const("Lexdrill::Beat::PATH", File.join(dir, ".drill.beat"))

        exit_code = nil
        expect { exit_code = described_class.new(%w[beat 1 2]).start }.to output(/loop size/).to_stderr
        expect(exit_code).to eq(1)
        expect(Lexdrill::Beat.configured?).to be false
      end
    end

    it "rejects non-positive repetitions" do
      Dir.mktmpdir("lexdrill-cli-beat-invalid-reps-spec") do |dir|
        stub_const("Lexdrill::Beat::PATH", File.join(dir, ".drill.beat"))

        exit_code = nil
        expect { exit_code = described_class.new(%w[beat 3 0]).start }.to output(/repetitions/).to_stderr
        expect(exit_code).to eq(1)
        expect(Lexdrill::Beat.configured?).to be false
      end
    end

    it "sets the beat via the waltz alias (loop size 3)" do
      Dir.mktmpdir("lexdrill-cli-beat-alias-spec") do |dir|
        stub_const("Lexdrill::Beat::PATH", File.join(dir, ".drill.beat"))

        exit_code = described_class.new(%w[waltz 16]).start
        expect(exit_code).to eq(0)
        expect(Lexdrill::Beat.loop_size).to eq(3)
        expect(Lexdrill::Beat.repetitions).to eq(16)
      end
    end

    it "defaults repetitions to 8 for a bare alias (drill jazz == drill beat 5 8)" do
      Dir.mktmpdir("lexdrill-cli-beat-alias-default-spec") do |dir|
        stub_const("Lexdrill::Beat::PATH", File.join(dir, ".drill.beat"))

        exit_code = described_class.new(["jazz"]).start
        expect(exit_code).to eq(0)
        expect(Lexdrill::Beat.loop_size).to eq(5)
        expect(Lexdrill::Beat.repetitions).to eq(8)
      end
    end

    it "defaults repetitions to 8 for `drill beat <loop_size>` with no repetitions given" do
      Dir.mktmpdir("lexdrill-cli-beat-default-spec") do |dir|
        stub_const("Lexdrill::Beat::PATH", File.join(dir, ".drill.beat"))

        exit_code = described_class.new(%w[beat 4]).start
        expect(exit_code).to eq(0)
        expect(Lexdrill::Beat.loop_size).to eq(4)
        expect(Lexdrill::Beat.repetitions).to eq(8)
      end
    end

    it "sets the format to simple" do
      Dir.mktmpdir("lexdrill-cli-format-simple-spec") do |dir|
        stub_const("Lexdrill::Format::PATH", File.join(dir, ".drill.format"))

        exit_code = described_class.new(%w[format simple]).start
        expect(exit_code).to eq(0)
        expect(Lexdrill::Format.current).to eq("simple")
      end
    end

    it "sets the format back to full" do
      Dir.mktmpdir("lexdrill-cli-format-full-spec") do |dir|
        stub_const("Lexdrill::Format::PATH", File.join(dir, ".drill.format"))
        Lexdrill::Format.set("simple")

        exit_code = described_class.new(%w[format full]).start
        expect(exit_code).to eq(0)
        expect(Lexdrill::Format.current).to eq("full")
      end
    end

    it "reports usage on stderr and returns 1 for an invalid format" do
      exit_code = nil
      expect { exit_code = described_class.new(%w[format bogus]).start }.to output(/usage/).to_stderr
      expect(exit_code).to eq(1)
    end
  end
end
