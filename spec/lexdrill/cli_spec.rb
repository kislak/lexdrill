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

    it "prints the current word as counter/total, the blue drill sign, a space, then the word, and returns 0" do
      Dir.mktmpdir("lexdrill-cli-next-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        stub_const("Lexdrill::WordList::COUNTER_PATH", File.join(dir, ".drill.counter"))
        stub_const("Lexdrill::Toggle::PATH", File.join(dir, ".drill.disabled"))
        stub_const("Lexdrill::Beat::PATH", File.join(dir, ".drill.beat"))
        stub_const("Lexdrill::Stats::PATH", File.join(dir, ".drill.stats"))
        stub_const("Lexdrill::Rand::PATH", File.join(dir, ".drill.rand"))
        stub_const("Lexdrill::Color::PATH", File.join(dir, ".drill.color"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "alpha\nbeta\n")

        exit_code = nil
        expect do
          exit_code = described_class.new(["next"]).start
        end.to output(%r{\A\e\[33m1/2⟳\e\[0m \e\[[\d;]+malpha\e\[0m\n\z}).to_stdout
        expect(exit_code).to eq(0)
      end
    end

    it "reports on stderr and returns 1 when there are no words" do
      Dir.mktmpdir("lexdrill-cli-next-empty-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        stub_const("Lexdrill::WordList::COUNTER_PATH", File.join(dir, ".drill.counter"))
        stub_const("Lexdrill::Toggle::PATH", File.join(dir, ".drill.disabled"))
        stub_const("Lexdrill::Beat::PATH", File.join(dir, ".drill.beat"))
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
        stub_const("Lexdrill::Stats::PATH", File.join(dir, ".drill.stats"))
        stub_const("Lexdrill::Rand::PATH", File.join(dir, ".drill.rand"))
        stub_const("Lexdrill::Color::PATH", File.join(dir, ".drill.color"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "alpha\nbeta\n")
        Lexdrill::Toggle.stop

        exit_code = nil
        expect do
          exit_code = described_class.new(["next"]).start
        end.to output(%r{\A\e\[33m1/2⟳\e\[0m \e\[[\d;]+malpha\e\[0m\n\z}).to_stdout
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
        stub_const("Lexdrill::Color::PATH", File.join(dir, ".drill.color"))
        stub_const("Lexdrill::Stats::PATH", File.join(dir, ".drill.stats"))
        stub_const("Lexdrill::Rand::PATH", File.join(dir, ".drill.rand"))
        stub_const("Lexdrill::Remote::PATH", File.join(dir, ".drill.remote"))
        stub_const("Lexdrill::OauthRemote::PATH", File.join(dir, ".drill.oauth-remote"))
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

    it "sets the color mode to random" do
      Dir.mktmpdir("lexdrill-cli-color-random-spec") do |dir|
        stub_const("Lexdrill::Color::PATH", File.join(dir, ".drill.color"))

        exit_code = described_class.new(%w[color random]).start
        expect(exit_code).to eq(0)
        expect(Lexdrill::Color.current).to eq("random")
      end
    end

    it "sets the color mode back to default" do
      Dir.mktmpdir("lexdrill-cli-color-default-spec") do |dir|
        stub_const("Lexdrill::Color::PATH", File.join(dir, ".drill.color"))
        Lexdrill::Color.set("random")

        exit_code = described_class.new(%w[color default]).start
        expect(exit_code).to eq(0)
        expect(Lexdrill::Color.current).to eq("default")
      end
    end

    it "reports usage on stderr and returns 1 when color is given no mode" do
      exit_code = nil
      expect { exit_code = described_class.new(["color"]).start }.to output(/usage/).to_stderr
      expect(exit_code).to eq(1)
    end

    it "reports an invalid color mode on stderr and returns 1" do
      exit_code = nil
      expect { exit_code = described_class.new(%w[color bogus]).start }.to output(/unknown color mode/).to_stderr
      expect(exit_code).to eq(1)
    end

    it "appends a new item to the end of the list" do
      Dir.mktmpdir("lexdrill-cli-add-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
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
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))

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

    it "pushes the updated list when a workbook and sheet are both selected" do
      Dir.mktmpdir("lexdrill-cli-add-autopush-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        stub_const("Lexdrill::AuthMode::PATH", File.join(dir, ".drill.auth-mode"))
        File.write(Lexdrill::WordList::PATH, "alpha\n")
        Lexdrill::Workbooks.add("NLP", "abc123")
        Lexdrill::Workbooks.set_current_sheet("Sheet1", 0)
        Lexdrill::AuthMode.set("oauth")
        allow(Lexdrill::GoogleAuth).to receive(:ensure_token!).and_return("tok")
        allow(Lexdrill::SheetsClient).to receive(:overwrite_sheet)

        exit_code = described_class.new(%w[add beta]).start

        expect(exit_code).to eq(0)
        expect(Lexdrill::SheetsClient).to have_received(:overwrite_sheet)
          .with("abc123", "Sheet1", [["alpha"], ["beta"]], "tok")
      end
    end

    it "does not push when no workbook/sheet is selected" do
      Dir.mktmpdir("lexdrill-cli-add-no-push-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        File.write(Lexdrill::WordList::PATH, "alpha\n")
        allow(Lexdrill::SheetsClient).to receive(:overwrite_sheet)

        described_class.new(%w[add beta]).start

        expect(Lexdrill::SheetsClient).not_to have_received(:overwrite_sheet)
      end
    end

    it "warns but still succeeds when the auto-push fails" do
      Dir.mktmpdir("lexdrill-cli-add-push-fails-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        stub_const("Lexdrill::AuthMode::PATH", File.join(dir, ".drill.auth-mode"))
        File.write(Lexdrill::WordList::PATH, "alpha\n")
        Lexdrill::Workbooks.add("NLP", "abc123")
        Lexdrill::Workbooks.set_current_sheet("Sheet1", 0)
        Lexdrill::AuthMode.set("oauth")
        allow(Lexdrill::GoogleAuth).to receive(:ensure_token!)
          .and_raise(Lexdrill::HTTPClient::NetworkError, "getaddrinfo failed")

        exit_code = nil
        expect do
          exit_code = described_class.new(%w[add beta]).start
        end.to output(/couldn't push to "Sheet1"/).to_stderr
        expect(exit_code).to eq(0)
      end
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
      Dir.mktmpdir("lexdrill-cli-edit-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        File.write(Lexdrill::WordList::PATH, "alpha\n")
        original_editor = ENV.fetch("EDITOR", nil)

        begin
          ENV["EDITOR"] = "true"
          exit_code = described_class.new(["edit"]).start
          expect(exit_code).to eq(0)
        ensure
          ENV["EDITOR"] = original_editor
        end
      end
    end

    it "returns 1 when the editor command fails" do
      Dir.mktmpdir("lexdrill-cli-edit-fail-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        File.write(Lexdrill::WordList::PATH, "alpha\n")
        original_editor = ENV.fetch("EDITOR", nil)

        begin
          ENV["EDITOR"] = "false"
          exit_code = described_class.new(["edit"]).start
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

    it "`drill all` is also an alias for `drill list`" do
      Dir.mktmpdir("lexdrill-cli-all-alias-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        stub_const("Lexdrill::WordList::COUNTER_PATH", File.join(dir, ".drill.counter"))
        stub_const("Lexdrill::Beat::PATH", File.join(dir, ".drill.beat"))
        stub_const("Lexdrill::Stats::PATH", File.join(dir, ".drill.stats"))
        stub_const("Lexdrill::Rand::PATH", File.join(dir, ".drill.rand"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "alpha\nbeta\n")
        Lexdrill::WordList.next

        exit_code = nil
        expect do
          exit_code = described_class.new(["all"]).start
        end.to output("1. alpha (1)\n2. beta (0)\n").to_stdout
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
        stub_const("Lexdrill::Stats::PATH", File.join(dir, ".drill.stats"))
        stub_const("Lexdrill::Rand::PATH", File.join(dir, ".drill.rand"))
        stub_const("Lexdrill::Color::PATH", File.join(dir, ".drill.color"))
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

    it "sets the auth mode to remote (service account)" do
      Dir.mktmpdir("lexdrill-cli-remote-spec") do |dir|
        stub_const("Lexdrill::AuthMode::PATH", File.join(dir, ".drill.auth-mode"))

        exit_code = nil
        expect { exit_code = described_class.new(["remote"]).start }.to output(/auth mode set: remote/).to_stdout
        expect(exit_code).to eq(0)
        expect(Lexdrill::AuthMode.current).to eq("remote")
      end
    end

    it "sets the auth mode to oauth (personal login)" do
      Dir.mktmpdir("lexdrill-cli-oauth-spec") do |dir|
        stub_const("Lexdrill::AuthMode::PATH", File.join(dir, ".drill.auth-mode"))

        exit_code = nil
        expect { exit_code = described_class.new(["oauth"]).start }.to output(/auth mode set: oauth/).to_stdout
        expect(exit_code).to eq(0)
        expect(Lexdrill::AuthMode.current).to eq("oauth")
      end
    end

    it "reports usage on stderr and returns 1 for an unrecognized wb subcommand" do
      exit_code = nil
      expect { exit_code = described_class.new(%w[wb bogus]).start }.to output(/usage/).to_stderr
      expect(exit_code).to eq(1)
    end

    it "reports no workbooks configured for wb index" do
      Dir.mktmpdir("lexdrill-cli-wb-index-empty-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))

        exit_code = nil
        expect { exit_code = described_class.new(%w[wb index]).start }.to output(/no workbooks configured/).to_stderr
        expect(exit_code).to eq(1)
      end
    end

    it "lists workbooks, marking the current one with the drill sign" do
      Dir.mktmpdir("lexdrill-cli-wb-index-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        Lexdrill::Workbooks.add("NLP", "abc123")
        Lexdrill::Workbooks.add("gcp", "def456")
        Lexdrill::Workbooks.use("gcp")
        sign = Lexdrill::Colorizer.paint_yellow(Lexdrill::LineFormatter::SEPARATOR)

        exit_code = nil
        expect do
          exit_code = described_class.new(%w[wb index]).start
        end.to output(
          "  NLP  https://docs.google.com/spreadsheets/d/abc123/edit\n" \
          "#{sign} gcp  https://docs.google.com/spreadsheets/d/def456/edit\n"
        ).to_stdout
        expect(exit_code).to eq(0)
      end
    end

    it "bare `drill wb` is an alias for `drill wb index`" do
      Dir.mktmpdir("lexdrill-cli-wb-bare-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        Lexdrill::Workbooks.add("NLP", "abc123")
        sign = Lexdrill::Colorizer.paint_yellow(Lexdrill::LineFormatter::SEPARATOR)

        exit_code = nil
        expect do
          exit_code = described_class.new(["wb"]).start
        end.to output("#{sign} NLP  https://docs.google.com/spreadsheets/d/abc123/edit\n").to_stdout
        expect(exit_code).to eq(0)
      end
    end

    it "adds a workbook by url, naming it after the spreadsheet's own title" do
      Dir.mktmpdir("lexdrill-cli-wb-add-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        stub_const("Lexdrill::AuthMode::PATH", File.join(dir, ".drill.auth-mode"))
        Lexdrill::AuthMode.set("oauth")
        allow(Lexdrill::GoogleAuth).to receive(:ensure_token!).and_return("tok")
        allow(Lexdrill::SheetsClient).to receive(:spreadsheet_title).with("abc123", "tok").and_return("NLP")

        exit_code = nil
        expect do
          exit_code = described_class.new(%w[wb add https://docs.google.com/spreadsheets/d/abc123/edit]).start
        end.to output(/workbook added: "NLP"/).to_stdout
        expect(exit_code).to eq(0)
        expect(Lexdrill::Workbooks.current_name).to eq("NLP")
        expect(Lexdrill::Workbooks.current_id).to eq("abc123")
      end
    end

    it "reports usage on stderr and returns 1 when wb add is given no url" do
      exit_code = nil
      expect { exit_code = described_class.new(%w[wb add]).start }.to output(/usage/).to_stderr
      expect(exit_code).to eq(1)
    end

    it "reports an invalid url on stderr and returns 1 for wb add" do
      exit_code = nil
      expect do
        exit_code = described_class.new(%w[wb add https://example.com/nope]).start
      end.to output(/could not find a spreadsheet id/).to_stderr
      expect(exit_code).to eq(1)
    end

    it "reports no auth mode configured for wb add" do
      Dir.mktmpdir("lexdrill-cli-wb-add-no-auth-spec") do |dir|
        stub_const("Lexdrill::AuthMode::PATH", File.join(dir, ".drill.auth-mode"))
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))

        exit_code = nil
        expect do
          exit_code = described_class.new(%w[wb add https://docs.google.com/spreadsheets/d/abc123/edit]).start
        end.to output(/no auth mode configured/).to_stderr
        expect(exit_code).to eq(1)
      end
    end

    it "reports when the workbook name is already taken" do
      Dir.mktmpdir("lexdrill-cli-wb-add-taken-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        stub_const("Lexdrill::AuthMode::PATH", File.join(dir, ".drill.auth-mode"))
        Lexdrill::Workbooks.add("NLP", "abc123")
        Lexdrill::AuthMode.set("oauth")
        allow(Lexdrill::GoogleAuth).to receive(:ensure_token!).and_return("tok")
        allow(Lexdrill::SheetsClient).to receive(:spreadsheet_title).and_return("NLP")

        exit_code = nil
        expect do
          exit_code = described_class.new(%w[wb add https://docs.google.com/spreadsheets/d/def456/edit]).start
        end.to output(/already configured/).to_stderr
        expect(exit_code).to eq(1)
      end
    end

    it "removes a workbook" do
      Dir.mktmpdir("lexdrill-cli-wb-remove-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        Lexdrill::Workbooks.add("NLP", "abc123")

        exit_code = nil
        expect do
          exit_code = described_class.new(%w[wb remove NLP]).start
        end.to output(/workbook removed: "NLP"/).to_stdout
        expect(exit_code).to eq(0)
        expect(Lexdrill::Workbooks.names).to eq([])
      end
    end

    it "reports usage on stderr and returns 1 when wb remove is given no name" do
      exit_code = nil
      expect { exit_code = described_class.new(%w[wb remove]).start }.to output(/usage/).to_stderr
      expect(exit_code).to eq(1)
    end

    it "reports no such workbook for wb remove" do
      Dir.mktmpdir("lexdrill-cli-wb-remove-missing-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))

        exit_code = nil
        expect { exit_code = described_class.new(%w[wb remove nope]).start }.to output(/no workbook named/).to_stderr
        expect(exit_code).to eq(1)
      end
    end

    it "switches the current workbook with wb use" do
      Dir.mktmpdir("lexdrill-cli-wb-use-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        Lexdrill::Workbooks.add("NLP", "abc123")
        Lexdrill::Workbooks.add("gcp", "def456")

        exit_code = nil
        expect do
          exit_code = described_class.new(%w[wb use gcp]).start
        end.to output(/workbook set: "gcp"/).to_stdout
        expect(exit_code).to eq(0)
        expect(Lexdrill::Workbooks.current_name).to eq("gcp")
      end
    end

    it "reports usage on stderr and returns 1 when wb use is given no name" do
      exit_code = nil
      expect { exit_code = described_class.new(%w[wb use]).start }.to output(/usage/).to_stderr
      expect(exit_code).to eq(1)
    end

    it "reports no such workbook for wb use" do
      Dir.mktmpdir("lexdrill-cli-wb-use-missing-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))

        exit_code = nil
        expect { exit_code = described_class.new(%w[wb use nope]).start }.to output(/no workbook named/).to_stderr
        expect(exit_code).to eq(1)
      end
    end

    it "reports usage on stderr and returns 1 for an unrecognized sh subcommand" do
      exit_code = nil
      expect { exit_code = described_class.new(%w[sh bogus]).start }.to output(/usage/).to_stderr
      expect(exit_code).to eq(1)
    end

    it "reports no workbook selected for sh index" do
      Dir.mktmpdir("lexdrill-cli-sh-index-no-wb-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))

        exit_code = nil
        expect { exit_code = described_class.new(%w[sh index]).start }.to output(/no workbook selected/).to_stderr
        expect(exit_code).to eq(1)
      end
    end

    it "lists the tabs in the current workbook, marking the current one with the drill sign" do
      Dir.mktmpdir("lexdrill-cli-sh-index-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        stub_const("Lexdrill::AuthMode::PATH", File.join(dir, ".drill.auth-mode"))
        Lexdrill::Workbooks.add("NLP", "abc123")
        Lexdrill::Workbooks.set_current_sheet("Archive", 1)
        Lexdrill::AuthMode.set("oauth")
        allow(Lexdrill::GoogleAuth).to receive(:ensure_token!).and_return("tok")
        allow(Lexdrill::SheetsClient).to receive(:sheet_titles).with("abc123", "tok").and_return(%w[Sheet1 Archive])
        sign = Lexdrill::Colorizer.paint_yellow(Lexdrill::LineFormatter::SEPARATOR)

        exit_code = nil
        expect do
          exit_code = described_class.new(%w[sh index]).start
        end.to output("  Sheet1\n#{sign} Archive\n").to_stdout
        expect(exit_code).to eq(0)
      end
    end

    it "bare `drill sh` is an alias for `drill sh index`" do
      Dir.mktmpdir("lexdrill-cli-sh-bare-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        stub_const("Lexdrill::AuthMode::PATH", File.join(dir, ".drill.auth-mode"))
        Lexdrill::Workbooks.add("NLP", "abc123")
        Lexdrill::Workbooks.set_current_sheet("Sheet1", 0)
        Lexdrill::AuthMode.set("oauth")
        allow(Lexdrill::GoogleAuth).to receive(:ensure_token!).and_return("tok")
        allow(Lexdrill::SheetsClient).to receive(:sheet_titles).with("abc123", "tok").and_return(%w[Sheet1])
        sign = Lexdrill::Colorizer.paint_yellow(Lexdrill::LineFormatter::SEPARATOR)

        exit_code = nil
        expect do
          exit_code = described_class.new(["sh"]).start
        end.to output("#{sign} Sheet1\n").to_stdout
        expect(exit_code).to eq(0)
      end
    end

    it "`drill ls` is also an alias for `drill sh index`" do
      Dir.mktmpdir("lexdrill-cli-ls-alias-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        stub_const("Lexdrill::AuthMode::PATH", File.join(dir, ".drill.auth-mode"))
        Lexdrill::Workbooks.add("NLP", "abc123")
        Lexdrill::Workbooks.set_current_sheet("Sheet1", 0)
        Lexdrill::AuthMode.set("oauth")
        allow(Lexdrill::GoogleAuth).to receive(:ensure_token!).and_return("tok")
        allow(Lexdrill::SheetsClient).to receive(:sheet_titles).with("abc123", "tok").and_return(%w[Sheet1])
        sign = Lexdrill::Colorizer.paint_yellow(Lexdrill::LineFormatter::SEPARATOR)

        exit_code = nil
        expect do
          exit_code = described_class.new(["ls"]).start
        end.to output("#{sign} Sheet1\n").to_stdout
        expect(exit_code).to eq(0)
      end
    end

    it "creates a new tab with sh add, making it current when none was selected" do
      Dir.mktmpdir("lexdrill-cli-sh-add-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        stub_const("Lexdrill::AuthMode::PATH", File.join(dir, ".drill.auth-mode"))
        Lexdrill::Workbooks.add("NLP", "abc123")
        Lexdrill::AuthMode.set("oauth")
        allow(Lexdrill::GoogleAuth).to receive(:ensure_token!).and_return("tok")
        allow(Lexdrill::SheetsClient).to receive(:add_sheet).with("abc123", "NewTab", "tok").and_return(7)

        exit_code = nil
        expect do
          exit_code = described_class.new(%w[sh add NewTab]).start
        end.to output(/sheet added: "NewTab"/).to_stdout
        expect(exit_code).to eq(0)
        expect(Lexdrill::Workbooks.current_sheet).to eq("NewTab")
        expect(Lexdrill::Workbooks.current_sheet_id).to eq(7)
      end
    end

    it "sh add does not change an already-selected current sheet" do
      Dir.mktmpdir("lexdrill-cli-sh-add-existing-current-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        stub_const("Lexdrill::AuthMode::PATH", File.join(dir, ".drill.auth-mode"))
        Lexdrill::Workbooks.add("NLP", "abc123")
        Lexdrill::Workbooks.set_current_sheet("Sheet1", 0)
        Lexdrill::AuthMode.set("oauth")
        allow(Lexdrill::GoogleAuth).to receive(:ensure_token!).and_return("tok")
        allow(Lexdrill::SheetsClient).to receive(:add_sheet).and_return(7)

        described_class.new(%w[sh add NewTab]).start

        expect(Lexdrill::Workbooks.current_sheet).to eq("Sheet1")
      end
    end

    it "reports usage on stderr and returns 1 when sh add is given no name" do
      exit_code = nil
      expect { exit_code = described_class.new(%w[sh add]).start }.to output(/usage/).to_stderr
      expect(exit_code).to eq(1)
    end

    it "removes a tab with sh remove" do
      Dir.mktmpdir("lexdrill-cli-sh-remove-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        stub_const("Lexdrill::AuthMode::PATH", File.join(dir, ".drill.auth-mode"))
        Lexdrill::Workbooks.add("NLP", "abc123")
        Lexdrill::AuthMode.set("oauth")
        allow(Lexdrill::GoogleAuth).to receive(:ensure_token!).and_return("tok")
        allow(Lexdrill::SheetsClient).to receive(:find_sheet_id).with("abc123", "OldTab", "tok").and_return(3)
        allow(Lexdrill::SheetsClient).to receive(:delete_sheet).with("abc123", 3, "tok")

        exit_code = nil
        expect do
          exit_code = described_class.new(%w[sh remove OldTab]).start
        end.to output(/sheet removed: "OldTab"/).to_stdout
        expect(exit_code).to eq(0)
        expect(Lexdrill::SheetsClient).to have_received(:delete_sheet).with("abc123", 3, "tok")
      end
    end

    it "reports usage on stderr and returns 1 when sh remove is given no name" do
      exit_code = nil
      expect { exit_code = described_class.new(%w[sh remove]).start }.to output(/usage/).to_stderr
      expect(exit_code).to eq(1)
    end

    it "reports no such tab for sh remove" do
      Dir.mktmpdir("lexdrill-cli-sh-remove-missing-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        stub_const("Lexdrill::AuthMode::PATH", File.join(dir, ".drill.auth-mode"))
        Lexdrill::Workbooks.add("NLP", "abc123")
        Lexdrill::AuthMode.set("oauth")
        allow(Lexdrill::GoogleAuth).to receive(:ensure_token!).and_return("tok")
        allow(Lexdrill::SheetsClient).to receive(:find_sheet_id).and_return(nil)

        exit_code = nil
        expect { exit_code = described_class.new(%w[sh remove NoSuchTab]).start }.to output(/no tab named/).to_stderr
        expect(exit_code).to eq(1)
      end
    end

    it "switches the active tab and pulls its contents with sh use" do
      Dir.mktmpdir("lexdrill-cli-sh-use-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        stub_const("Lexdrill::AuthMode::PATH", File.join(dir, ".drill.auth-mode"))
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "old-word\n")
        Lexdrill::Workbooks.add("NLP", "abc123")
        Lexdrill::AuthMode.set("oauth")
        allow(Lexdrill::GoogleAuth).to receive(:ensure_token!).and_return("tok")
        allow(Lexdrill::SheetsClient).to receive(:find_sheet_id).with("abc123", "Sheet1", "tok").and_return(0)
        allow(Lexdrill::SheetsClient).to receive(:read_column).with("abc123", "Sheet1",
                                                                    "tok").and_return(%w[alpha beta])

        exit_code = nil
        expect do
          exit_code = described_class.new(%w[sh use Sheet1]).start
        end.to output(/pulled 2 word\(s\) from "Sheet1"/).to_stdout
        expect(exit_code).to eq(0)
        expect(Lexdrill::Workbooks.current_sheet).to eq("Sheet1")
        expect(Lexdrill::Workbooks.current_sheet_id).to eq(0)
        expect(File.read(Lexdrill::WordList::PATH)).to eq("alpha\nbeta\n")
      end
    end

    it "reports usage on stderr and returns 1 when sh use is given no name" do
      exit_code = nil
      expect { exit_code = described_class.new(%w[sh use]).start }.to output(/usage/).to_stderr
      expect(exit_code).to eq(1)
    end

    it "`drill use <name>` is also an alias for `drill sh use <name>`" do
      Dir.mktmpdir("lexdrill-cli-use-alias-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        stub_const("Lexdrill::AuthMode::PATH", File.join(dir, ".drill.auth-mode"))
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "old-word\n")
        Lexdrill::Workbooks.add("NLP", "abc123")
        Lexdrill::AuthMode.set("oauth")
        allow(Lexdrill::GoogleAuth).to receive(:ensure_token!).and_return("tok")
        allow(Lexdrill::SheetsClient).to receive(:find_sheet_id).with("abc123", "Sheet1", "tok").and_return(0)
        allow(Lexdrill::SheetsClient).to receive(:read_column).with("abc123", "Sheet1", "tok").and_return(%w[alpha])

        exit_code = nil
        expect do
          exit_code = described_class.new(%w[use Sheet1]).start
        end.to output(/pulled 1 word\(s\) from "Sheet1"/).to_stdout
        expect(exit_code).to eq(0)
        expect(Lexdrill::Workbooks.current_sheet).to eq("Sheet1")
      end
    end

    it "reports usage on stderr and returns 1 when drill use is given no name" do
      exit_code = nil
      expect { exit_code = described_class.new(["use"]).start }.to output(/usage/).to_stderr
      expect(exit_code).to eq(1)
    end

    it "reports no such tab for sh use" do
      Dir.mktmpdir("lexdrill-cli-sh-use-missing-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        stub_const("Lexdrill::AuthMode::PATH", File.join(dir, ".drill.auth-mode"))
        Lexdrill::Workbooks.add("NLP", "abc123")
        Lexdrill::AuthMode.set("oauth")
        allow(Lexdrill::GoogleAuth).to receive(:ensure_token!).and_return("tok")
        allow(Lexdrill::SheetsClient).to receive(:find_sheet_id).and_return(nil)

        exit_code = nil
        expect { exit_code = described_class.new(%w[sh use NoSuchTab]).start }.to output(/no tab named/).to_stderr
        expect(exit_code).to eq(1)
      end
    end

    it "opens the current tab in the browser" do
      Dir.mktmpdir("lexdrill-cli-open-browser-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        Lexdrill::Workbooks.add("NLP", "abc123")
        Lexdrill::Workbooks.set_current_sheet("Sheet1", 5)
        allow(Lexdrill::Browser).to receive(:open)

        exit_code = described_class.new(["open"]).start

        expect(exit_code).to eq(0)
        expect(Lexdrill::Browser).to have_received(:open)
          .with("https://docs.google.com/spreadsheets/d/abc123/edit#gid=5")
      end
    end

    it "opens just the workbook url when no tab is selected yet" do
      Dir.mktmpdir("lexdrill-cli-open-no-sheet-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        Lexdrill::Workbooks.add("NLP", "abc123")
        allow(Lexdrill::Browser).to receive(:open)

        exit_code = described_class.new(["open"]).start

        expect(exit_code).to eq(0)
        expect(Lexdrill::Browser).to have_received(:open).with("https://docs.google.com/spreadsheets/d/abc123/edit")
      end
    end

    it "reports no workbook selected for open" do
      Dir.mktmpdir("lexdrill-cli-open-no-wb-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))

        exit_code = nil
        expect { exit_code = described_class.new(["open"]).start }.to output(/no workbook selected/).to_stderr
        expect(exit_code).to eq(1)
      end
    end

    it "reports no workbook selected for push" do
      Dir.mktmpdir("lexdrill-cli-push-no-wb-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))

        exit_code = nil
        expect { exit_code = described_class.new(["push"]).start }.to output(/no workbook selected/).to_stderr
        expect(exit_code).to eq(1)
      end
    end

    it "reports no sheet selected for push" do
      Dir.mktmpdir("lexdrill-cli-push-no-sheet-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        Lexdrill::Workbooks.add("NLP", "abc123")

        exit_code = nil
        expect { exit_code = described_class.new(["push"]).start }.to output(/no sheet selected/).to_stderr
        expect(exit_code).to eq(1)
      end
    end

    it "pushes just the word list text (no stats) to the active tab, then returns 0" do
      Dir.mktmpdir("lexdrill-cli-push-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        stub_const("Lexdrill::Stats::PATH", File.join(dir, ".drill.stats"))
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        stub_const("Lexdrill::AuthMode::PATH", File.join(dir, ".drill.auth-mode"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "alpha\nbeta\n")
        File.write(Lexdrill::Stats::PATH, JSON.generate("alpha" => 3))
        Lexdrill::Workbooks.add("NLP", "abc123")
        Lexdrill::Workbooks.set_current_sheet("Sheet1", 0)
        Lexdrill::AuthMode.set("oauth")
        allow(Lexdrill::GoogleAuth).to receive(:ensure_token!).and_return("tok")
        allow(Lexdrill::SheetsClient).to receive(:overwrite_sheet)

        exit_code = nil
        expect do
          exit_code = described_class.new(["push"]).start
        end.to output(/pushed 2 word\(s\) to "Sheet1"/).to_stdout
        expect(exit_code).to eq(0)
        expect(Lexdrill::SheetsClient).to have_received(:overwrite_sheet)
          .with("abc123", "Sheet1", [["alpha"], ["beta"]], "tok")
      end
    end

    it "uses the remote (service account) auth mode when configured" do
      Dir.mktmpdir("lexdrill-cli-push-remote-auth-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        stub_const("Lexdrill::AuthMode::PATH", File.join(dir, ".drill.auth-mode"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "alpha\n")
        Lexdrill::Workbooks.add("NLP", "abc123")
        Lexdrill::Workbooks.set_current_sheet("Sheet1", 0)
        Lexdrill::AuthMode.set("remote")
        allow(Lexdrill::ServiceAccountAuth).to receive(:fetch_token!).and_return("sa-tok")
        allow(Lexdrill::GoogleAuth).to receive(:ensure_token!)
        allow(Lexdrill::SheetsClient).to receive(:overwrite_sheet)

        exit_code = described_class.new(["push"]).start

        expect(exit_code).to eq(0)
        expect(Lexdrill::SheetsClient).to have_received(:overwrite_sheet)
          .with("abc123", "Sheet1", [["alpha"]], "sa-tok")
        expect(Lexdrill::GoogleAuth).not_to have_received(:ensure_token!)
      end
    end

    it "reports no auth mode configured for push" do
      Dir.mktmpdir("lexdrill-cli-push-no-auth-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        stub_const("Lexdrill::AuthMode::PATH", File.join(dir, ".drill.auth-mode"))
        Lexdrill::Workbooks.add("NLP", "abc123")
        Lexdrill::Workbooks.set_current_sheet("Sheet1", 0)

        exit_code = nil
        expect { exit_code = described_class.new(["push"]).start }.to output(/no auth mode configured/).to_stderr
        expect(exit_code).to eq(1)
      end
    end

    it "reports the service-account auth error message on stderr and returns 1" do
      Dir.mktmpdir("lexdrill-cli-push-sa-error-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        stub_const("Lexdrill::AuthMode::PATH", File.join(dir, ".drill.auth-mode"))
        Lexdrill::Workbooks.add("NLP", "abc123")
        Lexdrill::Workbooks.set_current_sheet("Sheet1", 0)
        Lexdrill::AuthMode.set("remote")
        allow(Lexdrill::ServiceAccountAuth).to receive(:fetch_token!)
          .and_raise(Lexdrill::ServiceAccountAuth::AuthError, "no service account key found")

        exit_code = nil
        expect { exit_code = described_class.new(["push"]).start }.to output(/no service account key/).to_stderr
        expect(exit_code).to eq(1)
      end
    end

    it "reports a 404 Sheets API error with a helpful hint" do
      Dir.mktmpdir("lexdrill-cli-push-404-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        stub_const("Lexdrill::AuthMode::PATH", File.join(dir, ".drill.auth-mode"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "alpha\n")
        Lexdrill::Workbooks.add("NLP", "abc123")
        Lexdrill::Workbooks.set_current_sheet("Sheet1", 0)
        Lexdrill::AuthMode.set("oauth")
        allow(Lexdrill::GoogleAuth).to receive(:ensure_token!).and_return("tok")
        allow(Lexdrill::SheetsClient).to receive(:overwrite_sheet)
          .and_raise(Lexdrill::SheetsClient::ApiError.new(404, "not found"))

        exit_code = nil
        expect do
          exit_code = described_class.new(["push"]).start
        end.to output(/not found or not accessible/).to_stderr
        expect(exit_code).to eq(1)
      end
    end

    it "reports a network error on stderr and returns 1 for push" do
      Dir.mktmpdir("lexdrill-cli-push-network-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        stub_const("Lexdrill::AuthMode::PATH", File.join(dir, ".drill.auth-mode"))
        Lexdrill::Workbooks.add("NLP", "abc123")
        Lexdrill::Workbooks.set_current_sheet("Sheet1", 0)
        Lexdrill::AuthMode.set("oauth")
        allow(Lexdrill::GoogleAuth).to receive(:ensure_token!)
          .and_raise(Lexdrill::HTTPClient::NetworkError, "getaddrinfo failed")

        exit_code = nil
        expect { exit_code = described_class.new(["push"]).start }.to output(/network error/).to_stderr
        expect(exit_code).to eq(1)
      end
    end

    it "reports no workbook selected for pull" do
      Dir.mktmpdir("lexdrill-cli-pull-no-wb-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))

        exit_code = nil
        expect { exit_code = described_class.new(["pull"]).start }.to output(/no workbook selected/).to_stderr
        expect(exit_code).to eq(1)
      end
    end

    it "reports no sheet selected for pull" do
      Dir.mktmpdir("lexdrill-cli-pull-no-sheet-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        Lexdrill::Workbooks.add("NLP", "abc123")

        exit_code = nil
        expect { exit_code = described_class.new(["pull"]).start }.to output(/no sheet selected/).to_stderr
        expect(exit_code).to eq(1)
      end
    end

    it "replaces the local word list with the active tab's column A, then returns 0" do
      Dir.mktmpdir("lexdrill-cli-pull-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        stub_const("Lexdrill::AuthMode::PATH", File.join(dir, ".drill.auth-mode"))
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "old-word\n")
        Lexdrill::Workbooks.add("NLP", "abc123")
        Lexdrill::Workbooks.set_current_sheet("Sheet1", 0)
        Lexdrill::AuthMode.set("oauth")
        allow(Lexdrill::GoogleAuth).to receive(:ensure_token!).and_return("tok")
        allow(Lexdrill::SheetsClient).to receive(:read_column).and_return(%w[alpha beta])

        exit_code = nil
        expect do
          exit_code = described_class.new(["pull"]).start
        end.to output(/pulled 2 word\(s\) from "Sheet1"/).to_stdout
        expect(exit_code).to eq(0)
        expect(Lexdrill::SheetsClient).to have_received(:read_column).with("abc123", "Sheet1", "tok")
        expect(File.read(Lexdrill::WordList::PATH)).to eq("alpha\nbeta\n")
      end
    end

    it "reports on stderr and returns 1 when the sheet has no data to pull" do
      Dir.mktmpdir("lexdrill-cli-pull-empty-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        stub_const("Lexdrill::AuthMode::PATH", File.join(dir, ".drill.auth-mode"))
        Lexdrill::Workbooks.add("NLP", "abc123")
        Lexdrill::Workbooks.set_current_sheet("Sheet1", 0)
        Lexdrill::AuthMode.set("oauth")
        allow(Lexdrill::GoogleAuth).to receive(:ensure_token!).and_return("tok")
        allow(Lexdrill::SheetsClient).to receive(:read_column).and_return([])

        exit_code = nil
        expect { exit_code = described_class.new(["pull"]).start }.to output(/no data to pull/).to_stderr
        expect(exit_code).to eq(1)
      end
    end

    it "reports the auth error message on stderr and returns 1 for pull" do
      Dir.mktmpdir("lexdrill-cli-pull-auth-error-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        stub_const("Lexdrill::AuthMode::PATH", File.join(dir, ".drill.auth-mode"))
        Lexdrill::Workbooks.add("NLP", "abc123")
        Lexdrill::Workbooks.set_current_sheet("Sheet1", 0)
        Lexdrill::AuthMode.set("oauth")
        allow(Lexdrill::GoogleAuth).to receive(:ensure_token!)
          .and_raise(Lexdrill::GoogleAuth::AuthError, "access denied")

        exit_code = nil
        expect { exit_code = described_class.new(["pull"]).start }.to output(/access denied/).to_stderr
        expect(exit_code).to eq(1)
      end
    end

    it "reports a Sheets API error on stderr and returns 1 for pull" do
      Dir.mktmpdir("lexdrill-cli-pull-api-error-spec") do |dir|
        stub_const("Lexdrill::Workbooks::PATH", File.join(dir, ".drill.workbooks.json"))
        stub_const("Lexdrill::AuthMode::PATH", File.join(dir, ".drill.auth-mode"))
        Lexdrill::Workbooks.add("NLP", "abc123")
        Lexdrill::Workbooks.set_current_sheet("NoSuchTab", 0)
        Lexdrill::AuthMode.set("oauth")
        allow(Lexdrill::GoogleAuth).to receive(:ensure_token!).and_return("tok")
        allow(Lexdrill::SheetsClient).to receive(:read_column)
          .and_raise(Lexdrill::SheetsClient::ApiError.new(400, "Unable to parse range"))

        exit_code = nil
        expect { exit_code = described_class.new(["pull"]).start }.to output(/real tab/).to_stderr
        expect(exit_code).to eq(1)
      end
    end
  end
end
