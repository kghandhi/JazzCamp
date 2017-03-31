require "csv"
require_relative "camp"

class Parser
  attr_accessor :camp
  def initialize(camp_name)
    @camp = Camp.new(camp_name)
  end

  def populate_students(student_stats_filename)
    CSV.foreach(student_stats_filename) do |student|
      next unless _validate_csv_line(student)
      student = student.map { |field| field.gsub(/\s+/,"") }

      lname, fname, instrument, in_rank, theory_score, musicianship_score, combo_score = student

      instrument = instrument.downcase
      variant = nil
      if instrument.include?("-")
        instrument, variant = instrument.split(/-/)
        instrument = instrument
        variant = variant.to_sym
      end
      instrument = instrument.to_sym
      in_rank = in_rank.to_i
      theory_score = theory_score.to_i
      musicianship_score = musicianship_score.to_f
      combo_score = combo_score.to_f

      next unless _validate_input(
        instrument,
        variant,
        theory_score,
        combo_score,
        musicianship_score
      )

      new_student = Student.new(
        fname,
        lname,
        instrument,
        variant,
        in_rank,
        theory_score,
        musicianship_score,
        combo_score
      )
      @camp.students_by_instrument[instrument] << new_student
      @camp.students << new_student
    end

    @camp.students_by_instrument.each do |instrument, students|
      puts "#{instrument}: #{students.length}"
    end
    puts "there are #{@camp.students.length} students"
  end

  def _validate_csv_line(line)
    return true if line.length == 7
    puts "The line #{line.join(" ")} is missing something."
    return false
  end

  def _validate_input(instrument, variant, theory_score, combo_score, musicianship_score)
    return _validate_instrument(instrument, variant) && _validate_theory(theory_score) && _validate_combo(combo_score) && _validate_musicianship(musicianship_score)
  end

  def _validate_instrument(instrument, variant)
    return true if POSSIBLE_INSTRUMENTS.include?(instrument) && _validate_variant(instrument, variant)

    type = variant.nil? ? instrument : "#{instrument} - #{variant}"
    puts "The #{type} is not a valid instrument"
    return false
  end

  def _validate_variant(instrument, variant)
    return true if variant.nil?
    if instrument == :saxophone
      [:alto, :baritone, :tenor].include?(variant)
    elsif instrument == :bass
      [:acoustic, :electric].include?(variant)
    else
      puts "#{variant} is not a type of #{instrument}"
      false
    end
  end

  def _validate_theory(score)
    return true if (0..62).include?(score)
    puts "The theory score: #{score} is not valid, it should be between 0 and 62"
    return false
  end

  def _validate_combo(score)
    return true if (0..6).include?(score)
    puts "The combo score: #{score} is not valid, it should be between 0 and 6"
    return false
  end

  def _validate_musicianship(score)
    return true if (0..6).include?(score)
    puts "The musicianship score: #{score} is not valid, it should be between 0 and 6"
    return false
  end
end
