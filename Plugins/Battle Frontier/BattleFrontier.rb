#===============================================================================
# Battle Frontier Plugin
#===============================================================================
# Author: Zeak6464
# Version: 1.0
#===============================================================================


#===============================================================================
# * Battle Frontier Scene
#===============================================================================
class BattleFrontierScene
  def initialize
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @sprites["background"] = Sprite.new(@viewport)
    @sprites["background"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @sprites["background"].bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0))
    @sprites["background"].opacity = 0
  end

  def pbStartScene
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    @viewport.dispose
  end

  def pbUpdate
    Graphics.update
    Input.update
  end

  def pbShowCommands(commands)
    ret = -1
    @sprites["commandwindow"] = Window_CommandPokemon.new(commands)
    @sprites["commandwindow"].viewport = @viewport
    @sprites["commandwindow"].index = 0
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::USE)
        ret = @sprites["commandwindow"].index
        break
      end
      if Input.trigger?(Input::BACK)
        ret = -1
        break
      end
      @sprites["commandwindow"].update
    end
    @sprites["commandwindow"].dispose
    return ret
  end
end

#===============================================================================
# Battle Frontier Screen
#===============================================================================
class BattleFrontierScreen
  def initialize(scene)
    @scene = scene
    @frontier = BattleFrontierPlugin::BattleFrontier.new
  end

  def pbStartScreen
    @scene.pbStartScene
    pbMainMenu
    @scene.pbEndScene
  end

  def pbMainMenu
    loop do
      command = @scene.pbShowCommands([
        _INTL("Battle Tower"),
        _INTL("Battle Palace"),
        _INTL("Battle Factory"),
        _INTL("Battle Arena"),
        _INTL("Battle Dome"),
        _INTL("Battle Pike"),
        _INTL("Battle Pyramid"),
        _INTL("Battle Hall"),
        _INTL("Battle Castle"),
        _INTL("Battle Arcade"),
        _INTL("Exit")
      ])
      
      case command
      when 0 then pbStartFacility(:TOWER)
      when 1 then pbStartFacility(:PALACE)
      when 2 then pbStartFacility(:FACTORY)
      when 3 then pbStartFacility(:ARENA)
      when 4 then pbStartFacility(:DOME)
      when 5 then pbStartFacility(:PIKE)
      when 6 then pbStartFacility(:PYRAMID)
      when 7 then pbStartFacility(:HALL)
      when 8 then pbStartFacility(:CASTLE)
      when 9 then pbStartFacility(:ARCADE)
      when 10, -1 then break
      end
    end
  end

  def pbStartFacility(facility)
    case facility
    when :TOWER
      scene = BattleTowerScene.new
      screen = BattleTowerScreen.new(scene)
    when :PALACE
      scene = BattlePalaceScene.new
      screen = BattlePalaceScreen.new(scene)
    when :FACTORY
      scene = BattleFactoryScene.new
      screen = BattleFactoryScreen.new(scene)
    when :ARENA
      scene = BattleArenaScene.new
      screen = BattleArenaScreen.new(scene)
    when :DOME
      scene = BattleDomeScene.new
      screen = BattleDomeScreen.new(scene)
    when :PIKE
      scene = BattlePikeScene.new
      screen = BattlePikeScreen.new(scene)
    when :PYRAMID
      scene = BattlePyramidScene.new
      screen = BattlePyramidScreen.new(scene)
    when :HALL
      scene = BattleFrontierPlugin::HallScene.new
      screen = BattleFrontierPlugin::HallScreen.new(scene)
    when :CASTLE
      scene = BattleFrontierPlugin::CastleScene.new
      screen = BattleFrontierPlugin::CastleScreen.new(scene)
    when :ARCADE
      scene = BattleArcadeScene.new
      screen = BattleArcadeScreen.new(scene)
    end
    
    screen.pbStart if screen
  end
end

#==============================================================================
# * Plugin Command
#==============================================================================
def pbBattleFrontier
  pbFadeOutIn {
    scene = BattleFrontierScene.new
    screen = BattleFrontierScreen.new(scene)
    screen.pbStartScreen
  }
end

#===============================================================================
# * Battle Frontier Plugin
#===============================================================================
module BattleFrontierPlugin
  #--------------------------------------------------------------------------
  # * Plugin Settings
  #--------------------------------------------------------------------------
  module Settings
    # Battle Points earned per win
    POINTS_PER_WIN = 3
    
    # Battle Type Settings
    ALLOW_DOUBLE_BATTLES = true
    ALLOW_MULTI_BATTLES = true
    
    # Facility Streak Requirements
    TOWER_STREAKS = [21, 49]      # Streaks needed to face Anabel
    PIKE_STREAKS = [28, 140]      # Streaks needed to face Lucy
    DOME_STREAKS = [5, 10]        # Streaks needed to face Tucker
    FACTORY_STREAKS = [21, 49]    # Streaks needed to face Noland
    ARENA_STREAKS = [27, 56]      # Streaks needed to face Greta
    PALACE_STREAKS = [21, 42]     # Streaks needed to face Spenser
    PYRAMID_STREAKS = [21, 70]    # Streaks needed to face Brandon
    HALL_STREAKS = [7, 21]        # Streaks needed to face Argenta
    CASTLE_STREAKS = [10, 30]     # Streaks needed to face Darach
    ARCADE_STREAKS = [7, 21]      # Streaks needed to face Dahlia
    
    # Battle Types
    BATTLE_TYPES = {
      :TOWER => [:SINGLE, :DOUBLE, :MULTI],
      :PIKE => [:SINGLE],
      :DOME => [:DOUBLE],
      :FACTORY => [:SINGLE, :DOUBLE],
      :ARENA => [:SINGLE],
      :PALACE => [:SINGLE],
      :PYRAMID => [:SINGLE],
      :HALL => [:SINGLE],
      :CASTLE => [:SINGLE],
      :ARCADE => [:SINGLE]
    }
    
    # Whether to use open level (true) or level 50 (false)
    OPEN_LEVEL = true
  end

  def self.createBrainTeam(facility, streak)
    trainer = nil
    case facility
    when :TOWER
      trainer = NPCTrainer.new("ANABEL", :FRONTIER_BRAIN)
      team = [
        [:ALAKAZAM, 50],
        [:SNORLAX, 50],
        [:ENTEI, 50]
      ]
    when :PIKE
      trainer = NPCTrainer.new("LUCY", :FRONTIER_BRAIN)
      team = [
        [:SEVIPER, 50],
        [:MILOTIC, 50],
        [:SHUCKLE, 50]
      ]
    when :DOME
      trainer = NPCTrainer.new("TUCKER", :FRONTIER_BRAIN)
      team = [
        [:SWAMPERT, 50],
        [:METAGROSS, 50],
        [:CHARIZARD, 50]
      ]
    when :FACTORY
      trainer = NPCTrainer.new("NOLAND", :FRONTIER_BRAIN)
      team = [
        [:ARTICUNO, 50],
        [:AGGRON, 50],
        [:WALREIN, 50]
      ]
    when :ARENA
      trainer = NPCTrainer.new("GRETA", :FRONTIER_BRAIN)
      team = [
        [:HERACROSS, 50],
        [:UMBREON, 50],
        [:SHEDINJA, 50]
      ]
    when :PALACE
      trainer = NPCTrainer.new("SPENSER", :FRONTIER_BRAIN)
      team = [
        [:ARCANINE, 50],
        [:SLAKING, 50],
        [:LAPRAS, 50]
      ]
    when :PYRAMID
      trainer = NPCTrainer.new("BRANDON", :FRONTIER_BRAIN)
      team = [
        [:REGIROCK, 50],
        [:REGICE, 50],
        [:REGISTEEL, 50]
      ]
    when :HALL
      trainer = NPCTrainer.new("ARGENTA", :FRONTIER_BRAIN)
      team = [
        [:GARDEVOIR, 50],
        [:MILOTIC, 50],
        [:SALAMENCE, 50]
      ]
    when :CASTLE
      trainer = NPCTrainer.new("DARACH", :FRONTIER_BRAIN)
      team = [
        [:GALLADE, 50],
        [:STARAPTOR, 50],
        [:LUCARIO, 50]
      ]
    when :ARCADE
      trainer = NPCTrainer.new("DAHLIA", :FRONTIER_BRAIN)
      team = [
        [:LUDICOLO, 50],
        [:GARCHOMP, 50],
        [:DRAGONITE, 50]
      ]
    end
    
    return nil if !trainer
    team.each do |pkmn|
      species = pkmn[0]
      level = pkmn[1]
      trainer.party.push(Pokemon.new(species, level))
    end
    return trainer
  end

  #--------------------------------------------------------------------------
  # * Battle Frontier Class
  #--------------------------------------------------------------------------
  class BattleFrontier
    attr_reader :currentFacility
    attr_reader :battlePoints
    attr_reader :symbols
    attr_reader :streaks
    attr_reader :openLevel
    attr_accessor :last_hall_pokemon
    attr_reader :fan_milestones
    attr_reader :record_milestones

    def initialize
      @battlePoints = 0
      @symbols = {
        :TOWER => false,
        :PALACE => false,
        :FACTORY => false,
        :ARENA => false,
        :DOME => false,
        :PIKE => false,
        :PYRAMID => false,
        :HALL => false,
        :CASTLE => false,
        :ARCADE => false
      }
      @streaks = {
        :TOWER => 0,
        :PALACE => 0,
        :FACTORY => 0,
        :ARENA => 0,
        :DOME => 0,
        :PIKE => 0,
        :PYRAMID => 0,
        :HALL => 0,
        :CASTLE => 0,
        :ARCADE => 0
      }
      @currentFacility = nil
      @openLevel = false  # Default to Level 50
      @fan_milestones = {}
      @record_milestones = {}
    end

    def addBattlePoints(amount)
      @battlePoints += amount
    end

    def canAfford?(cost)
      return @battlePoints >= cost
    end

    def spendBattlePoints(amount)
      return false if !canAfford?(amount)
      @battlePoints -= amount
      return true
    end

    def setSymbol(facility)
      @symbols[facility] = true
    end

    def hasSymbol?(facility)
      return @symbols[facility]
    end

    def incrementStreak(facility)
      @streaks[facility] += 1
    end

    def resetStreak(facility)
      @streaks[facility] = 0
    end

    def getStreak(facility)
      return @streaks[facility]
    end

    def canFaceLeader?(facility)
      streak = @streaks[facility]
      case facility
      when :TOWER
        return Settings::TOWER_STREAKS.include?(streak)
      when :PIKE
        return Settings::PIKE_STREAKS.include?(streak)
      when :DOME
        return Settings::DOME_STREAKS.include?(streak)
      when :FACTORY
        return Settings::FACTORY_STREAKS.include?(streak)
      when :ARENA
        return Settings::ARENA_STREAKS.include?(streak)
      when :PALACE
        return Settings::PALACE_STREAKS.include?(streak)
      when :PYRAMID
        return Settings::PYRAMID_STREAKS.include?(streak)
      when :HALL
        return Settings::HALL_STREAKS.include?(streak)
      when :CASTLE
        return Settings::CASTLE_STREAKS.include?(streak)
      when :ARCADE
        return Settings::ARCADE_STREAKS.include?(streak)
      end
      return false
    end

    def startFacility(facility)
      @currentFacility = facility
      case facility
      when :TOWER
        return startBattleTower
      when :PALACE
        return startBattlePalace
      when :FACTORY
        return startBattleFactory
      when :ARENA
        return startBattleArena
      when :DOME
        return startBattleDome
      when :PIKE
        return startBattlePike
      when :PYRAMID
        return startBattlePyramid
      when :HALL
        return startBattleHall
      when :CASTLE
        return startBattleCastle
      when :ARCADE
        return startBattleArcade
      end
    end

    def startBattleTower
      challenge = BattleChallenge.new
      challenge.set("tower", Settings::TOWER_STREAKS[0], 
                   pbBattleTowerRules(Settings::ALLOW_DOUBLE_BATTLES, Settings::OPEN_LEVEL))
      challenge.start
      return challenge
    end

    def startBattlePalace
      challenge = BattleChallenge.new
      challenge.set("palace", Settings::PALACE_STREAKS[0],
                   pbBattlePalaceRules(Settings::ALLOW_DOUBLE_BATTLES, Settings::OPEN_LEVEL))
      challenge.start
      return challenge
    end

    def startBattleFactory
      challenge = BattleChallenge.new
      challenge.set("factory", Settings::FACTORY_STREAKS[0],
                   pbBattleFactoryRules(Settings::ALLOW_DOUBLE_BATTLES, Settings::OPEN_LEVEL))
      challenge.start
      return challenge
    end

    def startBattleArena
      challenge = BattleChallenge.new
      challenge.set("arena", Settings::ARENA_STREAKS[0],
                   pbBattleArenaRules(Settings::OPEN_LEVEL))
      challenge.start
      return challenge
    end

    def startBattleDome
      challenge = BattleChallenge.new
      challenge.set("dome", Settings::DOME_STREAKS[0],
                   pbBattleDomeRules(Settings::ALLOW_DOUBLE_BATTLES, Settings::OPEN_LEVEL))
      challenge.start
      return challenge
    end

    def startBattlePike
      challenge = BattleChallenge.new
      challenge.set("pike", Settings::PIKE_STREAKS[0],
                   pbBattlePikeRules(Settings::ALLOW_DOUBLE_BATTLES, Settings::OPEN_LEVEL))
      challenge.start
      return challenge
    end

    def startBattlePyramid
      # Create and start the Battle Pyramid
      scene = BattlePyramidScene.new
      screen = BattlePyramidScreen.new(scene)
      pbFadeOutIn {
        screen.pbStart
      }
      # End the facility after challenge is complete
      endFacility
      return false
    end

    def startBattleHall
      # Create and start the Battle Hall
      scene = BattleFrontierPlugin::HallScene.new
      screen = BattleFrontierPlugin::HallScreen.new(scene)
      pbFadeOutIn {
        screen.pbStart
      }
      # End the facility after challenge is complete
      endFacility
      return false
    end

    def startBattleCastle
      # Create and start the Battle Castle
      scene = BattleFrontierPlugin::CastleScene.new
      screen = BattleFrontierPlugin::CastleScreen.new(scene)
      pbFadeOutIn {
        screen.pbStart
      }
      # End the facility after challenge is complete
      endFacility
      return false
    end

    def startBattleArcade
      # Create and start the Battle Arcade
      scene = BattleArcadeScene.new
      screen = BattleArcadeScreen.new(scene)
      pbFadeOutIn {
        screen.pbStart
      }
      # End the facility after challenge is complete
      endFacility
      return false
    end

    def endFacility
      return if !@currentFacility
      challenge = BattleChallenge.new
      challenge.pbEnd
      @currentFacility = nil
    end

    def pbStartScreen
      # First, choose battle level
      pbChooseBattleLevel
      
      # Then show facility selection
      pbShowFacilitySelection
    end

    def pbChooseBattleLevel
      command = pbShowCommands([
        _INTL("Level 50"),
        _INTL("Open Level")
      ])
      
      @openLevel = (command == 1)
      pbMessage(_INTL("You've chosen {1} battles.", @openLevel ? "Open Level" : "Level 50"))
    end

    def pbShowFacilitySelection
      command = pbShowCommands([
        _INTL("Battle Tower"),
        _INTL("Battle Palace"),
        _INTL("Battle Factory"),
        _INTL("Battle Arena"),
        _INTL("Battle Dome"),
        _INTL("Battle Pike"),
        _INTL("Battle Pyramid"),
        _INTL("Battle Hall"),
        _INTL("Battle Castle"),
        _INTL("Battle Arcade"),
        _INTL("Exit")
      ])
      
      case command
      when 0 then pbStartFacility(:TOWER)
      when 1 then pbStartFacility(:PALACE)
      when 2 then pbStartFacility(:FACTORY)
      when 3 then pbStartFacility(:ARENA)
      when 4 then pbStartFacility(:DOME)
      when 5 then pbStartFacility(:PIKE)
      when 6 then pbStartFacility(:PYRAMID)
      when 7 then pbStartFacility(:HALL)
      when 8 then pbStartFacility(:CASTLE)
      when 9 then pbStartFacility(:ARCADE)
      when 10 then return
      end
    end

    def pbStartFacility(facility)
      case facility
      when :TOWER
        scene = BattleTowerScene.new
        screen = BattleTowerScreen.new(scene)
      when :PALACE
        scene = BattlePalaceScene.new
        screen = BattlePalaceScreen.new(scene)
      when :FACTORY
        scene = BattleFactoryScene.new
        screen = BattleFactoryScreen.new(scene)
      when :ARENA
        scene = BattleArenaScene.new
        screen = BattleArenaScreen.new(scene)
      when :DOME
        scene = BattleDomeScene.new
        screen = BattleDomeScreen.new(scene)
      when :PIKE
        scene = BattlePikeScene.new
        screen = BattlePikeScreen.new(scene)
      when :PYRAMID
        scene = BattlePyramidScene.new
        screen = BattlePyramidScreen.new(scene)
      when :HALL
        scene = BattleFrontierPlugin::HallScene.new
        screen = BattleFrontierPlugin::HallScreen.new(scene)
      when :CASTLE
        scene = BattleFrontierPlugin::CastleScene.new
        screen = BattleFrontierPlugin::CastleScreen.new(scene)
      when :ARCADE
        scene = BattleArcadeScene.new
        screen = BattleArcadeScreen.new(scene)
      end
      
      screen.pbStart if screen
    end
  end

  #--------------------------------------------------------------------------
  # * Plugin Commands
  #--------------------------------------------------------------------------
  def self.start_battle_frontier
    scene = BattleFrontierScene.new
    scene.pbStart
  end

  def self.get_battle_points
    return $game_battle_frontier.battlePoints if $game_battle_frontier
    return 0
  end

  def self.has_symbol?(facility)
    return $game_battle_frontier.hasSymbol?(facility) if $game_battle_frontier
    return false
  end

  def self.get_streak(facility)
    return $game_battle_frontier.getStreak(facility) if $game_battle_frontier
    return 0
  end
end

#===============================================================================
# * Game Variables
#===============================================================================
class Game_Variables
  #--------------------------------------------------------------------------
  # * Initialize
  #--------------------------------------------------------------------------
  alias battle_frontier_initialize initialize
  def initialize
    battle_frontier_initialize
    $game_battle_frontier = BattleFrontierPlugin::BattleFrontier.new
  end
end 