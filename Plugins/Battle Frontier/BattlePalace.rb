#===============================================================================
# Battle Palace Scene and Screen
#===============================================================================
class BattlePalaceScene
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
end

class BattlePalaceScreen
  def initialize(scene)
    @scene = scene
    @streak = 0
  end

  def pbStart
    @scene.pbStart
    pbStartChallenge
    @scene.pbEnd
  end

  def pbStartChallenge
    # Welcome message
    pbMessage(_INTL("Welcome to the Battle Palace!"))
    pbMessage(_INTL("Here, your Pokémon will battle based on their nature!"))
    pbMessage(_INTL("You cannot give commands - your Pokémon will choose moves based on their personality."))
    pbMessage(_INTL("Win 21 battles to face Spenser, the Palace Maven!"))
    
    # Choose level rules
    level_adjustment = 0  # Default to Open Level
    cmd = pbMessage(_INTL("Choose a level rule."),
                   [_INTL("Level 50"), _INTL("Open Level"), _INTL("Cancel")], 3)
    case cmd
    when 0  # Level 50
      if !pbHasEligible?(3)  # Just check if they have 3 eligible Pokémon
        pbMessage(_INTL("Your Pokémon are not eligible to participate!"))
        return
      end
      if !pbEntryScreen(3, 50)  # Keep level 50 for the entry screen to show correct stats
        pbMessage(_INTL("You've decided not to participate."))
        return
      end
      level_adjustment = 50
    when 1  # Open Level
      if !pbHasEligible?(3, 100)
        pbMessage(_INTL("Your Pokémon are not eligible to participate!"))
        return
      end
      if !pbEntryScreen(3, 100)
        pbMessage(_INTL("You've decided not to participate."))
        return
      end
      level_adjustment = -1  # Flag for matching player's levels
    else
      pbMessage(_INTL("You've decided not to participate."))
      return
    end

    # Start the challenge
    7.times do |i|
      # Create opponent trainer
      trainer = NPCTrainer.new(
        _INTL("COOLTRAINER_M"),
        :COOLTRAINER_M
      )
      trainer.id = $player.make_foreign_ID
      trainer.party = []
      
      # Create opponent's team based on level rules
      if level_adjustment == 50
        # Level 50 rule - all Pokémon at level 50
        3.times do |j|
          species = GameData::Species.keys.sample
          trainer.party.push(Pokemon.new(species, 50))
        end
      else
        # Open Level rule - use average of player's team levels (minimum 50)
        avg_level = $player.party[0, 3].sum { |p| p.level } / 3
        avg_level = [avg_level, 50].max  # Ensure minimum level 50
        
        3.times do |j|
          species = GameData::Species.keys.sample
          trainer.party.push(Pokemon.new(species, avg_level))
        end
      end
      
      # Battle message
      pbMessage(_INTL("Battle {1} of 7!", i + 1))
      
      # Create battle scene
      scene = Battle::Scene.new
      
      # Create battle with Palace rules
      battle = BattlePalaceBattle.new(scene, $player.party, trainer.party, $player, trainer)
      battle.internalBattle = false
      
      # Start battle
      decision = battle.pbStartBattle
      
      # Handle battle result
      if decision == 1  # Won
        @streak += 1
        pbMessage(_INTL("Congratulations! You won!"))
        # Add BP
        $PokemonGlobal.battlePoints += BattleFrontierPlugin::Settings::POINTS_PER_WIN
        
        # Check if we should face Spenser
        if @streak == 21
          pbMessage(_INTL("Incredible! You've won 21 battles in a row!"))
          pbMessage(_INTL("Spenser, the Palace Maven, wishes to battle you!"))
          # Create Spenser battle
          brain = BattleFrontierPlugin.createBrainTeam(:PALACE, @streak)
          if brain
            scene = Battle::Scene.new
            battle = BattlePalaceBattle.new(scene, $player.party, brain.party, $player, brain)
            decision = battle.pbStartBattle
            if decision == 1
              pbMessage(_INTL("Congratulations! You've defeated Spenser!"))
              $PokemonGlobal.battlePoints += 10  # Bonus BP for defeating Brain
            end
          end
        end
      else  # Lost
        pbMessage(_INTL("You were defeated..."))
        @streak = 0
        break
      end
      
      # Heal party between battles
      $player.party.each { |pkmn| pkmn.heal }
    end
    
    # Challenge complete
    pbMessage(_INTL("Thank you for participating!"))
    pbMessage(_INTL("Your final streak was: {1}", @streak))
  end
end 