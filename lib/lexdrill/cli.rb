# frozen_string_literal: true

class Lexdrill::CLI
  COMMANDS = {
    print_version: %w[version --version -v],
    print_help: %w[help --help -h],
    run_next: %w[next],
    run_hook: %w[hook],
    run_start: %w[start],
    run_stop: %w[stop]
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
      lexdrill #{Lexdrill::VERSION} — vocabulary drilling in your terminal

      Usage:
        lexdrill version   Print the gem version
        lexdrill help      Show this help
        lexdrill next      Print the current word and advance
        lexdrill hook <zsh|bash>   Print the shell integration snippet
        lexdrill start     Resume drilling (undoes stop)
        lexdrill stop      Pause drilling everywhere until `start`
    HELP
    0
  end

  def run_next
    return 0 unless Lexdrill::Toggle.enabled?

    word = Lexdrill::WordList.next
    return print_no_words(Lexdrill::WordList::PATH) unless word

    puts word
    0
  end

  def print_no_words(path)
    warn "lexdrill: no words found in #{path}"
    1
  end

  def run_hook
    shell = argv[1]
    return print_hook_usage unless shell

    print_hook_snippet(shell)
  end

  def print_hook_usage
    warn "usage: lexdrill hook <zsh|bash>"
    1
  end

  def print_hook_snippet(shell)
    puts Lexdrill::ShellSnippet.for(shell)
    0
  rescue ArgumentError => error
    warn "lexdrill: #{error.message}"
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

  def print_unknown_command(command)
    warn "lexdrill: unknown command #{command.inspect}"
    print_help
    1
  end
end
