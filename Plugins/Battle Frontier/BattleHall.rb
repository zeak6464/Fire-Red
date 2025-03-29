#===============================================================================
# Battle Hall System
#===============================================================================
module BattleFrontierPlugin
  module HallSettings
    # Number of battles per round
    BATTLES_PER_ROUND = 10
    
    # Map ID for the Hall
    HALL_MAP_ID = 54
    
    # Ranking system
    RANKS = {
      0 => { name: "Beginner", min_wins: 0 },
      1 => { name: "Novice", min_wins: 10 },
      2 => { name: "Adept", min_wins: 20 },
      3 => { name: "Expert", min_wins: 30 },
      4 => { name: "Master", min_wins: 40 },
      5 => { name: "Grand Master", min_wins: 50 }
    }
    
    # Type-based trainers
    TYPE_TRAINERS = {
      :NORMAL => { name: "Normal-type Expert", types: [:NORMAL] },
      :FIRE => { name: "Fire-type Expert", types: [:FIRE] },
      :WATER => { name: "Water-type Expert", types: [:WATER] },
      :ELECTRIC => { name: "Electric-type Expert", types: [:ELECTRIC] },
      :GRASS => { name: "Grass-type Expert", types: [:GRASS] },
      :ICE => { name: "Ice-type Expert", types: [:ICE] },
      :FIGHTING => { name: "Fighting-type Expert", types: [:FIGHTING] },
      :POISON => { name: "Poison-type Expert", types: [:POISON] },
      :GROUND => { name: "Ground-type Expert", types: [:GROUND] },
      :FLYING => { name: "Flying-type Expert", types: [:FLYING] },
      :PSYCHIC => { name: "Psychic-type Expert", types: [:PSYCHIC] },
      :BUG => { name: "Bug-type Expert", types: [:BUG] },
      :ROCK => { name: "Rock-type Expert", types: [:ROCK] },
      :GHOST => { name: "Ghost-type Expert", types: [:GHOST] },
      :DRAGON => { name: "Dragon-type Expert", types: [:DRAGON] },
      :DARK => { name: "Dark-type Expert", types: [:DARK] },
      :STEEL => { name: "Steel-type Expert", types: [:STEEL] },
      :FAIRY => { name: "Fairy-type Expert", types: [:FAIRY] }
    }
    
    # Pokémon groups based on BST
    POKEMON_GROUPS = {
      1 => { max_bst: 339, ranks: 1..5 },    # Group 1: BST 339 or lower
      2 => { min_bst: 340, max_bst: 439, ranks: 3..8 },  # Group 2: BST 340-439
      3 => { min_bst: 440, max_bst: 499, ranks: 6..10 }, # Group 3: BST 440-499
      4 => { min_bst: 500, ranks: 9..10 }    # Group 4: BST 500 or higher
    }
    
    # Record milestones for fans
    FAN_MILESTONES = {
      1 => 1,    # 1 Pokémon with record
      2 => 11,   # 11 Pokémon with record
      3 => 31,   # 31 Pokémon with record
      4 => 51,   # 51 Pokémon with record
      5 => 101,  # 101 Pokémon with record
      6 => 151,  # 151 Pokémon with record
      7 => 251,  # 251 Pokémon with record
      8 => 351,  # 351 Pokémon with record
      9 => 475   # All eligible Pokémon
    }
    
    # Total record milestones for bonus BP
    RECORD_MILESTONES = {
      10 => 1,
      30 => 3,
      50 => 5, 100 => 5, 150 => 5, 200 => 5, 250 => 5, 300 => 5, 350 => 5, 400 => 5, 450 => 5,
      500 => 10, 600 => 10, 700 => 10, 800 => 10, 900 => 10, 1000 => 10,
      1200 => 30, 1400 => 30, 1600 => 30, 1800 => 30,
      2000 => 50
    }
  end

  #--------------------------------------------------------------------------
  # * Hall Challenge
  #--------------------------------------------------------------------------
  class HallChallenge
    attr_reader :current_battle
    attr_reader :current_round
    attr_reader :streak
    attr_reader :quit
    attr_reader :lost
    attr_reader :rank
    attr_reader :total_wins
    attr_reader :type_ranks
    attr_reader :selected_pokemon
    attr_reader :total_record
    
    def initialize
      @current_battle = 0
      @current_round = 0
      @streak = 0
      @quit = false
      @lost = false
      @rank = 0
      @total_wins = 0
      @selected_pokemon = nil
      @total_record = 0
      @type_ranks = {}
      @used_types = []  # Track types used in current round
      HallSettings::TYPE_TRAINERS.keys.each { |type| @type_ranks[type] = 1 }
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
      pbMessage(_INTL("Welcome to the Battle Hall!"))
      pbMessage(_INTL("Here, you'll battle with a single Pokémon."))
      pbMessage(_INTL("Choose your Pokémon wisely!"))
      
      # Check if player has a Pokémon level 30 or higher
      if !pbHasEligible?(1, 30)
        pbMessage(_INTL("You need at least one Pokémon level 30 or higher to participate!"))
        return false
      end
      
      # Choose Pokémon
      if !pbEntryScreen(1, 30)  # Changed from 3 to 1
        pbMessage(_INTL("You've decided not to participate."))
        return false
      end
      
      # Store the selected Pokémon
      @selected_pokemon = $player.party[0]
      
      # Check if this is a different Pokémon from last time
      if $game_battle_frontier.last_hall_pokemon && 
         $game_battle_frontier.last_hall_pokemon != @selected_pokemon.species
        pbMessage(_INTL("Warning: You're using a different Pokémon than last time."))
        pbMessage(_INTL("Your streak will be lost if you continue."))
        if !pbConfirmMessage(_INTL("Would you like to continue?"))
          return false
        end
      end
      
      # Store this Pokémon for next time
      $game_battle_frontier.last_hall_pokemon = @selected_pokemon.species
      
      return true
    end

    def calculate_opponent_level(selected_type)
      player_level = @selected_pokemon.level
      base_level = player_level - (3 * player_level / 10)
      
      # Count types at rank 2 or higher (excluding selected type)
      types_above_rank_1 = @type_ranks.count { |type, rank| 
        type != selected_type && rank >= 2 
      }
      
      # Calculate level based on formula
      level = base_level + (types_above_rank_1 / 2) + 
              ((@type_ranks[selected_type] - 1) * (player_level / 5))
      
      # Cap at player's level
      return [level, player_level].min
    end

    def get_available_types
      available = []
      HallSettings::TYPE_TRAINERS.each do |type, _|
        # Only add types that are not at rank 10 and haven't been used this round
        if @type_ranks[type] <= 10 && !@used_types.include?(type)
          available.push(type)
        end
      end
      return available
    end

    def select_type
      available_types = get_available_types
      if available_types.empty?
        if @used_types.size == HallSettings::BATTLES_PER_ROUND
          pbMessage(_INTL("You've battled all available types this round!"))
        else
          pbMessage(_INTL("All remaining types have reached Rank 10!"))
        end
        return nil
      end
      
      commands = available_types.map { |type| 
        _INTL("{1} (Rank {2})", 
              HallSettings::TYPE_TRAINERS[type][:name], 
              @type_ranks[type])
      }
      
      cmd = pbMessage(_INTL("Select a type to battle:"), commands, -1)
      return nil if cmd < 0
      
      selected_type = available_types[cmd]
      @used_types.push(selected_type) # Add to used types when selected
      return selected_type
    end

    def create_trainer(selected_type)
      trainer = NPCTrainer.new(
        _INTL(HallSettings::TYPE_TRAINERS[selected_type][:name]),
        :COOLTRAINER_F
      )
      trainer.id = $player.make_foreign_ID
      trainer.party = []
      
      # Calculate opponent level
      level = calculate_opponent_level(selected_type)
      
      # Get Pokémon group based on rank
      group = HallSettings::POKEMON_GROUPS.find { |_, data| 
        data[:ranks].include?(@type_ranks[selected_type])
      }
      
      if group
        # Get ALL Pokémon of selected type within BST range
        valid_species = GameData::Species.keys.select { |s| 
          species_data = GameData::Species.get(s)
          # Check if the Pokémon has the selected type as one of its types
          has_type = species_data.types.include?(selected_type)
          # Check BST range
          bst = species_data.base_stats.values.sum
          bst_in_range = bst >= (group[1][:min_bst] || 0) && 
                        bst <= (group[1][:max_bst] || Float::INFINITY)
          
          has_type && bst_in_range
        }
        
        if !valid_species.empty?
          # Select a random species from the valid list
          species = valid_species.sample
          if species
            pkmn = Pokemon.new(species, level)
            # Double check the Pokémon has the correct type
            if pkmn.hasType?(selected_type)
              trainer.party.push(pkmn)
            end
          end
        else
          # Fallback to a basic Pokémon of that type if no valid species found
          basic_species = GameData::Species.keys.find { |s| 
            GameData::Species.get(s).types.include?(selected_type)
          }
          if basic_species
            trainer.party.push(Pokemon.new(basic_species, level))
          end
        end
      end
      
      # If somehow we still don't have a Pokémon, create a default one
      if trainer.party.empty?
        case selected_type
        when :NORMAL
          species = :RATTATA
        when :FIRE
          species = :CHARMANDER
        when :WATER
          species = :SQUIRTLE
        when :ELECTRIC
          species = :PIKACHU
        when :GRASS
          species = :BULBASAUR
        when :ICE
          species = :SPHEAL
        when :FIGHTING
          species = :MACHOP
        when :POISON
          species = :EKANS
        when :GROUND
          species = :SANDSHREW
        when :FLYING
          species = :PIDGEY
        when :PSYCHIC
          species = :ABRA
        when :BUG
          species = :CATERPIE
        when :ROCK
          species = :GEODUDE
        when :GHOST
          species = :GASTLY
        when :DRAGON
          species = :DRATINI
        when :DARK
          species = :POOCHYENA
        when :STEEL
          species = :MAGNEMITE
        when :FAIRY
          species = :CLEFAIRY
        else
          species = :EEVEE
        end
        trainer.party.push(Pokemon.new(species, level))
      end
      
      return trainer
    end

    def update_type_rank(selected_type)
      @type_ranks[selected_type] += 1
      if @type_ranks[selected_type] > 10
        @type_ranks[selected_type] = 10
      end
    end

    def pbStartTrainerBattle(trainer)
      # Create battle scene
      scene = Battle::Scene.new
      
      # Create battle with only the selected Pokémon
      battle = Battle.new(scene, [$player.party[0]], trainer.party, $player, trainer)
      battle.internalBattle = false
      
      decision = battle.pbStartBattle
      
      if decision == 1  # Won
        @streak += 1
        @total_wins += 1
        @total_record += 1
        # Add points using the plugin's system
        $game_battle_frontier.addBattlePoints(BattleFrontierPlugin::Settings::POINTS_PER_WIN)
        # Update rank
        update_rank
      else
        @lost = true
      end
      
      return decision == 1
    end

    def pbStartRound
      @current_round += 1
      @current_battle = 0
      @used_types.clear  # Clear used types at the start of each round
      return @current_round <= 3  # Maximum 3 rounds
    end

    def pbStartBattle
      @current_battle += 1
      return @current_battle <= HallSettings::BATTLES_PER_ROUND
    end

    def show_rank_info
      current_rank = HallSettings::RANKS[@rank]
      next_rank = HallSettings::RANKS[@rank + 1]
      
      pbMessage(_INTL("Current Rank: {1}", current_rank[:name]))
      if next_rank
        wins_needed = next_rank[:min_wins] - @total_wins
        pbMessage(_INTL("Next Rank: {1} ({2} more wins needed)", 
                      next_rank[:name], wins_needed))
      end
    end

    def update_rank
      # Check if player has enough wins for next rank
      next_rank = HallSettings::RANKS[@rank + 1]
      if next_rank && @total_wins >= next_rank[:min_wins]
        @rank += 1
        pbMessage(_INTL("Congratulations! You've reached {1} rank!", 
                      HallSettings::RANKS[@rank][:name]))
      end
    end
  end

  #--------------------------------------------------------------------------
  # * Hall Scene
  #--------------------------------------------------------------------------
  class HallScene
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

  class HallScreen
    def initialize(scene)
      @scene = scene
      @streak = 0
      @current_round = 1
      @current_battle = 1
      @challenge = BattleFrontierPlugin::HallChallenge.new
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
            
            # Show rank info
            @challenge.show_rank_info
            
            # Select type and create trainer
            selected_type = @challenge.select_type
            if selected_type
              trainer = @challenge.create_trainer(selected_type)
              if !@challenge.pbStartTrainerBattle(trainer)
                @challenge.update_type_rank(selected_type)
                break
              end
            else
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
        
        # Check for Hall Matron battle
        if @challenge.current_battle == HallSettings::BATTLES_PER_ROUND && !@challenge.lost?
          pbMessage(_INTL("You've reached the final battle!"))
          pbMessage(_INTL("Argenta, the Hall Matron, appears!"))
          
          # Create Argenta battle
          brain = BattleFrontierPlugin.createBrainTeam(:HALL, @streak)
          if brain
            scene = Battle::Scene.new
            battle = Battle.new(scene, [$player.party[0]], brain.party, $player, brain)
            battle.internalBattle = false
            decision = battle.pbStartBattle
            if decision == 1
              pbMessage(_INTL("Congratulations! You've defeated Argenta!"))
              $game_battle_frontier.addBattlePoints(20)  # Bonus BP for defeating Hall Matron
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
end

#===============================================================================
# Battle Hall Scene and Screen
#===============================================================================
class BattleHallScene
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

#===============================================================================
# Battle Hall Entry Point
#===============================================================================
def start
  scene = BattleFrontierPlugin::HallScene.new
  screen = BattleFrontierPlugin::HallScreen.new(scene)
  pbFadeOutIn {
    screen.pbStart
  }
end 