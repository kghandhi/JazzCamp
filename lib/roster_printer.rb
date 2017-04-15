require_relative "student"
class RosterPrinter
  def initialize(students)
    @students = students
  end

  def find_all_rosters
    theory_class_rosters
    musicianship_class_rosters
    masterclass_rosters
    combo_rosters
    split_rosters
  end

  def theory_class_rosters
    theory_classes = @students.group_by { |student| student.theory_class }
    puts "----------------------------------------"
    puts "There are #{theory_classes.length} theory classes"
    puts "----------------------------------------"
    theory_classes.sort.each do |class_name, students|
      puts "#{class_name} has #{students.length} students"
    end
  end

  def musicianship_class_rosters
    musicianship_classes = @students.group_by { |student| student.musicianship_class }
    puts "----------------------------------------"
    puts "There are #{musicianship_classes.length} musicianship classes"
    puts "----------------------------------------"
    musicianship_classes.sort.each do |class_name, students|
      puts "#{class_name} has #{students.length} students"
    end
  end

  def masterclass_rosters
    masterclasses = @students.group_by { |student| student.masterclass }
    puts "----------------------------------------"
    puts "There are #{masterclasses.length} masterclasses"
    puts "----------------------------------------"
    masterclasses.sort.each do |class_name, students|
      puts "#{class_name} has #{students.length} students"
    end
  end

  def combo_rosters
    combos = @students.group_by { |student| student.combo }
    puts "----------------------------------------"
    puts "There are #{combos.length} combos"
    puts "----------------------------------------"
    combos.each do |class_name, students|
      puts "#{class_name} has #{students.length} students"
    end
  end

  def split_rosters
    splits = @students.group_by { |student| student.split }
    puts "----------------------------------------"
    puts "There are #{splits.length} split classes"
    puts "----------------------------------------"
    splits.each do |class_name, students|
      puts "#{class_name} has #{students.length} students"
    end
  end
end
