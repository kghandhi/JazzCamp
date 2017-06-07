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

PIANO_TYPE = [
  :piano,
  :vibes,
]

AMPY_TYPE = [
  :guitar,
  :bass,
]

WOODWINDS = [
  :clarinet,
  :flute,
  :saxophone,
]

BRASS = [
  :trumpet,
  :trombone,
]


COMBO_UNIQUE_INSTRUMENTS = [
  [:cello, nil],
  [:clarinet, nil],
  [:flute, nil],
  [:saxophone, :baritone],
  [:saxophone, :soprano],
  [:trombone, nil],
  [:trumpet, nil],
  [:viola, nil],
  [:violin, nil],
]
