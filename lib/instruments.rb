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

MAX_PIANO_PER_MUSICIANSHIP = 2
MAX_GUITAR_PER_MUSICIANSHIP = 2
MAX_BASS_PER_MUSICIANSHIP = 2
MAX_SAX_PER_MUSICIANSHIP = 5

MAX_SAX_PER_COMBO = 3
MAX_BRASS_PER_COMBO = 2
MAX_GUITAR_PER_COMBO = 1

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
