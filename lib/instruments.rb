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

woodwinds = [
  :clarinet,
  :flute,
  :saxophone,
]
