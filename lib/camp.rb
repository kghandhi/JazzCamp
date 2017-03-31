require_relative "student"
require_relative "classes"

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
:bass_electric
:bass_acoustic
:saxophone_alto
:saxophone_teno
:saxophone_baritone


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
    @students_by_instrument = Hash[POSSIBLE_INSTRUMENTS.map { |instrument| [instrument, []]}]
  end


  def schedule_theory_class
    @students_by_instrument[:drums].each { |drum_kid| drum_kid.theory_class = :drum_theory }
    non_drums = @students.select { |student| student.instrument != :drums }

    level_one_students = non_drums.select { |student| THEORY_BUCKETS[1].include?(student.theory_score) }
    level_two_students = non_drums.select { |student| THEORY_BUCKETS[2].include?(student.theory_score) }
    level_three_students = non_drums.select { |student| THEORY_BUCKETS[3].include?(student.theory_score) }
    level_four_students = non_drums.select { |student| THEORY_BUCKETS[4].include?(student.theory_score) }
    level_five_students = non_drums.select { |student| THEORY_BUCKETS[5].include?(student.theory_score) }
    POSSIBLE_INSTRUMENTS.each do |instrument|
      _divide_students_by_instrument(level_one_students, instrument, 1)
      _divide_students_by_instrument(level_two_students, instrument, 2)
      _divide_students_by_instrument(level_three_students, instrument, 3)
      _divide_students_by_instrument(level_four_students, instrument, 4)
      _divide_students_by_instrument(level_five_students, instrument, 5)
    end
      puts "level 1: #{level_one_students.length}"
      puts "level 2: #{level_two_students.length}"
      puts "level 3: #{level_three_students.length}"
      puts "level 4: #{level_four_students.length}"
      puts "level 5: #{level_five_students.length}"
  end

  def _divide_students_by_instrument(theory_bucket, instrument, level)
    students = theory_bucket.select { |student| instrument == student.instrument }
    students = students.sort_by { |student| student.in_rank }
    early_class = "early_theory_#{level}".to_sym
    late_class = "late_theory_#{level}".to_sym
    students.values_at(* students.each_index.select { |i| i.even? }).each { |student| student.theory_class = early_class }
    students.values_at(* students.each_index.select { |i| i.odd? }).each { |student| student.theory_class = late_class }

  end

  def schedule_musicianship_class
    # assumes students have been assigned theory classes already
    @students_by_instrument[:drums].each { |drum_kid| drum_kid.musicianship_class = :drum_rudiments }
    non_drums = @students.select { |student| student.instrument != :drums }
    early_theory = non_drums.select { |student| student.early_theory? }
    late_theory = non_drums.select { |student| !student.early_theory? }
    puts early_theory.length
    puts late_theory.length
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
    students_by_rank = students.sort_by { |student| student.in_rank }

    class_size = (students_by_rank.length / num.to_f).ceil
    num.times do |class_level|
      class_name = (instrument.to_s + "_masterclass_" + (class_level + 1).to_s).to_sym
      students_in_class = students_by_rank[(class_level * class_size)...(class_size * (class_level+1))]
      students_in_class.each { |student| student.masterclass = class_name }
    end
  end


  def schedule_combo
    # half students go to early combo half to late. Use instrument score to schedule these.
    # 30 combos each week. Each gets one of each of drummer, basssist, guitarist. 3-4 horn players per combo (1 trumpet, 1 trombone, 2 sax)
    # largest combo size is 5-6

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
