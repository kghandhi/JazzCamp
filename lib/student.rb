class Student
  attr_reader :lname, :fname, :instrument, :in_rank, :theory_score, :musicianship_score, :combo_score, :variant
  attr_accessor :theory_class, :musicianship_class, :masterclass, :combo, :split

  def initialize(student_params)
    @instrument = student_params.instrument
    @instrument_variation = student_params.variant
    @variant = student_params.variant
    @fname = student_params.fname
    @lname = student_params.lname

    @in_rank = student_params.in_rank
    @theory_score = student_params.theory_score
    @musicianship_score = student_params.musicianship_score
    @combo_score = student_params.combo_score

    @theory_class = nil
    @musicianship_class = nil
    @masterclass = nil
    @combo = nil
    @split = nil
  end

  def early_theory?
    return @theory_class.to_s.split(/_/)[0] == "early"
  end

  def early_musicianship?
    return @musicianship_class.to_s.split(/_/)[0] == "early"
  end

  def early_combo?
    return @combo.to_s.split(/_/)[0] == "early"
  end

  def late_combo?
    return @combo.to_s.split(/_/)[0] == "late"
  end

  def early_split?
    return @split.to_s.split(/_/)[0] == "early"
  end

  def late_split?
    return @split.to_s.split(/_/)[0] == "late"
  end

  def event1
    puts "HELP theory/musicianship" if @theory_class.nil? || @musicianship_class.nil? #early_theory? && early_musicianship?
    if early_theory? && !early_musicianship?
      @theory_class.to_s
    else
      @musicianship_class.to_s
    end
  end

  def event2
    if !early_theory? && early_musicianship?
      @theory_class.to_s
    else
      @musicianship_class.to_s
    end
  end

  def event3
    return @masterclass.to_s
  end

  def event6
    puts "HELP combo/split" if @combo.nil? || @split.nil? #early_combo? && early_split?
    if early_combo? && !early_split?
      @combo.to_s
    elsif early_split?
      @split.to_s
    else
      ""
    end
  end

  def event7
    if late_combo?
      @combo.to_s
    elsif late_split?
      @split.to_s
    else
      ""
    end
  end

  def full_instrument
    @instrument_variation.nil? ? @instrument : "#{@instrument} - #{@instrument_variation}"
  end

  def show
    puts "#{@fname} #{@lname}"
    puts full_instrument
    puts "In:#{@in_rank}, Th:#{@theory_score}, MU:#{@musicianship_score}, CO:#{@combo_score}"
    puts "EV1:#{event1}"
    puts "EV2:#{event2}"
    puts "EV3:#{event3}"
    puts "EV6:#{event6}"
    puts "EV7:#{event7}"
  end

  def summary_csv
    [@lname, @fname, full_instrument].join(",")
  end

  def csv_row
    [
      @lname,
      @fname,
      full_instrument,
      @in_rank,
      @theory_score,
      @musicianship_score,
      @combo_score,
      event1,
      event2,
      event3,
      event6,
      event7
    ].map(&:to_s).join(',')
  end
end
