#===============================================================================
# Battle Factory Scene and Screen
#===============================================================================
class BattleFactoryScene
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

  def pbShowRentalChoice(rentals)
    commands = []
    rentals.each do |pkmn|
      commands.push(_INTL("{1} (Lv.{2})", pkmn.name, pkmn.level))
    end
    ret = -1
    @sprites["command_window"] = Window_CommandPokemon.new(commands)
    @sprites["command_window"].viewport = @viewport
    @sprites["command_window"].index = 0
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::USE)
        ret = @sprites["command_window"].index
        break
      end
    end
    @sprites["command_window"].dispose
    return ret
  end
end

class BattleFactoryScreen
  def initialize(scene)
    @scene = scene
    @streak = 0
    @rental_party = []
  end

  def pbStart
    @scene.pbStart
    pbStartChallenge
    @scene.pbEnd
  end

  def pbStartChallenge
    # Welcome message
    pbMessage(_INTL("Welcome to the Battle Factory!"))
    pbMessage(_INTL("Here, you'll use rental Pokémon to battle!"))
    pbMessage(_INTL("First, choose 3 Pokémon to rent."))
    pbMessage(_INTL("After each win, you can swap one with your opponent's!"))
    pbMessage(_INTL("Win 21 battles to face Noland, the Factory Head!"))
    
    # Choose level rules
    level_adjustment = 0  # Default to Open Level
    cmd = pbMessage(_INTL("Choose a level rule."),
                   [_INTL("Level 50"), _INTL("Open Level"), _INTL("Cancel")], 3)
    case cmd
    when 0  # Level 50
      level_adjustment = 50
    when 1  # Open Level
      level_adjustment = 100
    else
      pbMessage(_INTL("You've decided not to participate."))
      return
    end
    
    # Create rental Pokémon
    rentals = []
    6.times { rentals.push(pbCreateRentalPokemon(level_adjustment)) }
    
    # Choose rental Pokémon
    3.times do
      pbMessage(_INTL("Choose a Pokémon to rent ({1} remaining)!", 3 - @rental_party.length))
      choice = @scene.pbShowRentalChoice(rentals)
      if choice >= 0
        @rental_party.push(rentals[choice])
        rentals.delete_at(choice)
      end
    end

    # Start the challenge
    7.times do |i|
      # Create opponent trainer
      trainer = NPCTrainer.new(
        _INTL("SCIENTIST"),
        :SCIENTIST
      )
      trainer.id = $player.make_foreign_ID
      trainer.party = []
      3.times { trainer.party.push(pbCreateRentalPokemon(level_adjustment)) }
      
      # Battle message
      pbMessage(_INTL("Battle {1} of 7!", i + 1))
      
      # Create battle scene
      scene = Battle::Scene.new
      
      # Create battle
      battle = Battle.new(scene, @rental_party, trainer.party, $player, trainer)
      battle.internalBattle = false
      
      # Start battle
      decision = battle.pbStartBattle
      
      # Handle battle result
      if decision == 1  # Won
        @streak += 1
        pbMessage(_INTL("Congratulations! You won!"))
        # Add BP
        $PokemonGlobal.battlePoints += BattleFrontierPlugin::Settings::POINTS_PER_WIN
        
        # Offer to swap Pokémon
        pbMessage(_INTL("Would you like to swap one of your Pokémon with your opponent's?"))
        if pbShowCommands(["Yes", "No"], -1) == 0
          yours = @scene.pbShowRentalChoice(@rental_party)
          theirs = @scene.pbShowRentalChoice(trainer.party)
          if yours >= 0 && theirs >= 0
            @rental_party[yours], trainer.party[theirs] = trainer.party[theirs], @rental_party[yours]
            pbMessage(_INTL("Pokémon swapped!"))
          end
        end
        
        # Check if we should face Noland
        if @streak == 21
          pbMessage(_INTL("Incredible! You've won 21 battles in a row!"))
          pbMessage(_INTL("Noland, the Factory Head, wishes to battle you!"))
          # Create Noland battle
          brain = BattleFrontierPlugin.createBrainTeam(:FACTORY, @streak)
          if brain
            scene = Battle::Scene.new
            battle = Battle.new(scene, @rental_party, brain.party, $player, brain)
            decision = battle.pbStartBattle
            if decision == 1
              pbMessage(_INTL("Congratulations! You've defeated Noland!"))
              $PokemonGlobal.battlePoints += 10  # Bonus BP for defeating Brain
            end
          end
        end
      else  # Lost
        pbMessage(_INTL("You were defeated..."))
        @streak = 0
        break
      end
      
      # Heal rental party between battles
      @rental_party.each { |pkmn| pkmn.heal }
    end
    
    # Challenge complete
    pbMessage(_INTL("Thank you for participating!"))
    pbMessage(_INTL("Your final streak was: {1}", @streak))
    @rental_party.clear
  end

  def pbCreateRentalPokemon(level = 50)
    species = GameData::Species.keys.sample
    pkmn = Pokemon.new(species, level)
    # Give random moves
    moves = pkmn.getMoveList
    pkmn.moves.clear
    4.times do
      move = moves.sample
      pkmn.learn_move(move[1]) if move
    end
    return pkmn
  end
end 