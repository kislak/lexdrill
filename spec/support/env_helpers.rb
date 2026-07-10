# frozen_string_literal: true

module EnvHelpers
  # Temporarily overrides ENV vars for the duration of the block, restoring
  # (or removing) the previous values afterwards.
  def with_env(overrides)
    previous = overrides.keys.to_h { |key| [key, ENV.fetch(key, nil)] }
    overrides.each { |key, value| ENV[key] = value }
    yield
  ensure
    previous.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end
end

RSpec.configure do |config|
  config.include EnvHelpers
end
