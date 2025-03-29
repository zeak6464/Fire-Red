#===============================================================================
# Battle Pyramid System
#===============================================================================
module BattleFrontierPlugin
  module PyramidSettings
    # Number of floors to complete
    FLOORS = 7
    
    # Single dungeon map ID
    DUNGEON_MAP_ID = 51
    
    # Items that can be found in the pyramid
    PYRAMID_ITEMS = [
      :POTION,
      :SUPERPOTION,
      :HYPERPOTION,
      :MAXPOTION,
      :FULLRESTORE,
      :REVIVE,
      :MAXREVIVE,
      :ETHER,
      :MAXETHER,
      :ELIXIR,
      :MAXELIXIR
    ]
  end

  #--------------------------------------------------------------------------
  # * Pyramid Challenge
  #--------------------------------------------------------------------------
  class PyramidChallenge
    attr_reader :current_location
    attr_reader :quit
    attr_reader :lost
    
    def initialize
      @current_floor = 0
      @items_found = []
      @trainers_defeated = 0
      @level_adjustment = 50  # Default to Level 50
      @current_location = nil
      @events_nearby = {}  # Track nearby events by direction
      @current_event = nil # Current event to handle
      @quit = false
      @lost = false
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
      pbMessage(_INTL("Welcome to the Battle Pyramid!"))
      pbMessage(_INTL("You must climb through 7 floors of treacherous dungeons."))
      pbMessage(_INTL("You can find useful items along the way."))
      pbMessage(_INTL("Be careful - your Pokémon won't be healed between floors!"))
      pbMessage(_INTL("Reach the top to face Brandon, the Pyramid King!"))
      
      # Choose level rules
      cmd = pbMessage(_INTL("Choose a level rule."),
                     [_INTL("Level 50"), _INTL("Open Level"), _INTL("Cancel")], 3)
      case cmd
      when 0  # Level 50
        if !pbHasEligible?(3)  # Just check if they have 3 eligible Pokémon
          pbMessage(_INTL("Your Pokémon are not eligible to participate!"))
          return false
        end
        if !pbEntryScreen(3, 50)  # Keep level 50 for the entry screen to show correct stats
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
        _INTL("COOLTRAINER_F"),
        :COOLTRAINER_F
      )
      trainer.id = $player.make_foreign_ID
      trainer.party = []
      
      # Add 3 random Pokémon at appropriate level
      floor_bonus = (@current_floor - 1) * 2  # +2 levels per floor
      max_level = [@level_adjustment + floor_bonus, 100].min  # Cap at level 100
      
      3.times do
        species = GameData::Species.keys.sample
        trainer.party.push(Pokemon.new(species, max_level))
      end
      
      return trainer
    end

    def look_around
      return if !@events_nearby || @events_nearby.empty?
      
      # Check each direction
      ["North", "South", "East", "West"].each do |direction|
        next if !@events_nearby[direction]
        case @events_nearby[direction]
        when :ITEM
          pbMessage(_INTL("You see something shiny to the {1}...", direction))
        when :TRAINER
          pbMessage(_INTL("You sense a trainer's presence to the {1}...", direction))
        when :WILD
          pbMessage(_INTL("You hear rustling in the darkness to the {1}...", direction))
        when :STAIRS
          pbMessage(_INTL("You see stairs leading upward to the {1}...", direction))
        end
      end
    end

    def move_forward(direction)
      return false if !@events_nearby || !@events_nearby[direction]
      
      @current_event = @events_nearby[direction]
      @events_nearby.delete(direction)  # Remove the event from that direction
      
      case @current_event
      when :ITEM
        item = PyramidSettings::PYRAMID_ITEMS.sample
        pbMessage(_INTL("You found a {1}!", GameData::Item.get(item).name))
        if $PokemonBag && $PokemonBag.respond_to?(:add)
          $PokemonBag.add(item)
          @items_found.push(item)
        end
        return true
        
      when :TRAINER
        pbMessage(_INTL("A trainer appears from the darkness!"))
        trainer = create_trainer
        return pbStartBattle(trainer)
        
      when :WILD
        pbMessage(_INTL("A wild Pokémon attacks!"))
        species = GameData::Species.keys.sample
        wild_pkmn = Pokemon.new(species, @level_adjustment)
        scene = Battle::Scene.new
        battle = Battle.new(scene, $player.party, [wild_pkmn], $player, nil)
        battle.internalBattle = false
        decision = battle.pbStartBattle
        return decision == 1
        
      when :STAIRS
        pbMessage(_INTL("You've reached the stairs to the next floor!"))
        return true
      end
      
      return false
    end

    def generate_events
      # Clear previous events
      @events_nearby = {}
      
      # Available directions
      directions = ["North", "South", "East", "West"]
      
      # Add 2-4 events for this section
      events = [:ITEM, :TRAINER, :WILD]
      num_events = rand(2..4)
      num_events.times do
        # Pick a random direction that doesn't have an event yet
        available_dirs = directions.select { |d| !@events_nearby[d] }
        break if available_dirs.empty?
        dir = available_dirs.sample
        @events_nearby[dir] = events.sample
      end
      
      # Add stairs in a random empty direction
      available_dirs = directions.select { |d| !@events_nearby[d] }
      if !available_dirs.empty?
        @events_nearby[available_dirs.sample] = :STAIRS
      end
    end

    def pbStartFloor
      @current_floor += 1
      return false if @current_floor > PyramidSettings::FLOORS
      
      pbMessage(_INTL("Floor {1}", @current_floor))
      
      # Generate new events for this floor
      generate_events
      
      # Darken the screen more as you go up floors
      $game_screen.tone.set((@current_floor * 5), (@current_floor * 5), (@current_floor * 5), 0) if $game_screen
      
      return true
    end

    def pbEndFloor
      # Floor ends when all events are cleared
      return @events_nearby.empty?
    end

    def pbStartBattle(trainer)
      # Create battle scene
      scene = Battle::Scene.new
      
      # Create battle
      battle = Battle.new(scene, $player.party, trainer.party, $player, trainer)
      battle.internalBattle = false
      
      decision = battle.pbStartBattle
      
      if decision == 1  # Won
        @trainers_defeated += 1
        # Add points using the plugin's system
        $game_battle_frontier.addBattlePoints(BattleFrontierPlugin::Settings::POINTS_PER_WIN)
      else
        @lost = true
      end
      
      return decision == 1
    end
  end

  #--------------------------------------------------------------------------
  # * Pyramid Scene
  #--------------------------------------------------------------------------
  class PyramidScene
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

    def pbShowCommands
      commands = [
        _INTL("Look"),
        _INTL("Move"),
        _INTL("Quit")
      ]
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

    def pbShowDirections
      commands = [
        _INTL("North"),
        _INTL("South"),
        _INTL("East"),
        _INTL("West")
      ]
      ret = -1
      @sprites["direction_window"] = Window_CommandPokemon.new(commands)
      @sprites["direction_window"].viewport = @viewport
      @sprites["direction_window"].index = 0
      loop do
        Graphics.update
        Input.update
        pbUpdate
        if Input.trigger?(Input::USE)
          ret = @sprites["direction_window"].index
          break
        end
        if Input.trigger?(Input::BACK)
          ret = -1
          break
        end
      end
      @sprites["direction_window"].dispose
      return ret
    end

    def pbShowFloorInfo(floor, items, trainers)
      # Show current floor information
      pbMessage(_INTL("Floor {1}", floor))
      pbMessage(_INTL("Items remaining: {1}", items))
      pbMessage(_INTL("Trainers remaining: {1}", trainers))
    end
  end
end

#===============================================================================
# Battle Pyramid Scene and Screen
#===============================================================================
class BattlePyramidScene
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

  def pbShowCommands
    commands = [
      _INTL("Look"),
      _INTL("Move"),
      _INTL("Quit")
    ]
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

  def pbShowDirections
    commands = [
      _INTL("North"),
      _INTL("South"),
      _INTL("East"),
      _INTL("West")
    ]
    ret = -1
    @sprites["direction_window"] = Window_CommandPokemon.new(commands)
    @sprites["direction_window"].viewport = @viewport
    @sprites["direction_window"].index = 0
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::USE)
        ret = @sprites["direction_window"].index
        break
      end
      if Input.trigger?(Input::BACK)
        ret = -1
        break
      end
    end
    @sprites["direction_window"].dispose
    return ret
  end

  def pbShowFloorInfo(floor, items, trainers)
    # Show current floor information
    pbMessage(_INTL("Floor {1}", floor))
    pbMessage(_INTL("Items remaining: {1}", items))
    pbMessage(_INTL("Trainers remaining: {1}", trainers))
  end
end

class BattlePyramidScreen
  PYRAMID_ITEMS = [
    :POTION, :SUPERPOTION, :HYPERPOTION,
    :FULLHEAL, :AWAKENING, :ANTIDOTE,
    :PARALYZEHEAL, :BURNHEAL, :ICEHEAL,
    :REVIVE, :MAXREVIVE, :ELIXIR
  ]

  def initialize(scene)
    @scene = scene
    @streak = 0
    @current_floor = 1
    @items_found = []
    @trainers_defeated = 0
    @challenge = BattleFrontierPlugin::PyramidChallenge.new
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
        break if !@challenge.pbStartFloor
        
        # Handle floor events until complete
        loop do
          command = @scene.pbShowCommands
          case command
          when 0  # Look
            @challenge.look_around
          when 1  # Move
            direction_index = @scene.pbShowDirections
            if direction_index >= 0  # Only proceed if a direction was chosen
              direction = ["North", "South", "East", "West"][direction_index]
              if @challenge.move_forward(direction)
                if @challenge.pbEndFloor
                  break  # Floor complete
                end
              end
            end
          when 2  # Quit
            if pbConfirmMessage(_INTL("Would you like to quit the challenge?"))
              pbMessage(_INTL("You've decided to quit..."))
              @challenge.quit
              break
            end
          end
        end
        
        # Break if player quit or lost
        break if @challenge.quit? || @challenge.lost?
      end
      
      # Return to Battle Frontier only after challenge is complete
      if @challenge.current_location
        pbFadeOutIn {
          $game_temp.player_transferring = true
          $game_temp.player_new_map_id = @challenge.current_location[0]
          $game_temp.player_new_x = @challenge.current_location[1]
          $game_temp.player_new_y = @challenge.current_location[2]
          $game_temp.player_new_direction = 2
          $scene.transfer_player
          $game_map.autoplay
        }
      end
    end
    
    # End the scene
    @scene.pbEnd
    
    # Restore the original party
    $player.party = @oldParty
  end

  def pbGenerateFloor
    # Each floor has:
    # - 3-5 items to find
    # - 2-4 trainers to battle
    # - Darker lighting as you go up
    {
      items: rand(3..5),
      trainers: rand(2..4),
      darkness: @current_floor * 20  # Gets darker each floor
    }
  end

  def pbStartChallenge
    # Welcome message
    pbMessage(_INTL("Welcome to the Battle Pyramid!"))
    pbMessage(_INTL("Explore each floor to find items and battle trainers!"))
    pbMessage(_INTL("The pyramid gets darker as you climb..."))
    pbMessage(_INTL("Reach floor 7 to face Brandon, the Pyramid King!"))
    
    # Check party size
    if $player.party.length < 3
      pbMessage(_INTL("You need 3 Pokémon to participate!"))
      return
    end

    # Initialize BP if needed
    $PokemonGlobal.battle_points = 0 if !$PokemonGlobal.respond_to?(:battle_points)

    # Start the challenge
    while @current_floor <= 7
      # Generate floor
      floor = pbGenerateFloor
      items_remaining = floor[:items]
      trainers_remaining = floor[:trainers]
      
      # Show floor info
      @scene.pbShowFloorInfo(@current_floor, items_remaining, trainers_remaining)
      
      # Explore floor
      while items_remaining > 0 || trainers_remaining > 0
        # Random event (item or trainer)
        if rand(2) == 0 && items_remaining > 0
          # Find item
          item = PYRAMID_ITEMS.sample
          pbMessage(_INTL("You found a {1}!", item.to_s))
          $PokemonBag.add(item)
          @items_found.push(item)
          items_remaining -= 1
          
        elsif trainers_remaining > 0
          # Battle trainer
          pbMessage(_INTL("A trainer appears in the darkness!"))
          trainer = pbCreateTrainer("HIKER", "PYRAMID TRAINER")
          trainer.party = pbCreateTrainerParty(3, 50)
          
          # Create battle
          scene = PokeBattle_Scene.new
          battle = PokeBattle_Battle.new(scene, $player.party, trainer.party, $player, trainer)
          battle.internalBattle = false
          
          # Start battle
          decision = battle.pbStartBattle
          
          if decision == 1  # Won
            @trainers_defeated += 1
            trainers_remaining -= 1
            @streak += 1
            pbMessage(_INTL("You won! Trainers remaining: {1}", trainers_remaining))
            $PokemonGlobal.battle_points += BattleFrontierPlugin::Settings::POINTS_PER_WIN
          else  # Lost
            pbMessage(_INTL("You were defeated..."))
            return
          end
        end
        
        # Show current status
        @scene.pbShowFloorInfo(@current_floor, items_remaining, trainers_remaining)
      end
      
      # Floor complete
      pbMessage(_INTL("Floor {1} complete!", @current_floor))
      
      # Check if we should face Brandon
      if @current_floor == 7
        pbMessage(_INTL("You've reached the top of the pyramid!"))
        pbMessage(_INTL("Brandon, the Pyramid King, appears!"))
        # Create Brandon battle
        brain = BattleFrontierPlugin.createBrainTeam(:PYRAMID, @streak)
        if brain
          scene = PokeBattle_Scene.new
          battle = PokeBattle_Battle.new(scene, $player.party, brain.party, $player, brain)
          decision = battle.pbStartBattle
          if decision == 1
            pbMessage(_INTL("Congratulations! You've defeated Brandon!"))
            $PokemonGlobal.battle_points += 10  # Bonus BP for defeating Brain
          end
        end
        break
      end
      
      # Heal between floors
      $player.party.each { |pkmn| pkmn.heal }
      @current_floor += 1
    end
    
    # Challenge complete
    pbMessage(_INTL("Thank you for participating!"))
    pbMessage(_INTL("You reached floor {1}!", @current_floor))
    pbMessage(_INTL("Items collected: {1}", @items_found.length))
    pbMessage(_INTL("Trainers defeated: {1}", @trainers_defeated))
  end
end

def self.start
  scene = BattlePyramidScene.new
  screen = BattlePyramidScreen.new(scene)
  pbFadeOutIn {
    screen.pbStart
  }
end 