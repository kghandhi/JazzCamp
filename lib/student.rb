class Student
  attr_reader :lname, :fname, :instrument, :in_rank, :theory_score, :musicianship_score, :combo_score
  attr_accessor :theory_class, :musicianship_class, :masterclass, :combo, :split

  def initialize(fname, lname, instrument, instrument_variation=nil, in_rank, theory_score, musicianship_score, combo_score)
    @instrument = instrument
    @instrument_variation = instrument_variation
    @fname = fname
    @lname = lname

    @in_rank = in_rank
    @theory_score = theory_score
    @musicianship_score = musicianship_score
    @combo_score = combo_score

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

  def early_split?
    return @split.to_s.split(/_/)[0] == "early"
  end

  def event1
    return @musicianship_class if @instrument == :drums
    if early_theory?
      @theory_class
    elsif early_musicianship?
      @musicianship_class
    end
  end

  def event2
    return @theory_class if @instrument == :drums
    if !early_theory? #@theory_class.to_s.split(/_/)[0] == "late"
      @theory_class
    elsif !early_musicianship? #@musicianship_class.to_s.split(/_/)[0] == "late"
      @musicianship_class
    end
  end

  def event3
    return @masterclass
  end

  def event6
    if early_combo?
      @combo
    elsif early_split?
      @split
    end
  end

  def event7
    if @combo.to_s.split(/_/)[0] == "late"
      @combo
    elsif @split.to_s.split(/_/)[0] == "late"
      @split
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
    ].join(',')
  end
end
