#===============================================================================
# Battle Pike Scene and Screen
#===============================================================================
class BattlePikeScene
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

  def pbShowRoomChoice
    commands = [_INTL("Left Room"), _INTL("Center Room"), _INTL("Right Room")]
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

class BattlePikeScreen
  ROOM_TYPES = [
    :BATTLE,      # Single battle
    :DOUBLE,      # Double battle
    :STATUS,      # Random status effect
    :HEAL,        # Heal party
    :ITEM,        # Find an item
    :TRAINER      # Tough trainer battle
  ]

  def initialize(scene)
    @scene = scene
    @streak = 0
    @rooms_cleared = 0
    @level_adjustment = 50  # Default to Level 50
  end

  def pbStart
    @scene.pbStart
    pbStartChallenge
    @scene.pbEnd
  end

  def pbApplyStatus(pkmn)
    status = [:SLEEP, :POISON, :BURN, :PARALYSIS, :FROZEN].sample
    case status
    when :SLEEP
      pkmn.sleep
      pbMessage(_INTL("{1} fell asleep!", pkmn.name))
    when :POISON
      pkmn.poison
      pbMessage(_INTL("{1} was poisoned!", pkmn.name))
    when :BURN
      pkmn.burn
      pbMessage(_INTL("{1} was burned!", pkmn.name))
    when :PARALYSIS
      pkmn.paralyze
      pbMessage(_INTL("{1} was paralyzed!", pkmn.name))
    when :FROZEN
      pkmn.freeze
      pbMessage(_INTL("{1} was frozen solid!", pkmn.name))
    end
  end

  def pbStartChallenge
    # Welcome message
    pbMessage(_INTL("Welcome to the Battle Pike!"))
    pbMessage(_INTL("Choose between three rooms as you progress!"))
    pbMessage(_INTL("Each room holds a different challenge!"))
    pbMessage(_INTL("Reach 28 rooms to face Lucy, the Pike Queen!"))
    
    # Choose level rules
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
      @level_adjustment = 50
    when 1  # Open Level
      if !pbHasEligible?(3, 100)
        pbMessage(_INTL("Your Pokémon are not eligible to participate!"))
        return
      end
      if !pbEntryScreen(3, 100)
        pbMessage(_INTL("You've decided not to participate."))
        return
      end
      # Calculate average level of player's team (minimum 50)
      avg_level = $player.party[0, 3].sum { |p| p.level } / 3
      @level_adjustment = [avg_level, 50].max
    else
      pbMessage(_INTL("You've decided not to participate."))
      return
    end

    # Start the challenge
    loop do
      # Show room choice
      pbMessage(_INTL("Choose your next room:"))
      choice = @scene.pbShowRoomChoice
      break if choice < 0
      
      # Determine room type
      room_type = ROOM_TYPES.sample
      
      # Handle room event
      case room_type
      when :BATTLE
        # Regular single battle
        trainer = NPCTrainer.new(
          _INTL("COOLTRAINER_F"),
          :COOLTRAINER_F
        )
        trainer.id = $player.make_foreign_ID
        trainer.party = []
        3.times do
          species = GameData::Species.keys.sample
          trainer.party.push(Pokemon.new(species, @level_adjustment))
        end
        
        scene = Battle::Scene.new
        battle = Battle.new(scene, $player.party, trainer.party, $player, trainer)
        battle.internalBattle = false
        decision = battle.pbStartBattle
        
        if decision == 1  # Won
          @streak += 1
          $PokemonGlobal.battlePoints += BattleFrontierPlugin::Settings::POINTS_PER_WIN
        else
          pbMessage(_INTL("You were defeated..."))
          break
        end
        
      when :DOUBLE
        # Double battle
        trainer = NPCTrainer.new(
          _INTL("COOLTRAINER_F"),
          :COOLTRAINER_F
        )
        trainer.id = $player.make_foreign_ID
        trainer.party = []
        4.times do
          species = GameData::Species.keys.sample
          trainer.party.push(Pokemon.new(species, @level_adjustment))
        end
        
        scene = Battle::Scene.new
        battle = Battle.new(scene, $player.party, trainer.party, $player, trainer)
        battle.internalBattle = false
        battle.rules["doublebattle"] = true
        decision = battle.pbStartBattle
        
        if decision == 1  # Won
          @streak += 1
          $PokemonGlobal.battlePoints += BattleFrontierPlugin::Settings::POINTS_PER_WIN
        else
          pbMessage(_INTL("You were defeated..."))
          break
        end
        
      when :STATUS
        # Apply random status to random party member
        pbMessage(_INTL("This room is filled with a strange atmosphere..."))
        pkmn = $player.party.sample
        pbApplyStatus(pkmn)
        
      when :HEAL
        # Heal party
        pbMessage(_INTL("You found a healing room!"))
        $player.party.each { |pkmn| pkmn.heal }
        pbMessage(_INTL("Your Pokémon were fully healed!"))
        
      when :ITEM
        # Find a random item
        items = [:POTION, :SUPERPOTION, :FULLHEAL, :REVIVE].sample
        pbMessage(_INTL("You found a {1}!", GameData::Item.get(items).name))
        if $PokemonBag && $PokemonBag.respond_to?(:add)
          $PokemonBag.add(items)
        else
          # Fallback if bag doesn't exist
          pbReceiveItem(items)
        end
        
      when :TRAINER
        # Tough trainer battle
        pbMessage(_INTL("A strong trainer appears!"))
        trainer = NPCTrainer.new(
          _INTL("COOLTRAINER_F"),
          :COOLTRAINER_F
        )
        trainer.id = $player.make_foreign_ID
        trainer.party = []
        3.times do
          species = GameData::Species.keys.sample
          trainer.party.push(Pokemon.new(species, @level_adjustment + 5))  # Higher level
        end
        
        scene = Battle::Scene.new
        battle = Battle.new(scene, $player.party, trainer.party, $player, trainer)
        battle.internalBattle = false
        decision = battle.pbStartBattle
        
        if decision == 1  # Won
          @streak += 1
          $PokemonGlobal.battlePoints += BattleFrontierPlugin::Settings::POINTS_PER_WIN
        else
          pbMessage(_INTL("You were defeated..."))
          break
        end
      end
      
      # Increment room counter
      @rooms_cleared += 1
      
      # Check if we should face Lucy
      if @rooms_cleared == 28
        pbMessage(_INTL("Incredible! You've cleared 28 rooms!"))
        pbMessage(_INTL("Lucy, the Pike Queen, wishes to battle you!"))
        
        # Create Lucy battle
        brain = BattleFrontierPlugin.createBrainTeam(:PIKE, @streak)
        if brain
          scene = Battle::Scene.new
          battle = Battle.new(scene, $player.party, brain.party, $player, brain)
          decision = battle.pbStartBattle
          if decision == 1
            pbMessage(_INTL("Congratulations! You've defeated Lucy!"))
            $PokemonGlobal.battlePoints += 10  # Bonus BP for defeating Brain
          end
        end
        break
      end
      
      # Show progress
      pbMessage(_INTL("Rooms cleared: {1}/28", @rooms_cleared))
    end
    
    # Challenge complete
    pbMessage(_INTL("Thank you for participating!"))
    pbMessage(_INTL("You cleared {1} rooms!", @rooms_cleared))
  end
end 