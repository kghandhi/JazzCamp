def zipper_split(sorted_students)
  grouped = sorted_students.each_with_index.group_by { |student,rank| rank % 2 }
  first_half = grouped[0].nil? ? [] : grouped[0].map(&:first)
  second_half = grouped[1].nil? ? [] : grouped[1].map(&:first)
  [first_half, second_half]
end

def in_groups(students, number)
  division = students.length / number
  modulo = students.length % number

  groups = {}
  start = 0

  number.times do |class_level|
    class_size = division + (modulo > 0 && modulo > class_level ? 1 : 0)
    groups[class_level] = students[start...(start + class_size)]
    start += class_size
  end
  groups
end

def class_label(human_readable, class_type, period, level, instrument=nil)
  readable_class_name, ugly_class_name = nil
  if class_type == :musicianship && !instrument.nil?
    abreviation = {
      :bass => "BS",
      :drums => "DRM",
      :guitar => "GUIT",
      :piano => "PNO",
      :saxophone => "SAX",
      :trombone => "TB",
      :trumpet => "TR",
    }[instrument]
    readable_class_name = (instrument.to_s + "_masterclass_#{level + 1}")
    ugly_class_name = if level == 0
                        "MC#{abreviation}"
                      else
                        "MC#{abreviation}#{level}"
                      end
  else
    class_descriptor = case class_type
                       when :theory
                         "T"
                       when :musicianship
                         "M"
                       when :combo
                         "C"
                       when :split
                         "JT"
                       end
    readable_class_name = "#{period}_#{class_type}_#{level + 1}"
    ugly_class_name = "#{period[0].upcase}#{class_descriptor}%02d" % [level + 1]
  end
  class_name = human_readable ? readable_class_name : ugly_class_name
  class_name.to_sym
end
