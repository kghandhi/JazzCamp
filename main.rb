# Read input (students + scores) from a csv
require "csv"
POSSIBLE_INSTRUMENTS = [
  :bass,
  :clarinet,
  :drum,
  :flute,
  :guitar,
  :piano,
  :sax,
  :trombone,
  :trumpet,
  :vocal,
  :cello,
  :violin,
  :viola,
  :vocals,
]

string_instruments = [
  :violin,
  :viola,
  :cello,

]

THEORY_BUCKETS = {
  1 => [0,14],
  2 => [15,29],
  3 => [30,44],
  4 => [45,59],
  5 => [60,62]
}

class Student
  attr_reader :combo_score
  attr_accessor :in_rank

  def initialize(fname, lname, instrument, theory_score, musicianship_score, combo_score)
    # theory_score (integer): [0,62]
    # musicianship_score (float): [0,6]
    # combo_score (float): [0,6]
    @instrument = instrument
    @in_rank = nil
    @fname = fname
    @lname = lname
    @theory_score = theory_score
    @musicianship_score = musicianship_score
    @combo_score = combo_score
  end

  def show
    puts "#{@fname} #{@lname}: #{@instrument}"
    puts "In:#{@in_rank}"
    puts "Th:#{@theory_score}"
    puts "MU:#{@musicianship_score}"
    puts "CO:#{@combo_score}"
  end
end

class Camp
  def initialize(name)
    @name = name
    @students = []
    @students_by_instrument = Hash[POSSIBLE_INSTRUMENTS.map { |instrument| [instrument, []]}]
  end

  def populate_students(student_stats_filename)
    CSV.foreach(student_stats_filename) do |student|
      next unless _validate_csv_line(student)

      lname, fname, instrument, theory_score, musicianship_score, combo_score = student.map { |field| field.gsub(/\s+/,"")}

      instrument = instrument.downcase.to_sym
      theory_score = theory_score.to_i
      musicianship_score = musicianship_score.to_f
      combo_score = combo_score.to_f

      next unless _validate_input(instrument, theory_score, combo_score, musicianship_score)

      new_student = Student.new(fname, lname, instrument, theory_score, musicianship_score, combo_score)
      @students_by_instrument[instrument] << new_student
      @students << new_student
    end
  end

  def calculate_instrument_score
    @students_by_instrument.each do |instrument, students|
      sorted_by_combo_score = students.sort_by { |student| student.combo_score }
      sorted_by_combo_score.each_with_index do |student, i|
        student.in_rank = i
      end
    end
    @students.map { |student| student.show }
  end

  def _validate_csv_line(line)
    return true if line.length == 6
    puts "The line #{line.join(" ")} is missing something."
    return false
  end

  def _validate_input(instrument, theory_score, combo_score, musicianship_score)
    return _validate_instrument(instrument) && _validate_theory(theory_score) && _validate_combo(combo_score) && _validate_musicianship(musicianship_score)
  end

  def _validate_instrument(instrument)
    return true if POSSIBLE_INSTRUMENTS.include?(instrument)
    puts "The #{instrument} is not a valid instrument"
    return false
  end

  def _validate_theory(score)
    return true if score >= 0 && score <= 62
    puts "The theory score: #{score} is not valid, it should be between 0 and 62"
    return false
  end

  def _validate_combo(score)
    return true if (score >= 0 && score <= 6)
    puts "The combo score: #{score} is not valid, it should be between 0 and 6"
    return false
  end

  def _validate_musicianship(score)
    return true if score >= 0 && score <= 6
    puts "The musicianship score: #{score} is not valid, it should be between 0 and 6"
    return false
  end

  def schedule_theory
    # half students go to early theory half to late. There is one theory class per level at each time
    # All drums are in the drum theory class (capacity 25)
    level_one_students = @students.select { |student| student.theory_score <= THEORY_BUCKETS[1][0] && student.theory_score <= THEORY_BICKETS[1][1] }
    level_two_students = @students.select { |student| student.theory_score <= THEORY_BUCKETS[2][0] && student.theory_score <= THEORY_BICKETS[2][1] }
    level_three_students = @students.select { |student| student.theory_score <= THEORY_BUCKETS[3][0] && student.theory_score <= THEORY_BICKETS[3][1] }
    level_four_students = @students.select { |student| student.theory_score <= THEORY_BUCKETS[2][0] && student.theory_score <= THEORY_BICKETS[4][1] }
    level_five_students = @students.select { |student| student.theory_score <= THEORY_BUCKETS[5][0] && student.theory_score <= THEORY_BICKETS[5][1] }
  end

  def schedule_musicianship_class
    # the same half that has early theory has late musicianship and vice versa.
    # There are 10 classes per period and each should have equal number students
    # Do not schedule more than 2 Piano, Guitar, Vibes, Bass in a class
    # All drummers are in drum rudiments class
    # What is late advanced ear studies? And where do vocalists go??
  end

  def schedule_combo
    # half students go to early combo half to late
    # 30 combos each week. Each gets one of each of drummer, basssist, guitarist. 3-4 horn players per combo (1 trumpet, 1 trombone, 2 sax)
    # largest combo size is 5-6

  end

  def schedule_split
    # the students who are in early combo are in late split and vice versa
    # divide the students by low to high combo score into three groups and place them in a split class
  end

end

if __FILE__ == $0
  fname = "ex.csv"
  camp = Camp.new("week 1")
  camp.populate_students(fname)
  camp.calculate_instrument_score
end

