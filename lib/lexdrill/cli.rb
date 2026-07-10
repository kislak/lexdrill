# frozen_string_literal: true

class Lexdrill::CLI
  COMMANDS = {
    print_version: %w[version --version -v],
    print_help: %w[help --help -h],
    run_next: %w[next],
    run_hook: %w[hook],
    run_start: %w[start],
    run_stop: %w[stop],
    run_inspect: %w[inspect],
    run_beat: %w[beat],
    run_beat_alias: %w[polka waltz rock jazz jiga balkan samba]
  }.freeze

  def self.start(argv = ARGV)
    new(argv).start
  end

  def initialize(argv)
    @argv = argv
  end

  attr_reader :argv

  def start
    command = argv.first || "help"
    handler = COMMANDS.find { |_method, options| options.include?(command) }&.first
    return print_unknown_command(command) unless handler

    send(handler)
  end

  private

  def print_version
    puts Lexdrill::VERSION
    0
  end

  def print_help
    puts <<~HELP
      drill #{Lexdrill::VERSION} — vocabulary drilling in your terminal

      Usage:
        drill version   Print the gem version
        drill help      Show this help
        drill next      Print the current word and advance
        drill hook <zsh|bash>   Print the shell integration snippet
        drill start     Resume drilling (undoes stop)
        drill stop      Pause drilling everywhere until `start`
        drill inspect   Show the active config/counter/toggle state
        drill beat <2-8> [repetitions]   Set the rhythm (repetitions defaults to 8)
        drill beat none                 Disable the rhythm
        drill polka|waltz|rock|jazz|jiga|balkan|samba [repetitions]
                        Shorthand for a fixed loop size (2 through 8, in order)
    HELP
    0
  end

  def run_next
    word = Lexdrill::WordList.next
    return print_no_words(Lexdrill::WordList::PATH) unless word

    puts Lexdrill::Colorizer.paint(Lexdrill::LineFormatter.format(word))
    0
  end

  def print_no_words(path)
    warn "drill: no words found in #{path}"
    1
  end

  def run_hook
    shell = argv[1]
    return print_hook_usage unless shell

    print_hook_snippet(shell)
  end

  def print_hook_usage
    warn "usage: drill hook <zsh|bash>"
    1
  end

  def print_hook_snippet(shell)
    puts Lexdrill::ShellSnippet.for(shell)
    0
  rescue ArgumentError => error
    warn "drill: #{error.message}"
    1
  end

  def run_start
    Lexdrill::Toggle.start
    0
  end

  def run_stop
    Lexdrill::Toggle.stop
    0
  end

  def run_inspect
    puts Lexdrill::Inspector.report
    0
  end

  def run_beat
    arg = argv[1]
    return print_beat_usage unless arg
    return clear_beat if arg == "none"

    set_beat(arg.to_i, Lexdrill::Beat.repetitions_or_default(argv[2]))
  end

  def run_beat_alias
    loop_size = Lexdrill::Beat::ALIASES.fetch(argv.first)
    set_beat(loop_size, Lexdrill::Beat.repetitions_or_default(argv[1]))
  end

  def set_beat(loop_size, repetitions)
    return print_invalid_loop_size unless Lexdrill::Beat.valid_loop_size?(loop_size)
    return print_invalid_repetitions unless repetitions.positive?

    Lexdrill::Beat.set(loop_size, repetitions)
    0
  end

  def clear_beat
    Lexdrill::Beat.clear
    0
  end

  def print_beat_usage
    warn "usage: drill beat <#{Lexdrill::Beat::MIN_LOOP_SIZE}-#{Lexdrill::Beat::MAX_LOOP_SIZE}> " \
         "<repetitions> | drill beat none"
    1
  end

  def print_invalid_loop_size
    warn "drill: loop size must be between #{Lexdrill::Beat::MIN_LOOP_SIZE} and #{Lexdrill::Beat::MAX_LOOP_SIZE}"
    1
  end

  def print_invalid_repetitions
    warn "drill: repetitions must be a positive number"
    1
  end

  def print_unknown_command(command)
    warn "drill: unknown command #{command.inspect}"
    print_help
    1
  end
end
