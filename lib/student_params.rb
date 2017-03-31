require_relative "instruments"

class StudentParams
  attr_reader :lname, :fname, :in_rank, :theory_score, :musicianship_score, :combo_score, :instrument, :variant
  def initialize(lname, fname, in_rank, theory_score, musicianship_score, combo_score, instrument, variant)
    @lname = lname
    @fname = fname
    @instrument = instrument
    @variant = variant
    @in_rank = in_rank
    @theory_score = theory_score
    @musicianship_score = musicianship_score
    @combo_score = combo_score
  end

  def valid?
    return _valid_instrument? && _valid_theory? && _valid_combo? && _valid_musicianship?
  end

  def _valid_instrument?
    return true if POSSIBLE_INSTRUMENTS.include?(@instrument) && _valid_variant?

    type = @variant.nil? ? @instrument : "#{@instrument} - #{@variant}"
    puts "The #{type} is not a valid instrument"
    return false
  end

  def _valid_variant?
    return true if @variant.nil? || POSSIBLE_VARIANTS[@instrument].include?(@variant)
    puts "#{@variant} is not a type of #{@instrument}"
    false
  end

  def _valid_theory?
    return true if (0..62).include?(@theory_score) || @instrument == :drums
    puts "The theory score: #{@theory_score} is not valid, it should be between 0 and 62"
    return false
  end

  def _valid_combo?
    return true if (0..6).include?(@combo_score) || @instrument == :voice
    puts "The combo score: #{@combo_score} is not valid, it should be between 0 and 6"
    return false
  end

  def _valid_musicianship?
    return true if (0..6).include?(@musicianship_score) || @instrument == :voice
    puts "The musicianship score: #{@musicianship_score} is not valid, it should be between 0 and 6"
    return false
  end
end
