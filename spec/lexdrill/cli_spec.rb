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

    it "prints the current word in full format and returns 0" do
      Dir.mktmpdir("lexdrill-cli-next-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        stub_const("Lexdrill::WordList::COUNTER_PATH", File.join(dir, ".drill.counter"))
        stub_const("Lexdrill::Toggle::PATH", File.join(dir, ".drill.disabled"))
        stub_const("Lexdrill::Beat::PATH", File.join(dir, ".drill.beat"))
        stub_const("Lexdrill::Format::PATH", File.join(dir, ".drill.format"))
        stub_const("Lexdrill::Stats::PATH", File.join(dir, ".drill.stats"))
        stub_const("Lexdrill::Rand::PATH", File.join(dir, ".drill.rand"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "alpha\nbeta\n")
        Lexdrill::Format.set("full")

        exit_code = nil
        expect do
          exit_code = described_class.new(["next"]).start
        end.to output(%r{\A\e\[[\d;]+m1/2⟳\[1-2\]\nalpha\e\[0m\n\z}).to_stdout
        expect(exit_code).to eq(0)
      end
    end

    it "prints simple-mode output as the blue drill sign, a space, then the word colored by its show count" do
      Dir.mktmpdir("lexdrill-cli-next-simple-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        stub_const("Lexdrill::WordList::COUNTER_PATH", File.join(dir, ".drill.counter"))
        stub_const("Lexdrill::Toggle::PATH", File.join(dir, ".drill.disabled"))
        stub_const("Lexdrill::Beat::PATH", File.join(dir, ".drill.beat"))
        stub_const("Lexdrill::Format::PATH", File.join(dir, ".drill.format"))
        stub_const("Lexdrill::Stats::PATH", File.join(dir, ".drill.stats"))
        stub_const("Lexdrill::Rand::PATH", File.join(dir, ".drill.rand"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "alpha\nbeta\n")
        Lexdrill::Format.set("simple")

        exit_code = nil
        expect do
          exit_code = described_class.new(["next"]).start
        end.to output(/\A\e\[34m⟳\e\[0m \e\[[\d;]+malpha\e\[0m\n\z/).to_stdout
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
        stub_const("Lexdrill::Stats::PATH", File.join(dir, ".drill.stats"))
        stub_const("Lexdrill::Rand::PATH", File.join(dir, ".drill.rand"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "")

        exit_code = nil
        expect { exit_code = described_class.new(["next"]).start }.to output(/no words/).to_stderr
        expect(exit_code).to eq(1)
      end
    end

    it "reports on stderr and returns 1 once every word has graduated" do
      Dir.mktmpdir("lexdrill-cli-next-graduated-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        stub_const("Lexdrill::WordList::COUNTER_PATH", File.join(dir, ".drill.counter"))
        stub_const("Lexdrill::Toggle::PATH", File.join(dir, ".drill.disabled"))
        stub_const("Lexdrill::Beat::PATH", File.join(dir, ".drill.beat"))
        stub_const("Lexdrill::Format::PATH", File.join(dir, ".drill.format"))
        stub_const("Lexdrill::Stats::PATH", File.join(dir, ".drill.stats"))
        stub_const("Lexdrill::Rand::PATH", File.join(dir, ".drill.rand"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "alpha\n")
        File.write(Lexdrill::WordList::COUNTER_PATH, "0")
        File.write(Lexdrill::Stats::PATH, JSON.generate("alpha" => Lexdrill::Stats::GRADUATION_THRESHOLD))

        exit_code = nil
        expect { exit_code = described_class.new(["next"]).start }.to output(/nothing left to drill/).to_stderr
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
        stub_const("Lexdrill::Stats::PATH", File.join(dir, ".drill.stats"))
        stub_const("Lexdrill::Rand::PATH", File.join(dir, ".drill.rand"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "alpha\nbeta\n")
        Lexdrill::Format.set("full")
        Lexdrill::Toggle.stop

        exit_code = nil
        expect do
          exit_code = described_class.new(["next"]).start
        end.to output(%r{\A\e\[[\d;]+m1/2⟳\[1-2\]\nalpha\e\[0m\n\z}).to_stdout
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
        stub_const("Lexdrill::Stats::PATH", File.join(dir, ".drill.stats"))
        stub_const("Lexdrill::Rand::PATH", File.join(dir, ".drill.rand"))
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

    it "sets beat rand with `beat rand`" do
      Dir.mktmpdir("lexdrill-cli-beat-rand-spec") do |dir|
        stub_const("Lexdrill::Beat::PATH", File.join(dir, ".drill.beat"))

        exit_code = described_class.new(%w[beat rand]).start
        expect(exit_code).to eq(0)
        expect(Lexdrill::Beat.rand?).to be true
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

    it "appends a new item to the end of the list" do
      Dir.mktmpdir("lexdrill-cli-add-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        File.write(Lexdrill::WordList::PATH, "alpha\nbeta\n")

        exit_code = nil
        expect do
          exit_code = described_class.new(%w[add gamma delta]).start
        end.to output(/added: gamma delta/).to_stdout
        expect(exit_code).to eq(0)

        lines = File.readlines(Lexdrill::WordList::PATH, encoding: "UTF-8").map(&:strip)
        expect(lines).to eq(["alpha", "beta", "gamma delta"])
      end
    end

    it "creates the list file if it doesn't exist yet" do
      Dir.mktmpdir("lexdrill-cli-add-new-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))

        exit_code = described_class.new(%w[add hello]).start
        expect(exit_code).to eq(0)
        expect(File.read(Lexdrill::WordList::PATH)).to eq("hello\n")
      end
    end

    it "reports usage on stderr and returns 1 when add is given no text" do
      exit_code = nil
      expect { exit_code = described_class.new(["add"]).start }.to output(/usage/).to_stderr
      expect(exit_code).to eq(1)
    end

    it "prints each item as count<TAB>phrase" do
      Dir.mktmpdir("lexdrill-cli-stats-tab-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        stub_const("Lexdrill::WordList::COUNTER_PATH", File.join(dir, ".drill.counter"))
        stub_const("Lexdrill::Beat::PATH", File.join(dir, ".drill.beat"))
        stub_const("Lexdrill::Stats::PATH", File.join(dir, ".drill.stats"))
        stub_const("Lexdrill::Rand::PATH", File.join(dir, ".drill.rand"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "alpha\nbeta\n")
        Lexdrill::WordList.next
        Lexdrill::WordList.next
        Lexdrill::WordList.next

        exit_code = nil
        expect do
          exit_code = described_class.new(["stats"]).start
        end.to output("2\talpha\n1\tbeta\n").to_stdout
        expect(exit_code).to eq(0)
      end
    end

    it "sorts items by show count, highest first, regardless of list file order" do
      Dir.mktmpdir("lexdrill-cli-stats-sort-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        stub_const("Lexdrill::Stats::PATH", File.join(dir, ".drill.stats"))
        stub_const("Lexdrill::Rand::PATH", File.join(dir, ".drill.rand"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "gamma\nbeta\nalpha\n")
        3.times { Lexdrill::Stats.record("alpha") }
        2.times { Lexdrill::Stats.record("beta") }
        Lexdrill::Stats.record("gamma")

        exit_code = nil
        expect do
          exit_code = described_class.new(["stats"]).start
        end.to output("3\talpha\n2\tbeta\n1\tgamma\n").to_stdout
        expect(exit_code).to eq(0)
      end
    end

    it "reports on stderr and returns 1 when the list is empty" do
      Dir.mktmpdir("lexdrill-cli-list-empty-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        stub_const("Lexdrill::WordList::COUNTER_PATH", File.join(dir, ".drill.counter"))
        stub_const("Lexdrill::Beat::PATH", File.join(dir, ".drill.beat"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "")

        exit_code = nil
        expect { exit_code = described_class.new(["list"]).start }.to output(/no words/).to_stderr
        expect(exit_code).to eq(1)
      end
    end

    it "opens the list file with $EDITOR and returns 0 on success" do
      Dir.mktmpdir("lexdrill-cli-open-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        File.write(Lexdrill::WordList::PATH, "alpha\n")
        original_editor = ENV.fetch("EDITOR", nil)

        begin
          ENV["EDITOR"] = "true"
          exit_code = described_class.new(["open"]).start
          expect(exit_code).to eq(0)
        ensure
          ENV["EDITOR"] = original_editor
        end
      end
    end

    it "returns 1 when the editor command fails" do
      Dir.mktmpdir("lexdrill-cli-open-fail-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        File.write(Lexdrill::WordList::PATH, "alpha\n")
        original_editor = ENV.fetch("EDITOR", nil)

        begin
          ENV["EDITOR"] = "false"
          exit_code = described_class.new(["open"]).start
          expect(exit_code).to eq(1)
        ensure
          ENV["EDITOR"] = original_editor
        end
      end
    end

    it "prints show counts for each item, numbered" do
      Dir.mktmpdir("lexdrill-cli-list-numbered-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        stub_const("Lexdrill::WordList::COUNTER_PATH", File.join(dir, ".drill.counter"))
        stub_const("Lexdrill::Beat::PATH", File.join(dir, ".drill.beat"))
        stub_const("Lexdrill::Stats::PATH", File.join(dir, ".drill.stats"))
        stub_const("Lexdrill::Rand::PATH", File.join(dir, ".drill.rand"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "alpha\nbeta\n")
        Lexdrill::WordList.next
        Lexdrill::WordList.next
        Lexdrill::WordList.next

        exit_code = nil
        expect do
          exit_code = described_class.new(["list"]).start
        end.to output("1. alpha (2)\n2. beta (1)\n").to_stdout
        expect(exit_code).to eq(0)
      end
    end

    it "reports on stderr and returns 1 when stats is run with no words" do
      Dir.mktmpdir("lexdrill-cli-stats-empty-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        stub_const("Lexdrill::WordList::COUNTER_PATH", File.join(dir, ".drill.counter"))
        stub_const("Lexdrill::Beat::PATH", File.join(dir, ".drill.beat"))
        stub_const("Lexdrill::Stats::PATH", File.join(dir, ".drill.stats"))
        stub_const("Lexdrill::Rand::PATH", File.join(dir, ".drill.rand"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "")

        exit_code = nil
        expect { exit_code = described_class.new(["stats"]).start }.to output(/no words/).to_stderr
        expect(exit_code).to eq(1)
      end
    end

    it "sets the rand denominator" do
      Dir.mktmpdir("lexdrill-cli-rand-spec") do |dir|
        stub_const("Lexdrill::Rand::PATH", File.join(dir, ".drill.rand"))

        exit_code = described_class.new(%w[rand 10]).start
        expect(exit_code).to eq(0)
        expect(Lexdrill::Rand.value).to eq(10)
      end
    end

    it "reports usage on stderr and returns 1 when rand is given no argument" do
      exit_code = nil
      expect { exit_code = described_class.new(["rand"]).start }.to output(/usage/).to_stderr
      expect(exit_code).to eq(1)
    end

    it "reports usage on stderr and returns 1 for a non-positive rand value" do
      exit_code = nil
      expect { exit_code = described_class.new(%w[rand 0]).start }.to output(/usage/).to_stderr
      expect(exit_code).to eq(1)
    end

    it "next silently no-ops (prints nothing, exits 0) when rand skips the show" do
      Dir.mktmpdir("lexdrill-cli-next-rand-skip-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        stub_const("Lexdrill::WordList::COUNTER_PATH", File.join(dir, ".drill.counter"))
        stub_const("Lexdrill::Rand::PATH", File.join(dir, ".drill.rand"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "alpha\n")
        Lexdrill::Rand.set(5)
        allow(Kernel).to receive(:rand).with(5).and_return(3)

        exit_code = nil
        expect { exit_code = described_class.new(["next"]).start }.to_not output.to_stdout
        expect(exit_code).to eq(0)
        expect(Lexdrill::Counter.new(Lexdrill::WordList::COUNTER_PATH).value).to eq(0)
      end
    end

    it "next still shows normally (manual call) when the random draw lands on zero" do
      Dir.mktmpdir("lexdrill-cli-next-rand-show-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        stub_const("Lexdrill::WordList::COUNTER_PATH", File.join(dir, ".drill.counter"))
        stub_const("Lexdrill::Toggle::PATH", File.join(dir, ".drill.disabled"))
        stub_const("Lexdrill::Beat::PATH", File.join(dir, ".drill.beat"))
        stub_const("Lexdrill::Format::PATH", File.join(dir, ".drill.format"))
        stub_const("Lexdrill::Stats::PATH", File.join(dir, ".drill.stats"))
        stub_const("Lexdrill::Rand::PATH", File.join(dir, ".drill.rand"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "alpha\n")
        Lexdrill::Rand.set(5)
        allow(Kernel).to receive(:rand).with(5).and_return(0)

        exit_code = nil
        expect { exit_code = described_class.new(["next"]).start }.to output(/alpha/).to_stdout
        expect(exit_code).to eq(0)
      end
    end

    it "go jumps so the following next shows the requested item, without printing anything itself" do
      Dir.mktmpdir("lexdrill-cli-go-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        stub_const("Lexdrill::WordList::COUNTER_PATH", File.join(dir, ".drill.counter"))
        stub_const("Lexdrill::Beat::PATH", File.join(dir, ".drill.beat"))
        stub_const("Lexdrill::Stats::PATH", File.join(dir, ".drill.stats"))
        stub_const("Lexdrill::Rand::PATH", File.join(dir, ".drill.rand"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "alpha\nbeta\ngamma\n")

        exit_code = nil
        expect { exit_code = described_class.new(%w[go 3]).start }.to_not output.to_stdout
        expect(exit_code).to eq(0)
        expect(Lexdrill::WordList.next).to eq("gamma")
      end
    end

    it "reports on stderr and returns 1 when there are no words to go to" do
      Dir.mktmpdir("lexdrill-cli-go-empty-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "")

        exit_code = nil
        expect { exit_code = described_class.new(%w[go 1]).start }.to output(/no words/).to_stderr
        expect(exit_code).to eq(1)
      end
    end

    it "reports usage on stderr and returns 1 for a number out of range" do
      Dir.mktmpdir("lexdrill-cli-go-range-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "alpha\nbeta\n")

        exit_code = nil
        expect { exit_code = described_class.new(%w[go 3]).start }.to output(/usage/).to_stderr
        expect(exit_code).to eq(1)

        exit_code = nil
        expect { exit_code = described_class.new(%w[go 0]).start }.to output(/usage/).to_stderr
        expect(exit_code).to eq(1)
      end
    end

    it "reports on stderr and returns 1 when the target item has already graduated" do
      Dir.mktmpdir("lexdrill-cli-go-graduated-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        stub_const("Lexdrill::Stats::PATH", File.join(dir, ".drill.stats"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "alpha\nbeta\n")
        File.write(Lexdrill::Stats::PATH, JSON.generate("alpha" => Lexdrill::Stats::GRADUATION_THRESHOLD))

        exit_code = nil
        expect { exit_code = described_class.new(%w[go 1]).start }.to output(/graduated/).to_stderr
        expect(exit_code).to eq(1)
      end
    end
  end
end
