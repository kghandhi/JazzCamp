# Read input (students + scores) from a csv
require "csv"
:bass
:clarinet
:drum
:flute
:guitar
:piano
:sax
:trombone
:trumpet
:vocal

class Student
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

  def repr
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
  end

  def populate_students(student_stats_filename)
    CSV.foreach(student_stats_filename) do |student|
      lname, fname, instrument, theory_score, musicianship_score, combo_score = student
      # make sure the instrument is in the list
      # make sure the scores are right
      # make sure the scores are all provided
      new_student = Student.new(fname, lname, instrument, theory_score.to_i, musicianship_score.to_f, combo_score.to_f)

      new_student.repr
    end
  end
end

if __FILE__ == $0
  fname = "ex.csv"
  camp = Camp.new("week 1")
  camp.populate_students(fname)
end

