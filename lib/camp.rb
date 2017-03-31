require_relative "student"
require_relative "classes"
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


  def schedule_theory_class
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

    rest = @students.select { |student| student.theory_class.nil? }
    # TODO do something with the rest
  end

  def theory_level(student)
    THEORY_BUCKETS.first { |level,range| range.include?(student.theory_score) }[0]
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
    # Drum Rudiments is a early class
    # Vocal Musicianship is an late class
    @students_by_instrument[:drums].each { |drum_kid| drum_kid.musicianship_class = :drum_rudiments }
    @students_by_instrument[:voice].each { |voice_kid| voice_kid.musicianship_class = :vocal_musicianship }

    rest = @students.select { |student| student.musicianship_class.nil? }
    # TODO do something with the rest
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
      level = levels.first { |level| level.include?(student.combo_score) }[0]
      student.masterclass = (instrument.to_s + "_masterclass_#{level}").to_sym
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
