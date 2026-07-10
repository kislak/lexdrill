# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"
require "reek/rake/task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new(:rubocop)

Reek::Rake::Task.new(:reek) do |t|
  t.fail_on_error = true
end

desc "Run RuboCop and Reek"
task lint: %i[rubocop reek]

task default: %i[spec lint]
