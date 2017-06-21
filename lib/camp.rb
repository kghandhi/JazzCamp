# require 'pry'
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
MAX_SAX_PER_COMBO = 3
MAX_BRASS_PER_COMBO = 2

class Camp
  attr_accessor :students
  attr_accessor :students_by_instrument

  def initialize(name)
    @name = name
    @students = []
    @students_by_instrument = _empty_students_by_instrument
    @counts_by_family = {
      :strings => num_students_in_family(STRINGS),
      :brass => num_students_in_family(BRASS),
      :woodwinds => num_students_in_family(WOODWINDS),
      :vibes => num_students_in_family([:vibes]),
      :piano => num_students_in_family([:piano]),
      :guitar => num_students_in_family([:guitar]),
      :bass => num_students_in_family([:bass]),
      :drums => num_students_in_family([:drums]),
    }
  end

  def _empty_students_by_instrument
    Hash[POSSIBLE_INSTRUMENTS.map { |instrument| [instrument, []]}]
  end

  def num_students_in_family(family)
    family.reduce(0) { |tot_in_family,instrument|
      tot_in_family += students_by_instrument[instrument].reduce(0) { |sum,xs| sum += xs.length }
    }
  end

  def total_instruments_in_family(instrument)
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
    @counts_by_family[family]
  end

  def schedule_theory_musicianship_classes
    # Theory Class for drummers and vocalists
    # Drummers go in Drum theory (late) if they do not have a theory score
    @students_by_instrument[:drums].each do |drummer|
      if drummer.theory_score == 0
        drummer.theory_class = :late_drum_theory
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
      drum_kid.musicianship_class = :early_drum_rudiments
    end
    @students_by_instrument[:voice].each do |voice_kid|
      voice_kid.musicianship_class = :late_vocal_musicianship
    end

    rest = @students.dup.select do |student|
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

  def _pull_qualified(full_set, positions_to_fill, max_mus_score)
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

    CLASSROOMS.sort_by! { |room| - (room.num_pianos + room.num_amps) }
    CLASSROOMS.each_with_index do |room,level|
      max_mus_score = [piano_type, other_type, ampy_type].map do |ss|
        ss.length > 0 ? ss.last.musicianship_score : 0
      end.max

      pianos = _pull_qualified(piano_type, room.num_pianos, max_mus_score)

      potential_amps = room.num_amps
      potential_amps += pianos.length != room.num_pianos ? room.num_pianos - pianos.length : 0
      amps = _pull_qualified(ampy_type, potential_amps, max_mus_score)

      potential_other = room.capacity - pianos.length - amps.length
      others = _pull_qualified(other_type, potential_other, max_mus_score)

      class_label = "#{period}_musicianship_#{level + 1}".to_sym
      (pianos + amps + others).map { |student| student.musicianship_class = class_label }
    end
  end

  def theory_level(student)
    (THEORY_BUCKETS.select { |level| THEORY_BUCKETS[level].include?(student.theory_score) }).first[0]
  end

  def schedule_masterclass
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
    students = @students_by_instrument[instrument].dup
    students += @students_by_instrument[:vibes].dup if instrument == :piano
    students.sort_by!(&:combo_score)

    groups = _in_groups(students, num)
    groups.each do |level,students_in_level|
      class_name = (instrument.to_s + "_masterclass_#{level + 1}").to_sym
      students_in_level.map { |student| student.masterclass = class_name }
    end
  end

  def _sort_by_inrank_combo(students)
    # sort by the highness of their combo score and the lowness of their fractional in_rank ([0,1] rank / # in)
    students.sort_by do |student|
      num_instruments_in_family = total_instruments_in_family(student.instrument)
      relative_rank = student.in_rank.to_f / num_instruments_in_family.to_f
      [- relative_rank, student.combo_score]
    end.reverse
  end

  def _split_horns_evenly(all_horns)
    grouped_by_instrument = all_horns.group_by { |student| [student.instrument, student.variant] }
    early_students = []
    late_students = []

    equalizer = 0
    grouped_by_instrument.each_pair do |instrument_tuple,students|
      sorted_students = _sort_by_inrank_combo(students)
      if equalizer % 2 == 0
        early_section, late_section = _zipper_split(sorted_students)
      else
        late_section, early_section = _zipper_split(sorted_students)
      end
      early_students += early_section
      late_students += late_section
      equalizer += 1
    end
    [_sort_by_inrank_combo(early_students), _sort_by_inrank_combo(late_students)]
  end

  def schedule_combo_split_classes
    @students_by_instrument[:voice].each { |student| student.combo = "vocal_combo" }
    @students_by_instrument[:voice].each { |student| student.split = "vocal_split" }
    drums = @students_by_instrument[:drums].dup.sort_by(&:in_rank)
    bass = @students_by_instrument[:bass].dup.sort_by(&:in_rank) # this is short
    guitars = @students_by_instrument[:guitar].dup.sort_by(&:in_rank)
    pianos = @students_by_instrument[:piano].dup.sort_by(&:in_rank)

    horns = @students.dup - @students_by_instrument[:voice].dup - drums - bass - guitars - pianos

    combo_groups = _split_into_combos(drums, bass, guitars, pianos, horns)
    early_combo_student_groups, late_combo_student_groups = _zipper_split_combos(combo_groups)
    early_combo_student_groups.each_with_index do |students,level|
      label = "early_combo_#{level+1}".to_sym
      students.map { |student| student.combo = label }
    end
    late_combo_student_groups.each_with_index do |students,level|
      label = "late_combo_#{level+1}".to_sym
      students.map { |student| student.combo = label }
    end
    early_combo_students = early_combo_student_groups.flatten
    late_combo_students = late_combo_student_groups.flatten

    _schedule_split(:early, late_combo_students)
    _schedule_split(:late, early_combo_students)
  end

  def _split_into_combos(drums, bass, guitars, pianos, horns)
    horn_groups = _in_groups(horns, drums.length)
    piano_groups = _in_groups(pianos, drums.length)
    guitar_groups = _in_groups(guitars, drums.length)
    drums.reverse!
    bass.reverse!
    combos = []
    (CLASSROOMS + CLASSROOMS).take(drums.length).each_with_index do |room,level|
      curr_combo = []
      curr_combo << drums.pop if drums.length > 0
      if bass.length > 0 && curr_combo.map { |s| s.combo_score.floor}.include?(bass.last.combo_score.floor)
        curr_combo << bass.pop if bass.length > 0
      end
      curr_combo += piano_groups[level]
      curr_combo += guitar_groups[level]

      # max_horns = [horn_groups[level].length, room.capacity - curr_combo.length].min
      max_horns = horn_groups[level].length
      curr_horns = _uniquely_get_horns(horns, max_horns)
      curr_combo += curr_horns
      puts "expected #{max_horns} horns, but got #{curr_horns.length}: #{horns.length}"
      combos << [level, curr_combo]
    end
    combos
  end

  def _schedule_split(period, students)
    students.sort_by!(&:combo_score)

    _in_groups(students, 3).each do |level,students|
      class_name = "#{period}_split_#{level + 1}".to_sym
      students.map { |student| student.split = class_name }
    end
  end


  def _uniquely_get_horns(all_horns, max_number)
    uniqueness_hash = Hash[COMBO_UNIQUE_INSTRUMENTS.map { |instrument| [instrument, 0]}]
    selected = []
    num_brass = 0
    num_sax = 0

    all_horns.each do |student|
      return selected if selected.length >= max_number

      next if student.instrument == :saxophone && num_sax >= MAX_SAX_PER_COMBO
      next if BRASS.include?(student.instrument) && num_brass >= MAX_BRASS_PER_COMBO

      added_student = nil
      key_to_hash = [student.instrument, student.variant]
      if COMBO_UNIQUE_INSTRUMENTS.include?(key_to_hash)
        if uniqueness_hash[key_to_hash] == 0
          uniqueness_hash[key_to_hash] += 1
          added_student = student
        end
      else
        added_student = student
      end

      if !added_student.nil?
        if added_student.instrument == :saxophone
          num_sax += 1
        elsif BRASS.include?(added_student.instrument)
          num_brass += 1
        end
        selected << student
        all_horns.delete(student)
      end
    end
    selected
  end

  def _zipper_split_combos(combos)
    sorted_combos = combos.sort_by { |tup| tup[0] }
    grouped = sorted_combos.group_by { |tup| tup[0] % 2 }
    first_half = grouped[0].nil? ? [] : grouped[0].map(&:last)
    second_half = grouped[1].nil? ? [] : grouped[1].map(&:last)
    [first_half, second_half]
  end

  def _zipper_split(sorted_students)
    grouped = sorted_students.each_with_index.group_by { |student,rank| rank % 2 }
    first_half = grouped[0].nil? ? [] : grouped[0].map(&:first)
    second_half = grouped[1].nil? ? [] : grouped[1].map(&:first)
    [first_half, second_half]
  end

  def _in_groups(students, number)
    division = students.length / number
    modulo = students.length % number

    groups = {}
    start = 0

    number.times do |class_level|
      class_size = division + (modulo > 0 && modulo > class_level ? 1 : 0)
      groups[class_level] = students[start...(start + class_size)]
      start += class_size
    end
    groups
  end
end
