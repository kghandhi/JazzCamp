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
    early_and_late = theory_score_ranked.each_with_index.group_by { |student,rank| rank % 2 }

    early = early_and_late[0].map!(&:first)
    early.map { |student| student.theory_class = "early_theory_#{theory_level(student)}".to_sym }

    late = early_and_late[1].map!(&:first)
    late.map { |student| student.theory_class = "late_theory_#{theory_level(student)}".to_sym }

    _schedule_musicianship(early, :early)
    _schedule_musicianship(late, :late)
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

  def schedule_combo
    # half students go to early combo half to late. Use instrument score to schedule these.
    # 30 combos each week. Each gets one of each of drummer, basssist, guitarist. 3-4 horn players per combo (1 trumpet, 1 trombone, 2 sax)
    # largest combo size is 5-6
    drums = @students_by_instrument[:drums].sort_by(&:in_rank)
    puts "Combo's cannot be scheduled if number of drums > number of combos" if drums.length > @number_of_combos

    pianos = @students_by_instrument[:piano].sort_by(&:in_rank)
    # if the number of pianos is differnt then number of drums what do we do

    # sorted highest ranked drummer to lowest
    drums.each_with_index do |level,instr|
      instr.combo = "combo_#{level}".to_sym
    end
  end

  def schedule_split
    # the students who are in early combo are in late split and vice versa
    # divide the students by low to high combo score into three groups and place them in a split class
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
