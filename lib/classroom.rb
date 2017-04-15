class Classroom
  attr_accessor :capacity, :num_pianos, :num_amps
  def initialize(name, capacity, num_pianos, num_amps)
    @name = name
    @capacity = capacity
    @num_pianos = num_pianos.nil? ? 1 : num_pianos
    @num_amps = num_amps.nil? ? 1 : num_amps
  end
end

CLASSROOMS = [
  Classroom.new("CTYD", 9, 3, 2),
  Classroom.new("DINK", 9, 5, nil),
  Classroom.new("SIGMA", 9, 2, nil),
  Classroom.new("XAN", 9, 1, 1),
  Classroom.new("103", 7, nil, nil),
  Classroom.new("105", 8, 2, 1),
  Classroom.new("106", 8, nil, nil),
  Classroom.new("151", 9, 3, 2),
  Classroom.new("204", 9, 2, 2),
  Classroom.new("211", 8, 2, 1),
  Classroom.new("221", 8, 1, 3),
  Classroom.new("222", 8, 1, 3),
  Classroom.new("223", 5, nil, nil),
  Classroom.new("224", 5, nil, nil),
  Classroom.new("225", 6, nil, nil),
  Classroom.new("226", 9, 3, 1),
]
