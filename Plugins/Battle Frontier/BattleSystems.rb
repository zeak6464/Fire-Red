#===============================================================================
# Battle Frontier Systems
#===============================================================================

#===============================================================================
# Battle Points System
#===============================================================================
class BattlePoints
  attr_reader :points

  def initialize
    @points = 0
  end

  def add_points(amount)
    @points += amount
    save_points
  end

  def spend_points(amount)
    return false if @points < amount
    @points -= amount
    save_points
    return true
  end

  def save_points
    $PokemonGlobal.battlePoints = @points
  end

  def self.load_points
    return $PokemonGlobal.battlePoints || 0
  end
end

#===============================================================================
# Symbol System
#===============================================================================
class FrontierSymbols
  SYMBOLS = {
    :TOWER   => 0,
    :PALACE  => 1,
    :ARENA   => 2,
    :FACTORY => 3,
    :DOME    => 4,
    :PIKE    => 5,
    :PYRAMID => 6,
    :CASTLE  => 7,
    :HALL    => 8,
    :ARCADE  => 9
  }

  def initialize
    @symbols = {}
    SYMBOLS.each do |facility, id|
      @symbols[facility] = {
        silver: false,
        gold: false
      }
    end
  end

  def award_symbol(facility, type)
    return if !SYMBOLS[facility]
    @symbols[facility][type] = true
    save_symbols
  end

  def has_symbol?(facility, type)
    return false if !SYMBOLS[facility]
    return @symbols[facility][type]
  end

  def save_symbols
    $PokemonGlobal.frontierSymbols = @symbols
  end

  def self.load_symbols
    return $PokemonGlobal.frontierSymbols || {}
  end
end

#===============================================================================
# Frontier Brain System
#===============================================================================
class FrontierBrain
  attr_reader :name, :facility, :battle_type, :team

  def initialize(name, facility, battle_type, team)
    @name = name
    @facility = facility
    @battle_type = battle_type
    @team = team
  end
end

class FrontierBrainSystem
  BRAINS = {
    :TOWER => [
      FrontierBrain.new("Palmer", :TOWER, :SINGLE, [:RHYPERIOR, :DRAGONITE, :MILOTIC]),
      FrontierBrain.new("Palmer", :TOWER, :DOUBLE, [:RHYPERIOR, :DRAGONITE, :MILOTIC, :REGIGIGAS])
    ],
    :FACTORY => [
      FrontierBrain.new("Thorton", :FACTORY, :SINGLE, [:SCIZOR, :PORYGONZ, :ELECTIVIRE])
    ],
    :DOME => [
      FrontierBrain.new("Tucker", :DOME, :SINGLE, [:SALAMENCE, :CHARIZARD, :SWAMPERT, :PINSIR])
    ],
    :PIKE => [
      FrontierBrain.new("Lucy", :PIKE, :SINGLE, [:SEVIPER, :MILOTIC, :SHUCKLE])
    ],
    :PYRAMID => [
      FrontierBrain.new("Brandon", :PYRAMID, :SINGLE, [:REGISTEEL, :REGICE, :REGIROCK])
    ],
    :CASTLE => [
      FrontierBrain.new("Dahlia", :CASTLE, :DOUBLE, [:LUDICOLO, :GARDEVOIR, :GALLADE, :ALTARIA])
    ],
    :HALL => [
      FrontierBrain.new("Argenta", :HALL, :SINGLE, [:MILOTIC, :GARDEVOIR, :SALAMENCE])
    ],
    :ARCADE => [
      FrontierBrain.new("Darach", :ARCADE, :SINGLE, [:GALLADE, :LUCARIO, :ESPEON, :UMBREON])
    ]
  }

  def self.get_brain(facility, battle_type)
    return nil if !BRAINS[facility]
    return BRAINS[facility].find { |brain| brain.battle_type == battle_type }
  end

  def self.is_brain_battle?(facility, battle_number)
    case facility
    when :TOWER
      return battle_number == 49 || battle_number == 99
    when :FACTORY
      return battle_number == 21 || battle_number == 42
    when :DOME
      return battle_number == 31 || battle_number == 63
    when :PIKE
      return battle_number == 28 || battle_number == 56
    when :PYRAMID
      return battle_number == 10 || battle_number == 20
    when :CASTLE
      return battle_number == 49 || battle_number == 99
    when :HALL
      return battle_number == 49 || battle_number == 99
    when :ARCADE
      return battle_number == 49 || battle_number == 99
    end
    return false
  end
end

#===============================================================================
# Battle Challenge Extension
#===============================================================================
class BattleChallenge
  def pbAwardPoints(amount)
    $PokemonGlobal.battlePoints = BattlePoints.load_points
    $PokemonGlobal.battlePoints.add_points(amount)
  end

  def pbAwardSymbol(facility, type)
    $PokemonGlobal.frontierSymbols = FrontierSymbols.load_symbols
    $PokemonGlobal.frontierSymbols.award_symbol(facility, type)
  end

  def pbIsBrainBattle?
    return FrontierBrainSystem.is_brain_battle?(@id, @currentChallenge)
  end

  def pbGetBrain
    return FrontierBrainSystem.get_brain(@id, @rules.doublebattle ? :DOUBLE : :SINGLE)
  end
end 