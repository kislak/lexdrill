# frozen_string_literal: true

# Wraps text in an ANSI color code. `paint_by_count` maps a word's show
# count onto a blue -> red truecolor gradient, one step per
# Lexdrill::Stats::BUCKET_SIZE shows, so a word's color reflects how many
# times it's been drilled — unless `drill color random` is set (see
# Lexdrill::Color), in which case a vivid random color is used every time
# instead.
module Lexdrill::Colorizer
  YELLOW = 33
  GRADIENT_STEPS = Lexdrill::Stats::GRADUATION_THRESHOLD / Lexdrill::Stats::BUCKET_SIZE
  HUE_DEGREES = 360
  # Which of {peak, trough, 0} each RGB channel takes in each 60-degree hue
  # sextant, walking red -> yellow -> green -> cyan -> blue -> magenta -> red.
  SEXTANT_CHANNELS = [
    %i[peak trough zero],
    %i[trough peak zero],
    %i[zero peak trough],
    %i[zero trough peak],
    %i[trough zero peak],
    %i[peak zero trough]
  ].freeze

  def self.paint_yellow(text)
    wrap(text, YELLOW)
  end

  def self.paint_by_count(text, count)
    code = Lexdrill::Color.random? ? random_code : gradient_code(count)
    wrap(text, code)
  end

  def self.gradient_code(count)
    last_bucket = GRADIENT_STEPS - 1
    bucket = [count / Lexdrill::Stats::BUCKET_SIZE, last_bucket].min
    fraction = bucket.fdiv(last_bucket)
    red = (fraction * 255).round
    blue = ((1 - fraction) * 255).round
    "38;2;#{red};0;#{blue}"
  end
  private_class_method :gradient_code

  def self.random_code
    red, green, blue = hue_to_rgb(Kernel.rand(HUE_DEGREES))
    "38;2;#{red};#{green};#{blue}"
  end
  private_class_method :random_code

  # Full-saturation, full-value HSV -> RGB, for a vivid random color.
  def self.hue_to_rgb(hue)
    peak = 255
    trough = hue_trough(hue, peak)
    rgb_for_sextant(hue / 60, peak, trough)
  end
  private_class_method :hue_to_rgb

  def self.hue_trough(hue, peak)
    (peak * (1 - (((hue / 60.0) % 2) - 1).abs)).round
  end
  private_class_method :hue_trough

  def self.rgb_for_sextant(sextant, peak, trough)
    channel_values = { peak: peak, trough: trough, zero: 0 }
    SEXTANT_CHANNELS[sextant % SEXTANT_CHANNELS.size].map { |channel| channel_values.fetch(channel) }
  end
  private_class_method :rgb_for_sextant

  def self.wrap(text, code)
    "\e[#{code}m#{text}\e[0m"
  end
  private_class_method :wrap
end
