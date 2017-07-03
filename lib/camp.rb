require_relative "student"
require_relative "classroom"
require_relative "instruments"

APPLIED_THEORY = (43..47)

class Camp
  attr_accessor :students
  attr_accessor :students_by_instrument

  def initialize(name, human_readable)
    @name = name
    @human_readable = human_readable
    @students = []
    @students_by_instrument = _empty_students_by_instrument
  end

  def _empty_students_by_instrument
    Hash[POSSIBLE_INSTRUMENTS.map { |instrument| [instrument, []]}]
  end

  def counts_by_family
    {
      :strings => num_students_in_family(STRINGS),
      :brass => num_students_in_family(BRASS),
      :woodwinds => num_students_in_family(WOODWINDS),
      :vibes => num_students_in_family([:vibes]),
      :piano => num_students_in_family([:piano]),
      :guitar => num_students_in_family([:guitar]),
      :bass => num_students_in_family([:bass]),
      :drums => num_students_in_family([:drums]),
    }
  end

  def num_students_in_family(family)
    family.reduce(0) { |tot_in_family,instrument|
      tot_in_family += @students_by_instrument[instrument].length
    }
  end

  def total_instruments_in_family(instrument)
    family = ({
      :strings => STRINGS,
      :brass => BRASS,
      :woodwinds => WOODWINDS,
      :vibes => [:vibes],
      :piano => [:piano],
      :guitar => [:guitar],
      :bass => [:bass],
      :drums => [:drums]
    }.select { |family,components| components.include?(instrument) }).keys.first
    counts_by_family[family]
  end

  def schedule_theory_musicianship_classes
    # Theory Class for drummers and vocalists
    # Drummers go in Drum theory (late) if they do not have a theory score

    rest = @students.dup.select { |student| ![:voice,:drums].include?(student.instrument) }
    early_theory, late_theory = _zipper_split(rest.sort_by(&:theory_score))

    @students_by_instrument[:drums].each do |drummer|
      if drummer.theory_score == 0
        drummer.theory_class = @human_readable ? :late_drum_theory : :LDT
      else
        late_theory << drummer
      end
    end

    # vocalists must be in early theory
    @students_by_instrument[:voice].each do |vocalist|
      early_theory << vocalist
    end

    # Musicianship class for drummers and vocalists
    @students_by_instrument[:drums].each do |drum_kid|
      drum_kid.musicianship_class = @human_readable ? :early_drum_rudiments : :EDM
    end
    @students_by_instrument[:voice].each do |voice_kid|
      voice_kid.musicianship_class = @human_readable ? :late_vocal_musicianship : :VM
    end

    _schedule_theory(:early, early_theory)
    _schedule_theory(:late, late_theory)

    # students with early theory have late musicianship and visa versa
    _schedule_musicianship(:late, early_theory)
    _schedule_musicianship(:early, late_theory)
  end

  def _schedule_theory(period, students)
    applied_theory = students.select { |student| APPLIED_THEORY.include?(student.theory_score) }

    readable_class_name = "#{period}_applied_theory"
    ugly_class_name = "#{period[0].upcase}T05"
    class_name = @human_readable ? readable_class_name : ugly_class_name
    applied_theory.map { |student| student.theory_class = class_name.to_sym }

    rest = students - applied_theory
    rest_grouped = _in_groups(rest.sort_by(&:theory_score), 4)
    rest_grouped.each do |level,students_at_level|

      readable_class_name = "#{period}_theory_#{level + 1}"
      ugly_class_name = "#{period[0].upcase}T%02d" % [level + 1]
      class_name = @human_readable ? readable_class_name : ugly_class_name
      students_at_level.map { |student| student.theory_class = class_name.to_sym }
    end
  end

  def _in_range(max_score, potential)
    (max_score - potential.musicianship_score).abs <= 1
  end

  def _pull_qualified(full_set, positions_to_fill, max_mus_score)
    instruments = []

    while instruments.length < positions_to_fill && full_set.length > 0 && _in_range(max_mus_score, full_set.last)
      instruments << full_set.pop
    end
    instruments
  end

  def _schedule_musicianship(period, students)
    piano_type = students.select { |student| PIANO_TYPE.include?(student.instrument) }
    piano_type.sort_by!(&:musicianship_score)

    guitar_type = students.select { |student| student.instrument == :guitar }
    guitar_type.sort_by!(&:musicianship_score)

    bass_type = students.select { |student| student.instrument == :bass }
    bass_type.sort_by!(&:musicianship_score)

    saxophone_type = students.select { |student| student.instrument == :saxophone }
    saxophone_type.sort_by!(&:musicianship_score)

    other_type = students - piano_type - guitar_type - bass_type - saxophone_type
    other_type.sort_by!(&:musicianship_score)

    CLASSROOMS.sort_by! { |room| - (room.num_pianos + room.num_amps) }
    CLASSROOMS.each_with_index do |room,level|
      max_mus_score = [piano_type, other_type, saxophone_type, bass_type, guitar_type].map do |ss|
        ss.length > 0 ? ss.last.musicianship_score : 0
      end.max

      pianos = _pull_qualified(piano_type, MAX_PIANO_PER_MUSICIANSHIP, max_mus_score)

      guitars = _pull_qualified(guitar_type, MAX_GUITAR_PER_MUSICIANSHIP, max_mus_score)
      bass = _pull_qualified(bass_type, MAX_BASS_PER_MUSICIANSHIP, max_mus_score)
      saxophones = _pull_qualified(saxophone_type, MAX_SAX_PER_MUSICIANSHIP, max_mus_score)

      potential_other = room.capacity - pianos.length - guitars.length - bass.length - saxophones.length
      others = _pull_qualified(other_type, potential_other, max_mus_score)

      readable_class_name = "#{period}_musicianship_#{level + 1}"
      ugly_class_name = if level == 0
                          "#{period[0].upcase}M99"
                        else
                          "#{period[0].upcase}M%02d" % [level]
                        end

      class_name = @human_readable ? readable_class_name : ugly_class_name
      (pianos + guitars + bass + saxophones + others).map { |student| student.musicianship_class = class_name.to_sym }
    end
  end

  def theory_level(student)
    (THEORY_BUCKETS.select { |level| THEORY_BUCKETS[level].include?(student.theory_score) }).first[0]
  end

  def schedule_masterclass
    @students_by_instrument[:clarinet].each do |clarinet_kid|
      clarinet_kid.masterclass = @human_readable ? :clarinet_masterclass : :MCCLAR
  end
    @students_by_instrument[:flute].each do |flute_kid|
      flute_kid.masterclass = @human_readable ? :flute_masterclass : :MCFL
    end
    @students_by_instrument[:voice].each do |vocal_kid|
      vocal_kid.masterclass = @human_readable ? :voice_masterclass : :MCVOC
    end
    STRINGS.each do |string_instrument|
      @students_by_instrument[string_instrument].each do |string_kid|
        string_kid.masterclass = @human_readable ? :string_masterclass : :MCSTR
      end
    end

    [:bass, :drums, :guitar, :piano, :trombone, :trumpet,].each do |two_class_instrument|
      _split_into_masterclasses(two_class_instrument, 2)
    end
    _split_into_masterclasses(:saxophone, 4)
  end

  def _split_into_masterclasses(instrument, num)
    students = @students_by_instrument[instrument].dup
    students += @students_by_instrument[:vibes].dup if instrument == :piano
    students.sort_by!(&:combo_score)

    groups = _in_groups(students, num)
    groups.each do |level,students_in_level|
      readable_class_name = (instrument.to_s + "_masterclass_#{level + 1}")
      ugly_class_name = if level == 0
                          "MC#{_abreviation[instrument]}"
                        else
                          "MC#{_abreviation[instrument]}#{level}"
                        end
      class_name = @human_readable ? readable_class_name : ugly_class_name
      students_in_level.map { |student| student.masterclass = class_name.to_sym }
    end
  end

  def _abreviation
    {
      :bass => "BS",
      :drums => "DRM",
      :guitar => "GUIT",
      :piano => "PNO",
      :saxophone => "SAX",
      :trombone => "TB",
      :trumpet => "TR",
    }
  end

  def schedule_combo_split_classes
    # do not handle vocalists
    @students_by_instrument[:voice].each { |student| student.combo = "vocal_combo" }
    @students_by_instrument[:voice].each { |student| student.split = "vocal_split" }

    drums = @students_by_instrument[:drums].dup.sort_by(&:in_rank)
    bass = @students_by_instrument[:bass].dup.sort_by(&:in_rank) # this is short
    guitars = @students_by_instrument[:guitar].dup.sort_by(&:in_rank)
    pianos = @students_by_instrument[:piano].dup.sort_by(&:in_rank)

    # cello, clarinet, flute, saxophone, trombone, trumpet, vibes, viola, violin
    # STRINGS + vibes + WOODWINDS + BRASS
    horns = @students.dup - @students_by_instrument[:voice].dup - drums - bass - guitars - pianos

    early_combos, late_combos = _schedule_combo(drums, bass, guitars, pianos, horns)
    _schedule_split(:late, early_combos)
    _schedule_split(:early, late_combos)
  end

  def _schedule_combo(drummers, bassists, guitarists, pianos, horns)
    horn_groups = _in_horn_groups(horns, drummers.length)
    piano_groups = _in_groups(pianos, drummers.length)
    guitar_groups = _in_groups(guitarists, drummers.length)
    drummers.reverse!
    bassists.reverse!

    early_combos = []
    late_combos = []

    double_classrooms = (CLASSROOMS + CLASSROOMS).sort_by { |room| - (room.num_pianos + room.num_amps) }
    double_classrooms.take(drummers.length).each_with_index do |room,level|
      #TODO take into account room requirements?
      curr_combo = []
      curr_combo << drummers.pop if drummers.length > 0
      curr_combo += piano_groups[level]
      curr_combo += guitar_groups[level]

      if bassists.length > 0 && curr_combo.map(&:in_rank).include?(bassists.last.in_rank)
        curr_combo << bassists.pop if bassists.length > 0
      end

      curr_combo += horn_groups[level]

      if level % 2 == 0
        period = "early"
        early_combos += curr_combo
      else
        period = "late"
        late_combos += curr_combo
      end

      readable_class_name = "#{period}_combo_#{level + 1}"
      ugly_class_name = "#{period[0].upcase}C%02d" % [level + 1]
      class_name = @human_readable ? readable_class_name : ugly_class_name

      curr_combo.map { |student| student.combo = class_name.to_sym }
    end
    [early_combos, late_combos]
  end

  def _schedule_split(period, students)
    students.sort_by!(&:combo_score)

    _in_groups(students, 3).each do |level,students|
      readable_class_name = "#{period}_split_#{level + 1}"
      ugly_class_name = "#{period[0].upcase}JT%02d" % [level + 1]
      class_name = @human_readable ? readable_class_name : ugly_class_name
      students.map { |student| student.split = class_name.to_sym }
    end
  end

  def _zipper_split(sorted_students)
    grouped = sorted_students.each_with_index.group_by { |student,rank| rank % 2 }
    first_half = grouped[0].nil? ? [] : grouped[0].map(&:first)
    second_half = grouped[1].nil? ? [] : grouped[1].map(&:first)
    [first_half, second_half]
  end

  def _in_horn_groups(horns, number)
    horns_by_level = Hash.new([])

    grouped_by_instrument = horns.group_by { |student| [student.instrument, student.variant] }
    grouped_by_instrument.each do |instrument_pair,students|

      students.sort_by! { |s| [-s.in_rank, s.combo_score] }
      students.reverse!

      grouped = _in_groups(students, number)
      grouped.each do |level,students_at_level|
        if students.length < number
          # the length of students_at_level is 1 or 0
          next if students_at_level.length == 0
          student = students_at_level.first
          # definitely off by 1 here
          total = total_instruments_in_family(instrument_pair.first).to_f
          expected_level = if total != 1
                             ((student.in_rank / total.to_f) * number).ceil - 1
                           else
                             expected_level = ((student.combo_score / 6.0) * number).ceil - 1
                           end
          horns_by_level[expected_level] << student
        else
          horns_by_level[level] += students_at_level
        end
      end
    end
    horns_by_level
  end

  def _in_groups(students, number)
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
end
