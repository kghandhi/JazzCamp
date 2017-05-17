require_relative "parser"
require_relative "roster_printer"

class ClassScheduler
  def initialize
    @input  = $stdin
    @output = $stdout
  end

  def run(args)
    _usage if args.size != 2

    student_stats_filename = args[0]
    camp_name = args[1]
    _abort("invalid file path.") unless File.file?(student_stats_filename)

    camp = Camp.new(camp_name)
    Parser.new(camp).populate_students(student_stats_filename)
    camp.schedule_masterclass
    camp.schedule_theory_musicianship_classes
    camp.schedule_combo_split_classes
    RosterPrinter.new(camp_name, camp.students).write_output
    # RosterPrinter.new(camp_name, camp.students).find_all_rosters
  end

  def _usage
    expected_arguments = "<INPUT_FILE_PATH> <CAMP_NAME>"
    @output.puts "ruby lib/class_scheduler.rb #{expected_arguments}"
    @output.puts
    @output.puts "The input file should be a .csv formatted like:"
    @output.puts "\tLNAME, FNAME, INSTUMENT, INSTRUMENT_RANK, THEORY_SCORE, MUSICIANSHIP_SCORE, COMBO_SCORE"
    @output.puts
    @output.puts "The camp name should be a unique name for the week of the camp being scheduled"
    exit 1
  end

  def _abort(reason)
    @output.puts "Aborting, #{reason}"
  end
end

if $PROGRAM_NAME == __FILE__
  ClassScheduler.new.run(ARGV)
end
