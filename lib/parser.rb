require "csv"
require_relative "camp"
require_relative "student_params"

class Parser
  def initialize(camp)
    @camp = camp
  end

  def populate_students(student_stats_filename)
    CSV.foreach(student_stats_filename) do |student|
      next unless _validate_csv_line(student)

      student_params = _format_line(student)

      next unless student_params.valid?

      new_student = Student.new(student_params)
      @camp.students_by_instrument[new_student.instrument] << new_student
      @camp.students << new_student
    end

    @camp.students_by_instrument.each do |instrument, students|
      puts "#{instrument}: #{students.length}"
    end
    puts "there are #{@camp.students.length} students"
  end

  def _format_line(line)
    line = line.map { |field| field.gsub(/\s+/,"") unless field.nil? }

    lname, fname, instrument, in_rank, theory_score, musicianship_score, combo_score = line

    instrument, variant = instrument.downcase.split(/-/).map(&:to_sym)

    StudentParams.new(
      lname,
      fname,
      in_rank.to_i,
      theory_score.to_i,
      musicianship_score.to_f,
      combo_score.to_f,
      instrument,
      variant
    )
  end

  def _validate_csv_line(line)
    return true if line.length == 7
    puts "The line #{line.join(" ")} is missing something."
    return false
  end
end
