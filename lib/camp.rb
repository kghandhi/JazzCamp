require_relative "student"
require_relative "classroom"
require_relative "instruments"
require_relative "camp_helpers"

APPLIED_THEORY = (43..49)

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
    early_theory, late_theory = zipper_split(rest.sort_by(&:theory_score))

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
      voice_kid.musicianship_class = @human_readable ? :late_vocal_musicianship : :LVM
    end


    _schedule_theory(:early, early_theory)
    _schedule_theory(:late, late_theory)

    late_musicianship = early_theory.select { |student| ![:voice, :drums].include?(student.instrument) }
    early_musicianship = late_theory.select { |student| ![:voice, :drums].include?(student.instrument) }

    # students with early theory have late musicianship and visa versa
    late_musicianship_schedule_musicianship(:late, late_musicianship)
    _schedule_musicianship(:early, early_musicianship)
  end

  def _schedule_theory(period, students)
    applied_theory = students.select { |student| APPLIED_THEORY.include?(student.theory_score) }

    # should be "#{period}_applied_theory"
    class_label = class_label(@human_readable, :theory, period, 5)
    applied_theory.map { |student| student.theory_class = class_label }

    rest = students - applied_theory
    rest_grouped = in_groups(rest.sort_by(&:theory_score), 4)
    rest_grouped.each do |level,students_at_level|
      class_label = class_label(@human_readable, :theory, period, level)
      students_at_level.map { |student| student.theory_class = class_label }
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

      read_level = level == 0 ? 98 : level - 1

      class_label = class_label(@human_readable, :musicianship, period, read_level)
      (pianos + guitars + bass + saxophones + others).map { |student| student.musicianship_class = class_label }
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

    groups = in_groups(students, num)
    groups.each do |level,students_in_level|
      class_label = class_label(@human_readable, :musicianship, nil, level, instrument=instrument)
      students_in_level.map { |student| student.masterclass = class_label }
    end
  end

  def schedule_combo_split_classes
    # do not handle vocalists
    drums = @students_by_instrument[:drums].dup.sort_by(&:in_rank)
    bass = @students_by_instrument[:bass].dup.sort_by(&:in_rank)
    pianos = @students_by_instrument[:piano].dup.sort_by(&:in_rank)

    # cello, clarinet, flute, saxophone, trombone, trumpet, vibes, viola, violin
    # STRINGS + vibes + WOODWINDS + BRASS + guitar
    horns = @students.dup - @students_by_instrument[:voice].dup - drums - bass - pianos

    early_combos, late_combos = _schedule_combo(drums, bass, pianos, horns)
    _schedule_split(:late, early_combos)
    _schedule_split(:early, late_combos)
  end

  def _schedule_combo(drummers, bassists, pianos, horns)
    num_combos = drummers.length
    piano_groups = in_groups(pianos, num_combos)
    drummers.reverse!
    bassists.reverse!

    early_combos = []
    late_combos = []
    double_classrooms = (CLASSROOMS + CLASSROOMS).sort_by { |room| - (room.num_pianos + room.num_amps) }
    double_classrooms.take(num_combos).each_with_index do |room,level|
      curr_combo = []
      curr_combo << drummers.pop if drummers.length > 0
      curr_combo += piano_groups[level]

      curr_horns = if level <= 4
                     _top_five_combo_horns(horns, curr_combo)
                   else
                     if level == 5
                       horns = _sort_by_inrank_combo(horns)
                     end
                     desired_horns = room.capacity - curr_combo.length
                     _uniquely_get_horns(horns, desired_horns)
                   end

      curr_combo += curr_horns
      curr_combo << bassists.pop if _bassist_acceptable(bassists, level, curr_combo)

      read_level, evenness = level.divmod(2)

      if evenness == 0
        period = "early"
        early_combos += curr_combo
      else
        period = "late"
        late_combos += curr_combo
      end

      class_label = class_label(@human_readable, :combo, period, read_level)
      curr_combo.map { |student| student.combo = class_label }
    end
    [early_combos, late_combos]
  end

  def _bassist_acceptable(bassists, level, curr_combo)
    return false if bassists.length == 0
    bassist = bassists.last
    avg_combo_score = (curr_combo.inject(0) { |sum,s| sum += s.combo_score }).to_f / curr_combo.length.to_f
    bassist.in_rank <= (level + 1) && (avg_combo_score - bassist.combo_score).abs <= 1
  end

  def _top_five_combo_horns(horns, curr_combo)
    # we dont need to do this every single time
    horns.sort_by! { |student| [ - student.in_rank, student.combo_score ] }
    horns.reverse!
    combo_contains = {}
    curr_horns = []

    horns.dup.each do |student|
      break if curr_horns.length >= 3
      next if !combo_contains[[student.instrument, student.variant]].nil?
      combo_contains[[student.instrument,student.variant]] = 1
      curr_horns << student
      horns.delete(student)
    end
    curr_combo += curr_horns
    curr_combo
  end

  def _sort_by_inrank_combo(students)
    # sort by the highness of their combo score and the lowness of their fractional in_rank ([0,1] rank / # in)
    students.sort_by do |student|
      num_instruments_in_family = total_instruments_in_family(student.instrument)
      relative_rank = student.in_rank.to_f / num_instruments_in_family.to_f
      [- relative_rank, student.combo_score]
    end.reverse
  end

  def _uniquely_get_horns(all_horns, max_number)
    uniqueness_hash = Hash[COMBO_UNIQUE_INSTRUMENTS.map { |instrument| [instrument, 0]}]
    selected = []
    num_brass = 0
    num_sax = 0
    num_guitar = 0

    all_horns.dup.each do |student|
      return selected if selected.length >= max_number

      next if student.instrument == :saxophone && num_sax >= MAX_SAX_PER_COMBO
      next if student.instrument == :guitar && num_guitar >= MAX_GUITAR_PER_COMBO
      next if BRASS.include?(student.instrument) && num_brass >= MAX_BRASS_PER_COMBO

      added_student = nil
      key_to_hash = [student.instrument, student.variant]

      if COMBO_UNIQUE_INSTRUMENTS.include?(key_to_hash)
        if uniqueness_hash[key_to_hash] == 0
          uniqueness_hash[key_to_hash] += 1
          added_student = student
        end
      else
        added_student = student
      end

      if !added_student.nil?
        if added_student.instrument == :saxophone
          num_sax += 1
        elsif added_student.instrument == :guitar
          num_guitar += 1
        elsif BRASS.include?(student.instrument)
          num_brass += 1
        end
        selected << student
        all_horns.delete(student)
      end
    end
    selected
  end

  def _schedule_split(period, students)
    students.sort_by!(&:combo_score)

    in_groups(students, 3).each do |level,students|
      class_label = class_label(@human_readable, :split, period, level)
      students.map { |student| student.split = class_label }
    end
  end
end
