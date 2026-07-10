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
    run_beat_alias: %w[polka waltz rock jazz jiga balkan samba],
    run_format: %w[format],
    run_add: %w[add],
    run_list: %w[list],
    run_open: %w[open],
    run_stats: %w[stats]
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
        drill format simple|full   Set the output style (simple is the default)
        drill add <text>   Append a new item to the end of the list
        drill list         Print all items in the list, numbered
        drill open         Open the list file in $EDITOR/$VISUAL (falls back to vi)
        drill stats        Show how many times each item has been shown
    HELP
    0
  end

  def run_next
    word = Lexdrill::WordList.next
    return print_no_words(Lexdrill::WordList::PATH) unless word

    puts colored_line(word)
    0
  end

  def colored_line(word)
    text = Lexdrill::LineFormatter.format(word)
    return text if Lexdrill::Format.simple?

    Lexdrill::Colorizer.paint(text)
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

  def run_format
    mode = argv[1]
    return print_format_usage unless Lexdrill::Format::VALID.include?(mode)

    Lexdrill::Format.set(mode)
    0
  end

  def print_format_usage
    warn "usage: drill format <#{Lexdrill::Format::VALID.join('|')}>"
    1
  end

  def run_add
    text = argv[1..].join(" ")
    return print_add_usage if text.empty?

    File.open(Lexdrill::WordList::PATH, "a", encoding: "UTF-8") { |file| file.puts(text) }
    puts "added: #{text}"
    0
  end

  def print_add_usage
    warn "usage: drill add <text>"
    1
  end

  def run_list
    words = Lexdrill::WordList.words
    return print_no_words(Lexdrill::WordList::PATH) if words.empty?

    words.each_with_index { |word, index| puts "#{index + 1}. #{word}" }
    0
  end

  def run_open
    editor_cmd = (ENV["VISUAL"] || ENV["EDITOR"] || "vi").split
    system(*editor_cmd, Lexdrill::WordList::PATH) ? 0 : 1
  end

  def run_stats
    words = Lexdrill::WordList.words
    return print_no_words(Lexdrill::WordList::PATH) if words.empty?

    counts = Lexdrill::Stats.counts
    words.each_with_index { |word, index| puts "#{index + 1}. #{word} (#{counts.fetch(word, 0)})" }
    0
  end

  def print_unknown_command(command)
    warn "drill: unknown command #{command.inspect}"
    print_help
    1
  end
end
