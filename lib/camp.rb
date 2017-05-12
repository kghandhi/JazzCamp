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

  def initialize(name, number_of_rooms)
    @name = name
    @students = []
    @students_by_instrument = Hash[POSSIBLE_INSTRUMENTS.map { |instrument| [instrument, []]}]
    @number_of_combos = number_of_rooms * 2
  end

  def schedule_theory_musicianship_classes
    # Theory Class for drummers and vocalists
    # Drummers go in Drum theory (late) if they do not have a theory score
    @students_by_instrument[:drums].each do |drummer|
      if drummer.theory_score.nil?
        drum_kid.theory_class = :drum_theory
      else
        drummer.theory_class = "late_theory_#{theory_level(drummer)}".to_sym
      end
    end

    # vocalists must be in early theory
    @students_by_instrument[:voice].each do |vocalist|
      vocalist.theory_class = "early_theory_#{theory_level(vocalist)}".to_sym
    end

    # Musicianship class for drummers and vocalists
    @students_by_instrument[:drums].each { |drum_kid| drum_kid.musicianship_class = :drum_rudiments }
    @students_by_instrument[:voice].each { |voice_kid| voice_kid.musicianship_class = :vocal_musicianship }

    rest = @students.select { |student| student.musicianship_class.nil? && student.theory_class.nil? }

    theory_score_ranked = rest.sort_by(&:theory_score)
    early, late = _zipper_split(theory_score_ranked)
   # early_and_late = theory_score_ranked.each_with_index.group_by { |student,rank| rank % 2 }

    #early = early_and_late[0].map!(&:first)
    early.map { |student| student.theory_class = "early_theory_#{theory_level(student)}".to_sym }

    #late = early_and_late[1].map!(&:first)
    late.map { |student| student.theory_class = "late_theory_#{theory_level(student)}".to_sym }

    _schedule_musicianship(early, :early)
    _schedule_musicianship(late, :late)
  end

  def _zipper_split(sorted_students)
    grouped = sorted_students.each_with_index.group_by { |student,rank| rank % 2 }
    first_set = grouped[0].map(&:first)
    second_set = grouped[1].map(&:first)

    [first_set, second_set]
  end

  def _schedule_musicianship(students, period)
    piano_type = students.select { |student| PIANO_TYPE.include?(student.instrument) }
    piano_type.sort_by!(&:musicianship_score)

    ampy_type = students.select { |student| AMPY_TYPE.include?(student.instrument) }
    ampy_type.sort_by!(&:musicianship_score)

    other_type = students - piano_type - ampy_type
    other_type.sort_by!(&:musicianship_score)

    CLASSROOMS.shuffle.each_with_index do |room,level|
      pianos = piano_type.pop(room.num_pianos)

      num_amps = room.num_amps
      num_amps += pianos.length != room.num_pianos ? room.num_pianos - pianos.length : 0
      amps = ampy_type.pop(num_amps)

      other = other_type.pop(room.capacity - amps.length - pianos.length)

      class_label = "#{period}_musicianship_#{level}".to_sym
      (pianos + amps + other).map { |student| student.musicianship_class = class_label }
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
    students = @students_by_instrument[instrument]
    students.concat(@students_by_instrument[:vibes]) if instrument == :piano
    if num == 2
      levels = {
        1 => (0...3),
        2 => (3..6),
      }
    elsif students.any? { |student| student.combo_score == 6 }
    # for sax consider just splitting evenly?
      levels = {
        1 => (0...2),
        2 => (2...4),
        3 => (4...6),
        4 => (6..6),
      }
    else
      levels = {
        1 => (0...2),
        2 => (2...4),
        3 => (4...5),
        4 => (5..6),
      }
    end

    students.each do |student|
      level = (levels.select { |level| levels[level].include?(student.combo_score) }).first[0]

      student.masterclass = (instrument.to_s + "_masterclass_#{level}").to_sym
    end
  end

  def _sort_by_two(students)
    # sort by the highness of their combo score and the lowness of their fractional in_rank ([0,1] rank / # in)
    students.sort_by do |student|
      num_instruments_in_family = total_instruments(student.instrument)
      relative_rank = student.in_rank.to_f / num_instruments_in_family.to_f
      [student.combo_score, - relative_rank]
    end
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
    drums = @students_by_instrument[:drums].sort_by(&:in_rank)
    bass = @students_by_instrument[:bass].sort_by(&:in_rank) # this is short
    guitars = @students_by_instrument[:guitar].sort_by(&:in_rank)
    # assert guitars.length == drums.length?
    horns = @students - @students_by_instrument[:voice] - drums - bass - guitars
    horns = _sort_by_two(horns)

    early_drums, late_drums = _zipper_split(drums)
    early_bass, late_bass = _zipper_split(bass)
    early_guitars, late_guitars = _zipper_split(guitars)
    early_horns, late_horns = _zipper_split(horns)

    _schedule_combo(:early, early_drums, early_bass, early_guitars, early_horns)
    _schedule_combo(:late, late_drums, late_bass, late_guitars, late_horns)

    early_students = early_drums + early_bass + early_guitars + early_horns
    late_students = late_drums + late_bass + late_guitars + late_horns
    _schedule_split(:early, early_students)
    _schedule_split(:late, late_students)

  end

  def _schedule_combo(period, drummers, bassists, guitarists, horns)
    CLASSROOMS.take(drummers.length).each_with_index do |room,level|
      curr_combo = []
      curr_combo << drummers.pop if drummers.length > 0
      curr_combo << guitarists.pop if guitarists.length > 0 # take two if the room is big enough and if they're same combo score
      if bassists.length > 0 && curr_combo.map { |s| s.combo_score.floor}.include?(bassists.last.combo_score.floor)
        curr_combo << bassists.pop if bassists.length > 0
      end

      curr_combo += horns.pop(room.capacity - curr_combo.length) if horns.length > 0

      class_label = "#{period}_combo_#{level}".to_sym
      curr_combo.map { |student| student.combo = class_label }
    end
  end

  def _schedule_split(period, students)
    students.sort_by!(&:combo_score)

    in_groups(students, 3).each do |level,students|
      class_name = "#{period}_split_#{level}".to_sym
      students.map { |student| student.split = class_name }
    end
  end

  def in_groups(students, number)
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

  def write_output
    alphebetized_students = @students.sort_by { |student| student.lname }

    this_camp_directory = "#{Dir.pwd}/#{@name}"
    output_filename = "#{Time.now.to_i}_output.csv"
    Dir.mkdir(this_camp_directory)
    output_file = File.open("#{this_camp_directory}/#{output_filename}", "w")

    alphebetized_students.each { |student| output_file.puts(student.csv_row) }
    puts "Your output is done and located at #{this_camp_directory}/#{output_filename}"
  end
end
