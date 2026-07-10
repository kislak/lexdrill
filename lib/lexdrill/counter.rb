# frozen_string_literal: true

class Lexdrill::Counter
  attr_reader :path

  def initialize(path)
    @path = path
  end

  def value
    return 0 unless File.exist?(path)

    File.read(path).strip.to_i
  end

  def increment
    File.write(path, (value + 1).to_s)
  end

  def reset
    File.write(path, "0")
  end

  # The current value, unless it's out of bounds for the given size, in
  # which case it resets to 0 first.
  def bounded_value(size)
    current = value
    return current if current < size

    reset
    0
  end
end
