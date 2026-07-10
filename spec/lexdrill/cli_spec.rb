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
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "alpha\nbeta\n")

        exit_code = nil
        expect { exit_code = described_class.new(["next"]).start }.to output("alpha\n").to_stdout
        expect(exit_code).to eq(0)
      end
    end

    it "reports on stderr and returns 1 when there are no words" do
      Dir.mktmpdir("lexdrill-cli-next-empty-spec") do |dir|
        stub_const("Lexdrill::WordList::PATH", File.join(dir, ".drill.txt"))
        stub_const("Lexdrill::WordList::COUNTER_PATH", File.join(dir, ".drill.counter"))
        stub_const("Lexdrill::Toggle::PATH", File.join(dir, ".drill.disabled"))
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
        Lexdrill::WordList.instance_variable_set(:@words, nil)
        File.write(Lexdrill::WordList::PATH, "alpha\nbeta\n")
        Lexdrill::Toggle.stop

        exit_code = nil
        expect { exit_code = described_class.new(["next"]).start }.to output("alpha\n").to_stdout
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
        Lexdrill::WordList.instance_variable_set(:@words, nil)

        exit_code = nil
        expect { exit_code = described_class.new(["inspect"]).start }.to output(/Words file:/).to_stdout
        expect(exit_code).to eq(0)
      end
    end
  end
end
