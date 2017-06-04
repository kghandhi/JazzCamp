require_relative "student"
require_relative "classroom"
require_relative "instruments"

THEORY_BUCKETS = {
  1 => (0..14),
  2 => (15..29),
  3 => (30..44),
  4 => (45..59),
  5 => (60..62)
}

class Camp
  attr_accessor :students
  attr_accessor :students_by_instrument

  def initialize(name)
    @name = name
    @students = []
    @students_by_instrument = _empty_students_by_instrument
  end

  def _empty_students_by_instrument
    Hash[POSSIBLE_INSTRUMENTS.map { |instrument| [instrument, []]}]
  end

  def schedule_theory_musicianship_classes
    # Theory Class for drummers and vocalists
    # Drummers go in Drum theory (late) if they do not have a theory score
    @students_by_instrument[:drums].each do |drummer|
      if drummer.theory_score == 0
        drummer.theory_class = :drum_theory
      else
        drummer.theory_class = "late_theory_#{theory_level(drummer)}".to_sym
      end
    end

    # vocalists must be in early theory
    @students_by_instrument[:voice].each do |vocalist|
      vocalist.theory_class = "early_theory_#{theory_level(vocalist)}".to_sym
    end

    # Musicianship class for drummers and vocalists
    @students_by_instrument[:drums].each do |drum_kid|
      drum_kid.musicianship_class = :drum_rudiments
    end
    @students_by_instrument[:voice].each do |voice_kid|
      voice_kid.musicianship_class = :vocal_musicianship
    end

    rest = @students.select do |student|
      student.musicianship_class.nil? && student.theory_class.nil?
    end

    early_theory, late_theory = _zipper_split(rest.sort_by(&:theory_score))

    early_theory.map { |student|
      student.theory_class = "early_theory_#{theory_level(student)}".to_sym
    }
    late_theory.map { |student|
      student.theory_class = "late_theory_#{theory_level(student)}".to_sym
    }

    # students with early theory have late musicianship and visa versa
    _schedule_musicianship(:late, early_theory)
    _schedule_musicianship(:early, late_theory)
  end

  def _in_range(max_score, potential)
    (max_score - potential.musicianship_score).abs <= 1
  end

  def fill_positions(full_set, positions_to_fill, max_mus_score)
    instruments = []

    while instruments.length < positions_to_fill && full_set.length > 0 && _in_range(max_mus_score, full_set.last)
      instruments << full_set.pop
    end
    instruments
  end

  def _schedule_musicianship(period, students)
    piano_type = students.select { |student| PIANO_TYPE.include?(student.instrument) }
    piano_type.sort_by!(&:musicianship_score)

    ampy_type = students.select { |student| AMPY_TYPE.include?(student.instrument) }
    ampy_type.sort_by!(&:musicianship_score)

    other_type = students - piano_type - ampy_type
    other_type.sort_by!(&:musicianship_score)

    # should shuffle
    CLASSROOMS.sort_by! { |room| - (room.num_pianos + room.num_amps) }
    CLASSROOMS.each_with_index do |room,level|
      max_mus_score = [piano_type, other_type, ampy_type].map do |ss|
        ss.length > 0 ? ss.last.musicianship_score : 0
      end.max

      pianos = fill_positions(piano_type, room.num_pianos, max_mus_score)

      potential_amps = room.num_amps
      potential_amps += pianos.length != room.num_pianos ? room.num_pianos - pianos.length : 0
      amps = fill_positions(ampy_type, potential_amps, max_mus_score)

      potential_other = room.capacity - pianos.length - amps.length
      others = fill_positions(other_type, potential_other, max_mus_score)

      class_label = "#{period}_musicianship_#{level + 1}".to_sym
      (pianos + amps + others).map { |student| student.musicianship_class = class_label }
    end
  end

  def theory_level(student)
    (THEORY_BUCKETS.select { |level| THEORY_BUCKETS[level].include?(student.theory_score) }).first[0]
  end

  def schedule_masterclass
    # TODO fix
    @students_by_instrument[:clarinet].each { |clarinet_kid| clarinet_kid.masterclass = :clarinet_masterclass }
    @students_by_instrument[:flute].each { |flute_kid| flute_kid.masterclass = :flute_masterclass }
    @students_by_instrument[:voice].each { |vocal_kid| vocal_kid.masterclass = :voice_masterclass}
    STRINGS.each do |string_instrument|
      @students_by_instrument[string_instrument].each { |string_kid| string_kid.masterclass = :string_masterclass }
    end

    [:bass, :drums, :guitar, :piano, :trombone, :trumpet,].each do |two_class_instrument|
      _split_into_masterclasses(two_class_instrument, 2)
    end
    _split_into_masterclasses(:saxophone, 4)
  end

  def _split_into_masterclasses(instrument, num)
    students = @students_by_instrument[instrument]
    students += @students_by_instrument[:vibes] if instrument == :piano

    groups = _in_groups(students, num)
    groups.each do |level,students_in_level|
      class_name = (instrument.to_s + "_masterclass_#{level + 1}").to_sym
      students_in_level.map { |student| student.masterclass = class_name }
    end
    # if num == 2
    #   levels = {
    #     1 => (0...3),
    #     2 => (3..6),
    #   }
    # elsif students.any? { |student| student.combo_score == 6 }
    # # for sax consider just splitting evenly?
    #   levels = {
    #     1 => (0...2),
    #     2 => (2...4),
    #     3 => (4...6),
    #     4 => (6..6),
    #   }
    # else
    #   levels = {
    #     1 => (0...2),
    #     2 => (2...4),
    #     3 => (4...5),
    #     4 => (5..6),
    #   }
    # end
    #
    # students.each do |student|
    #   level = (levels.select { |level| levels[level].include?(student.combo_score) }).first[0]
    #
    #   student.masterclass = (instrument.to_s + "_masterclass_#{level}").to_sym
    # end
  end

  def _sort_by_two(students)
    # sort by the highness of their combo score and the lowness of their fractional in_rank ([0,1] rank / # in)
    students.sort_by do |student|
      num_instruments_in_family = total_instruments(student.instrument)
      relative_rank = student.in_rank.to_f / num_instruments_in_family.to_f
      [- relative_rank, student.combo_score]
    end.reverse
  end

  def total_instruments(instrument)
    # TODO memoize
    family = ([
      STRINGS,
      BRASS,
      WOODWINDS,
      [:vibes],
      [:piano],
      [:guitar],
      [:bass],
      [:drums]
    ].select { |family| family.include?(instrument) }).first

    family.inject(0) {|sum,in_type| sum += @students_by_instrument[in_type].length }
  end

  def schedule_combo_split_classes
    # do not handle vocalists
    @students_by_instrument[:voice].each { |student| student.combo = "vocal_combo" }
    @students_by_instrument[:voice].each { |student| student.split = "vocal_split" }

    drums = @students_by_instrument[:drums].sort_by(&:in_rank)
    bass = @students_by_instrument[:bass].sort_by(&:in_rank) # this is short
    guitars = @students_by_instrument[:guitar].sort_by(&:in_rank)
    pianos = @students_by_instrument[:piano].sort_by(&:in_rank)

    horns = @students - @students_by_instrument[:voice] - drums - bass - guitars - pianos
    horns = _sort_by_two(horns)

    early_drums, late_drums = _zipper_split(drums)
    early_bass, late_bass = _zipper_split(bass)
    early_guitars, late_guitars = _zipper_split(guitars)
    early_pianos, late_pianos = _zipper_split(pianos)
    early_horns, late_horns = _zipper_split(horns)

    early_students = early_drums + early_bass + early_guitars + early_pianos + early_horns
    late_students = late_drums + late_bass + late_guitars + late_pianos + late_horns

    _schedule_split(:early, early_students)
    _schedule_split(:late, late_students)

    _schedule_combo(:late, early_drums, early_bass, early_guitars, early_pianos, early_horns)
    _schedule_combo(:early, late_drums, late_bass, late_guitars, late_pianos, late_horns)
  end

  def _schedule_combo(period, drummers, bassists, guitarists, pianos, horns)
    horn_groups = _in_groups(horns, drummers.length)
    piano_groups = _in_groups(pianos, drummers.length)
    guitar_groups = _in_groups(guitarists, drummers.length)
    drummers.reverse!
    bassists.reverse!

    CLASSROOMS.take(drummers.length).each_with_index do |room,level|
      curr_combo = []
      curr_combo << drummers.pop if drummers.length > 0
      if bassists.length > 0 && curr_combo.map { |s| s.combo_score.floor}.include?(bassists.last.combo_score.floor)
        curr_combo << bassists.pop if bassists.length > 0
      end

      curr_combo += horn_groups[level]
      curr_combo += piano_groups[level]
      curr_combo += guitar_groups[level]

      class_label = "#{period}_combo_#{level + 1}".to_sym
      curr_combo.map { |student| student.combo = class_label }
    end
  end

  def _schedule_split(period, students)
    students.sort_by!(&:combo_score)

    _in_groups(students, 3).each do |level,students|
      class_name = "#{period}_split_#{level + 1}".to_sym
      students.map { |student| student.split = class_name }
    end
  end

  def _zipper_split(sorted_students)
    grouped = sorted_students.each_with_index.group_by { |student,rank| rank % 2 }
    [grouped[0].map(&:first), grouped[1].map(&:first)]
  end

  def _in_groups(students, number)
    division = students.length / number
    modulo = students.length % number

    groups = {}
    start = 0

    number.times do |class_level|
      class_size = division + (modulo > 0 && modulo > class_level ? 1 : 0)
      groups[class_level] = students[start...(start + class_size + 1)]
      start += class_size
    end
    groups
  end
end
