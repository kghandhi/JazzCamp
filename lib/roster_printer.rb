require_relative "student"
class RosterPrinter
  def initialize(camp_name, students, write_rosters=false)
    @students = students
    @this_camp_directory = "#{Dir.pwd}/#{camp_name}"
    @write_rosters = write_rosters
  end

  def find_all_rosters
    theory_class_rosters
    musicianship_class_rosters
    masterclass_rosters
    combo_rosters
    split_rosters
  end

  def write_output
    Dir.mkdir(@this_camp_directory) unless Dir.exist?(@this_camp_directory)

    # the full view
    alphebetized_students = @students.sort_by { |student| student.lname }
    output_filename = "#{Time.now.to_i}_output.csv"
    output_file = File.open("#{@this_camp_directory}/#{output_filename}", "w")

    alphebetized_students.each { |student| output_file.puts(student.csv_row) }
    puts "Your output is done and located at #{@this_camp_directory}/#{output_filename}"

    # print rosters
    find_all_rosters
  end

  def theory_class_rosters
    theory_classes = @students.group_by { |student| student.theory_class }
    puts "----------------------------------------"
    puts "There are #{theory_classes.length} theory classes"
    puts "----------------------------------------"
    theory_classes.sort.each do |class_name, students|
      _print_roster(class_name, students)
      puts "#{class_name} has #{students.length} students"
    end
  end

  def musicianship_class_rosters
    musicianship_classes = @students.group_by { |student| student.musicianship_class.to_s }
    puts "----------------------------------------"
    puts "There are #{musicianship_classes.length} musicianship classes"
    puts "----------------------------------------"
    musicianship_classes.sort.each do |class_name, students|
      _print_roster(class_name, students)
      puts "#{class_name} has #{students.length} students"
    end
  end

  def masterclass_rosters
    masterclasses = @students.group_by { |student| student.masterclass.to_s }
    puts "----------------------------------------"
    puts "There are #{masterclasses.length} masterclasses"
    puts "----------------------------------------"
    masterclasses.sort.each do |class_name, students|
      _print_roster(class_name, students)
      puts "#{class_name} has #{students.length} students"
    end
  end

  def combo_rosters
    combos = @students.group_by { |student| student.combo.to_s }
    puts "----------------------------------------"
    puts "There are #{combos.length} combos"
    puts "----------------------------------------"
    combos.sort.each do |class_name, students|
      _print_roster(class_name, students)
      puts "#{class_name} has #{students.length} students:"
      # puts (students.map { |s| "#{s.full_instrument} (#{s.in_rank},#{s.combo_score})" } ).join(";")
    end
  end

  def split_rosters
    splits = @students.group_by { |student| student.split.to_s }
    puts "----------------------------------------"
    puts "There are #{splits.length} split classes"
    puts "----------------------------------------"
    splits.sort.each do |class_name, students|
      _print_roster(class_name, students)
      puts "#{class_name} has #{students.length} students"
    end
  end

  def _print_roster(class_name, students)
    if @write_rosters
      output_file = File.open("#{@this_camp_directory}/#{class_name}.csv", "w")
      students.sort_by(&:lname).each { |student| output_file.puts(student.summary_csv) }
    end
  end
end
