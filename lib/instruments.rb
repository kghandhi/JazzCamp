POSSIBLE_INSTRUMENTS = [
  :bass,
  :cello,
  :clarinet,
  :drums,
  :flute,
  :guitar,
  :piano,
  :saxophone,
  :trombone,
  :trumpet,
  :vibes,
  :viola,
  :violin,
  :voice,
]

POSSIBLE_VARIANTS = Hash.new([])
POSSIBLE_VARIANTS[:bass] = [:electric, :acoustic]
POSSIBLE_VARIANTS[:saxophone] = [:alto, :baritone, :soprano, :tenor]

STRINGS = [
  :cello,
  :viola,
  :violin,
]

RHYTHMS = [
  :bass,
  :guitar,
  :piano,
  :vibes,
]

PIANO_TYPE = [
  :piano,
  :vibes,
]

AMPY_TYPE = [
  :guitar,
  :bass,
]

woodwinds = [
  :clarinet,
  :flute,
  :saxophone,
]

