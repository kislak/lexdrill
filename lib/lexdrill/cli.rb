# frozen_string_literal: true

class Lexdrill::CLI
  COMMANDS = {
    print_version: %w[version --version -v],
    print_help: %w[help --help -h],
    run_next: %w[next]
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
    HELP
    0
  end

  def run_next
    word = Lexdrill::WordList.next
    return print_no_words(Lexdrill::WordList::PATH) unless word

    puts word
    0
  end

  def print_no_words(path)
    warn "lexdrill: no words found in #{path}"
    1
  end

  def print_unknown_command(command)
    warn "lexdrill: unknown command #{command.inspect}"
    print_help
    1
  end
end
