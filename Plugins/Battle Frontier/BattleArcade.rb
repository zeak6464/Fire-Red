#===============================================================================
# Battle Arcade System
#===============================================================================
module BattleFrontierPlugin
  module ArcadeSettings
    # Number of battles per round
    BATTLES_PER_ROUND = 7
    
    # Map ID for the Arcade
    ARCADE_MAP_ID = 55
    
    # Event Types
    EVENT_TYPES = {
      # Player Events
      :PLAYER => {
        :HP_HALVE => { effect: :hp_halve, desc: "Halve opponent's HP", cost: 5 },
        :STAT_BOOST => { effect: :stat_boost, desc: "Boost all stats", cost: 3 },
        :TYPE_CHANGE => { effect: :type_change, desc: "Change opponent's type", cost: 4 },
        :HEAL => { effect: :heal, desc: "Restore HP", cost: 2 }
      },
      # Opponent Events
      :OPPONENT => {
        :HP_HALVE => { effect: :hp_halve, desc: "Halve your HP", cost: 5 },
        :STAT_BOOST => { effect: :stat_boost, desc: "Boost opponent's stats", cost: 3 },
        :TYPE_CHANGE => { effect: :type_change, desc: "Change your type", cost: 4 },
        :HEAL => { effect: :heal, desc: "Restore opponent's HP", cost: 2 }
      },
      # Field Events
      :FIELD => {
        :SUNNY => { effect: :sunny, desc: "Set Sunny Day", cost: 2 },
        :RAIN => { effect: :rain, desc: "Set Rain Dance", cost: 2 },
        :SANDSTORM => { effect: :sandstorm, desc: "Set Sandstorm", cost: 2 },
        :HAIL => { effect: :hail, desc: "Set Hail", cost: 2 }
      }
    }
  end

  #--------------------------------------------------------------------------
  # * Arcade Challenge
  #--------------------------------------------------------------------------
  class ArcadeChallenge
    attr_reader :current_battle
    attr_reader :current_round
    attr_reader :streak
    attr_reader :quit
    attr_reader :lost
    attr_reader :points
    
    def initialize
      @current_battle = 0
      @current_round = 0
      @streak = 0
      @quit = false
      @lost = false
      @points = 5  # Start with 5 points
      # Initialize Battle Frontier if not already done
      $game_battle_frontier = BattleFrontierPlugin::BattleFrontier.new if !$game_battle_frontier
    end

    def quit?
      return @quit
    end

    def lost?
      return @lost
    end

    def quit
      @quit = true
    end

    def start
      pbMessage(_INTL("Welcome to the Battle Arcade!"))
      pbMessage(_INTL("Before each battle, you'll get random events!"))
      pbMessage(_INTL("You start with 5 points each round."))
      pbMessage(_INTL("Win 7 battles to face Dahlia, the Arcade Star!"))
      
      # Choose level rules
      cmd = pbMessage(_INTL("Choose a level rule."),
                     [_INTL("Level 50"), _INTL("Open Level"), _INTL("Cancel")], 3)
      case cmd
      when 0  # Level 50
        if !pbHasEligible?(3)
          pbMessage(_INTL("Your Pokémon are not eligible to participate!"))
          return false
        end
        if !pbEntryScreen(3, 50)
          pbMessage(_INTL("You've decided not to participate."))
          return false
        end
        @level_adjustment = 50
      when 1  # Open Level
        if !pbHasEligible?(3, 100)
          pbMessage(_INTL("Your Pokémon are not eligible to participate!"))
          return false
        end
        if !pbEntryScreen(3, 100)
          pbMessage(_INTL("You've decided not to participate."))
          return false
        end
        # Calculate average level of player's team (minimum 50)
        avg_level = $player.party[0, 3].sum { |p| p.level } / 3
        @level_adjustment = [avg_level, 50].max
      else
        pbMessage(_INTL("You've decided not to participate."))
        return false
      end
      
      return true
    end

    def create_trainer
      trainer = NPCTrainer.new(
        _INTL("Arcade Trainer"),
        :COOLTRAINER_F
      )
      trainer.id = $player.make_foreign_ID
      trainer.party = []
      
      # Add 3 random Pokémon
      round_bonus = (@current_round - 1) * 2  # +2 levels per round
      max_level = [@level_adjustment + round_bonus, 100].min  # Cap at level 100
      
      3.times do
        species = GameData::Species.keys.sample
        trainer.party.push(Pokemon.new(species, max_level))
      end
      
      return trainer
    end

    def get_random_event
      # Randomly select event type (Player, Opponent, or Field)
      event_type = ArcadeSettings::EVENT_TYPES.keys.sample
      # Randomly select event from that type
      event = ArcadeSettings::EVENT_TYPES[event_type].keys.sample
      return [event_type, event]
    end

    def show_events
      pbMessage(_INTL("Current Points: {1}", @points))
      
      # Get 3 random events
      events = []
      3.times do
        event_type, event = get_random_event
        data = ArcadeSettings::EVENT_TYPES[event_type][event]
        events.push([event_type, event, data])
      end
      
      # Show events and let player choose
      commands = []
      events.each do |event_type, event, data|
        if @points >= data[:cost]
          commands.push(_INTL("{1} ({2} points)", data[:desc], data[:cost]))
        end
      end
      commands.push(_INTL("Start Battle"))
      commands.push(_INTL("Quit"))
      
      # Show menu and get selection
      cmd = pbMessage(_INTL("Choose an event or start battle:"), commands, -1)
      
      if cmd < events.length
        # Get selected event
        event_type, event, data = events[cmd]
        if @points >= data[:cost]
          @points -= data[:cost]
          pbMessage(_INTL("You selected: {1}", data[:desc]))
          apply_effect(event_type, event)
          return true
        end
      elsif cmd == events.length
        # Start Battle
        return true
      else
        # Quit
        if pbConfirmMessage(_INTL("Would you like to quit the challenge?"))
          pbMessage(_INTL("You've decided to quit..."))
          @quit = true
          return false
        end
        return false
      end
      
      return true
    end

    def apply_effect(event_type, event)
      case event_type
      when :PLAYER
        case event
        when :hp_halve
          $game_temp.battle_party.each { |p| p.hp = p.totalhp / 2 }
        when :stat_boost
          $player.party.each do |p|
            p.stages[:ATTACK] = 6
            p.stages[:DEFENSE] = 6
            p.stages[:SPEED] = 6
            p.stages[:SPECIAL_ATTACK] = 6
            p.stages[:SPECIAL_DEFENSE] = 6
          end
        when :type_change
          $game_temp.battle_party.each do |p|
            p.types = [GameData::Type.keys.sample]
          end
        when :heal
          $game_temp.battle_party.each { |p| p.heal }
        end
      when :OPPONENT
        case event
        when :hp_halve
          $player.party.each { |p| p.hp = p.totalhp / 2 }
        when :stat_boost
          $game_temp.battle_party.each do |p|
            p.stages[:ATTACK] = 6
            p.stages[:DEFENSE] = 6
            p.stages[:SPEED] = 6
            p.stages[:SPECIAL_ATTACK] = 6
            p.stages[:SPECIAL_DEFENSE] = 6
          end
        when :type_change
          $player.party.each do |p|
            p.types = [GameData::Type.keys.sample]
          end
        when :heal
          $player.party.each { |p| p.heal }
        end
      when :FIELD
        case event
        when :sunny
          $game_temp.battle_weather = :SunnyDay
        when :rain
          $game_temp.battle_weather = :RainDance
        when :sandstorm
          $game_temp.battle_weather = :Sandstorm
        when :hail
          $game_temp.battle_weather = :Hail
        end
      end
    end

    def pbStartTrainerBattle(trainer)
      # Create battle scene
      scene = Battle::Scene.new
      
      # Create battle
      battle = Battle.new(scene, $player.party, trainer.party, $player, trainer)
      battle.internalBattle = false
      
      decision = battle.pbStartBattle
      
      if decision == 1  # Won
        @streak += 1
        # Add points using the plugin's system
        $game_battle_frontier.addBattlePoints(BattleFrontierPlugin::Settings::POINTS_PER_WIN)
      else
        @lost = true
      end
      
      return decision == 1
    end

    def pbStartRound
      @current_round += 1
      @current_battle = 0
      @points = 5  # Reset points for new round
      return @current_round <= 3  # Maximum 3 rounds
    end

    def pbStartBattle
      @current_battle += 1
      return @current_battle <= ArcadeSettings::BATTLES_PER_ROUND
    end
  end

  #--------------------------------------------------------------------------
  # * Arcade Scene
  #--------------------------------------------------------------------------
  class ArcadeScene
    def initialize
      @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
      @viewport.z = 99999
      @sprites = {}
    end

    def pbStart
      pbFadeInAndShow(@sprites) { pbUpdate }
    end

    def pbEnd
      pbFadeOutAndHide(@sprites) { pbUpdate }
      dispose
    end

    def dispose
      pbDisposeSpriteHash(@sprites)
      @viewport.dispose
    end

    def pbUpdate
      Graphics.update
      Input.update
      pbUpdateSpriteHash(@sprites)
    end

    def pbShowRoundInfo(round, battle)
      # Show current round and battle information
      pbMessage(_INTL("Round {1}", round))
      pbMessage(_INTL("Battle {1}", battle))
    end
  end
end

#===============================================================================
# Battle Arcade Scene and Screen
#===============================================================================
class BattleArcadeScene
  def initialize
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
  end

  def pbStart
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbEnd
    pbFadeOutAndHide(@sprites) { pbUpdate }
    dispose
  end

  def dispose
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def pbUpdate
    Graphics.update
    Input.update
    pbUpdateSpriteHash(@sprites)
  end

  def pbShowRoundInfo(round, battle)
    # Show current round and battle information
    pbMessage(_INTL("Round {1}", round))
    pbMessage(_INTL("Battle {1}", battle))
  end
end

class BattleArcadeScreen
  def initialize(scene)
    @scene = scene
    @streak = 0
    @current_round = 1
    @current_battle = 1
    @challenge = BattleFrontierPlugin::ArcadeChallenge.new
  end

  def pbStart
    # Save the current party
    @oldParty = $player.party.clone
    
    # Start the scene
    @scene.pbStart
    
    # Start the challenge
    if @challenge.start
      # Continue until challenge is complete
      loop do
        break if !@challenge.pbStartRound
        
        # Handle battles until round is complete
        loop do
          break if !@challenge.pbStartBattle
          
          # Show round info
          @scene.pbShowRoundInfo(@current_round, @current_battle)
          
          # Show events and get selection
          if !@challenge.show_events
            break
          end
          
          # Create and start battle
          trainer = @challenge.create_trainer
          if !@challenge.pbStartTrainerBattle(trainer)
            break
          end
          
          # Break if player quit or lost
          break if @challenge.quit? || @challenge.lost?
          
          # Update battle counter
          @current_battle += 1
        end
        
        # Break if player quit or lost
        break if @challenge.quit? || @challenge.lost?
        
        # Update round counter
        @current_round += 1
      end
      
      # Check if player reached Dahlia
      if @challenge.current_battle == ArcadeSettings::BATTLES_PER_ROUND && !@challenge.lost?
        pbMessage(_INTL("You've reached the final battle!"))
        pbMessage(_INTL("Dahlia, the Arcade Star, appears!"))
        
        # Create Dahlia battle
        brain = BattleFrontierPlugin.createBrainTeam(:ARCADE, @streak)
        if brain
          scene = Battle::Scene.new
          battle = Battle.new(scene, $player.party, brain.party, $player, brain)
          battle.internalBattle = false
          decision = battle.pbStartBattle
          if decision == 1
            pbMessage(_INTL("Congratulations! You've defeated Dahlia!"))
            $game_battle_frontier.addBattlePoints(10)  # Bonus BP for defeating Brain
          end
        end
      end
    end
    
    # End the scene
    @scene.pbEnd
    
    # Restore the original party
    $player.party = @oldParty
  end
end

def start
  scene = BattleArcadeScene.new
  screen = BattleArcadeScreen.new(scene)
  pbFadeOutIn {
    screen.pbStart
  }
end 