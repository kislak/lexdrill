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
    run_stats: %w[stats],
    run_rand: %w[rand]
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
        drill beat rand                 Ignore the counter/rhythm; show a random item each time
        drill polka|waltz|rock|jazz|jiga|balkan|samba [repetitions]
                        Shorthand for a fixed loop size (2 through 8, in order)
        drill format simple|full   Set the output style (simple is the default)
        drill add <text>   Append a new item to the end of the list
        drill list         Print items as <count>\t<phrase>, tab-separated, highest count first
        drill open         Open the list file in $EDITOR/$VISUAL (falls back to vi)
        drill stats        Show how many times each item has been shown
        drill rand <n>     drill next shows a word ~1-in-n times (n=1 is every time)
    HELP
    0
  end

  def run_next
    return 0 if Lexdrill::Rand.skip?

    word = Lexdrill::WordList.next
    return print_next_failure unless word

    puts colored_line(word)
    0
  end

  def print_next_failure
    return print_no_words(Lexdrill::WordList::PATH) if Lexdrill::WordList.words.empty?

    print_all_graduated
  end

  def print_all_graduated
    warn "drill: every item has reached #{Lexdrill::Stats::GRADUATION_THRESHOLD} shows — nothing left to drill"
    1
  end

  def colored_line(word)
    text = Lexdrill::LineFormatter.format(word)
    return text if Lexdrill::Format.simple?

    count = Lexdrill::Stats.counts.fetch(word, 0)
    Lexdrill::Colorizer.paint_by_count(text, count)
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
    return set_rand_beat if arg == "rand"

    set_beat(arg.to_i, Lexdrill::Beat.repetitions_or_default(argv[2]))
  end

  def set_rand_beat
    Lexdrill::Beat.set_rand
    0
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
         "<repetitions> | drill beat none | drill beat rand"
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

    counts = Lexdrill::Stats.counts
    pairs = words.map { |word| [counts.fetch(word, 0), word] }.sort_by { |count, _word| -count }
    pairs.each { |count, word| puts "#{count}\t#{word}" }
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

  def run_rand
    denominator = argv[1].to_s.to_i
    return print_rand_usage unless denominator.positive?

    Lexdrill::Rand.set(denominator)
    0
  end

  def print_rand_usage
    warn "usage: drill rand <n>   (drill next shows a word ~1-in-n times; n=1 is every time)"
    1
  end

  def print_unknown_command(command)
    warn "drill: unknown command #{command.inspect}"
    print_help
    1
  end
end
