# frozen_string_literal: true

# Subcommand dispatcher for the `lexdrill` executable.
class Lexdrill::CLI
  COMMANDS = {
    print_version: %w[version --version -v],
    print_help: %w[help --help -h]
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
    HELP
    0
  end

  def print_unknown_command(command)
    warn "lexdrill: unknown command #{command.inspect}"
    print_help
    1
  end
end
