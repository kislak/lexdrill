# frozen_string_literal: true

# The starter list seeded into ~/.drill.txt on first run, when neither an
# LEXDRILL_PATH override nor a project-local .drill.txt exists yet.
module Lexdrill::DefaultWords
  WORDS = [
    "The map is not the territory",
    "Respect for other people's model of the world",
    "Mind and body are parts of the same system",
    "You cannot not communicate",
    "The meaning of your communication is the response you get",
    "People operate out of the best choice available to them",
    "Every behavior has a positive intention",
    "People have all the resources they need to succeed",
    "There is no failure only feedback",
    "If what you are doing isn't working do something else",
    "The person with the most flexibility controls the system",
    "Choice is better than no choice",
    "If one person can do something anyone can learn to do it",
    "Modeling successful performance leads to excellence",
    "All procedures should increase wholeness and choice",
    "Individuals are not their behaviors",
    "Resistance in a listener is a sign of a lack of flexibility in the communicator",
    "We process all information through our five senses",
    "Clean feedback is the breakfast of champions",
    "Possible in the world is possible for me it is only a matter of how"
  ].freeze

  TEXT = "#{WORDS.join("\n")}\n".freeze
end
