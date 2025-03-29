#===============================================================================
# Battle Castle System
#===============================================================================
module BattleFrontierPlugin
  module CastleSettings
    # Number of battles per round
    BATTLES_PER_ROUND = 7
    
    # Map ID for the Castle
    CASTLE_MAP_ID = 53
    
    # Advantages and their costs
    ADVANTAGES = {
      # Level 1 Advantages
      :EXAMINE => { name: "Examine", cost: 1, rank: 1 },
      :LEVEL_UP => { name: "+5 Level", cost: 1, rank: 1 },
      :LEVEL_DOWN => { name: "-5 Level", cost: 15, rank: 1 },
      :STRENGTH => { name: "Strength/Stats", cost: 2, rank: 1 },
      :HP_RECOVERY => { name: "HP Recovery", cost: 10, rank: 1 },
      :PASS => { name: "Pass", cost: 50, rank: 1 },
      
      # Level 2 Advantages
      :MOVE => { name: "Move", cost: 5, rank: 2 },
      :PP_RECOVERY => { name: "PP Recovery", cost: 8, rank: 2 },
      
      # Berries (Level 1)
      :CHERI_BERRY => { name: "Cheri Berry", cost: 2, rank: 1 },
      :CHESTO_BERRY => { name: "Chesto Berry", cost: 2, rank: 1 },
      :PECHA_BERRY => { name: "Pecha Berry", cost: 2, rank: 1 },
      :RAWST_BERRY => { name: "Rawst Berry", cost: 2, rank: 1 },
      :ASPEAR_BERRY => { name: "Aspear Berry", cost: 2, rank: 1 },
      :PERSIM_BERRY => { name: "Persim Berry", cost: 2, rank: 1 },
      :LUM_BERRY => { name: "Lum Berry", cost: 5, rank: 1 },
      :SITRUS_BERRY => { name: "Sitrus Berry", cost: 5, rank: 1 },
      
      # Level 2 Items
      :KINGS_ROCK => { name: "King's Rock", cost: 10, rank: 2 },
      :QUICK_CLAW => { name: "Quick Claw", cost: 15, rank: 2 },
      :POWER_HERB => { name: "Power Herb", cost: 5, rank: 2 },
      :SHELL_BELL => { name: "Shell Bell", cost: 15, rank: 2 },
      :METRONOME => { name: "Metronome", cost: 10, rank: 2 },
      :LIGHT_CLAY => { name: "Light Clay", cost: 10, rank: 2 },
      :GRIP_CLAW => { name: "Grip Claw", cost: 10, rank: 2 },
      :BIG_ROOT => { name: "Big Root", cost: 10, rank: 2 },
      :TOXIC_ORB => { name: "Toxic Orb", cost: 10, rank: 2 },
      :FLAME_ORB => { name: "Flame Orb", cost: 10, rank: 2 },
      :LIGHT_BALL => { name: "Light Ball", cost: 15, rank: 2 },
      :THICK_CLUB => { name: "Thick Club", cost: 15, rank: 2 },
      
      # Level 3 Items
      :WHITE_HERB => { name: "White Herb", cost: 5, rank: 3 },
      :FOCUS_BAND => { name: "Focus Band", cost: 15, rank: 3 },
      :FOCUS_SASH => { name: "Focus Sash", cost: 10, rank: 3 },
      :LEFTOVERS => { name: "Leftovers", cost: 20, rank: 3 },
      :BRIGHTPOWDER => { name: "BrightPowder", cost: 20, rank: 3 },
      :SCOPE_LENS => { name: "Scope Lens", cost: 20, rank: 3 },
      :WIDE_LENS => { name: "Wide Lens", cost: 20, rank: 3 },
      :ZOOM_LENS => { name: "Zoom Lens", cost: 20, rank: 3 },
      :CHOICE_BAND => { name: "Choice Band", cost: 20, rank: 3 },
      :CHOICE_SPECS => { name: "Choice Specs", cost: 20, rank: 3 },
      :CHOICE_SCARF => { name: "Choice Scarf", cost: 20, rank: 3 },
      :MUSCLE_BAND => { name: "Muscle Band", cost: 20, rank: 3 },
      :WISE_GLASSES => { name: "Wise Glasses", cost: 20, rank: 3 },
      :EXPERT_BELT => { name: "Expert Belt", cost: 20, rank: 3 },
      :LIFE_ORB => { name: "Life Orb", cost: 20, rank: 3 }
    }
    
    # Ranking up costs
    RANK_UP_COSTS = {
      :RECOVERY => {
        2 => 100,  # Level 1 to 2
        3 => 100   # Level 2 to 3
      },
      :ITEM => {
        2 => 100,  # Level 1 to 2
        3 => 150   # Level 2 to 3
      },
      :INFO => {
        2 => 50    # Level 1 to 2
      }
    }
  end

  #--------------------------------------------------------------------------
  # * Castle Challenge
  #--------------------------------------------------------------------------
  class CastleChallenge
    attr_reader :current_battle
    attr_reader :current_round
    attr_reader :streak
    attr_reader :quit
    attr_reader :lost
    attr_reader :points
    attr_reader :ranks
    
    def initialize
      @current_battle = 0
      @current_round = 0
      @streak = 0
      @quit = false
      @lost = false
      @points = 0  # Castle Points
      @ranks = {
        :RECOVERY => 1,
        :ITEM => 1,
        :INFO => 1
      }
      @items = {}  # Store purchased items
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
      pbMessage(_INTL("Welcome to the Battle Castle!"))
      pbMessage(_INTL("Before each battle, you can purchase advantages to help you!"))
      pbMessage(_INTL("Each advantage costs Castle Points (CP) to buy."))
      pbMessage(_INTL("Win 7 battles to face Darach, the Castle Valet!"))
      
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
        _INTL("Castle Trainer"),
        :COOLTRAINER_F
      )
      trainer.id = $player.make_foreign_ID
      trainer.party = []
      
      # Add 3 random Pokémon at appropriate level
      round_bonus = (@current_round - 1) * 2  # +2 levels per round
      max_level = [@level_adjustment + round_bonus, 100].min  # Cap at level 100
      
      3.times do
        species = GameData::Species.keys.sample
        trainer.party.push(Pokemon.new(species, max_level))
      end
      
      return trainer
    end

    def show_advantages
      # Create menu options
      commands = []
      
      # Add advantages based on current ranks
      CastleSettings::ADVANTAGES.each do |advantage, data|
        if data[:rank] <= @ranks[:ITEM]  # Check if player's rank is high enough
          commands.push(_INTL("{1} ({2} CP)", data[:name], data[:cost]))
        end
      end
      
      # Add rank up options
      commands.push(_INTL("Rank Up Recovery (100 CP)")) if @ranks[:RECOVERY] < 3
      commands.push(_INTL("Rank Up Items (100 CP)")) if @ranks[:ITEM] < 3
      commands.push(_INTL("Rank Up Info (50 CP)")) if @ranks[:INFO] < 2
      
      commands.push(_INTL("Start Battle"))
      commands.push(_INTL("Quit"))
      
      # Show menu and get selection
      cmd = pbMessage(_INTL("Choose an advantage (You have {1} CP):", @points),
                     commands, -1)
      
      if cmd < CastleSettings::ADVANTAGES.length
        # Get selected advantage
        advantage = CastleSettings::ADVANTAGES.keys[cmd]
        data = CastleSettings::ADVANTAGES[advantage]
        
        # Check if player can afford it
        if @points >= data[:cost]
          @points -= data[:cost]
          pbMessage(_INTL("You bought {1} for {2} CP!", data[:name], data[:cost]))
          @items[advantage] = true
          return true
        else
          pbMessage(_INTL("You don't have enough CP!"))
          return false
        end
      elsif cmd < CastleSettings::ADVANTAGES.length + 3  # Rank up options
        rank_up_index = cmd - CastleSettings::ADVANTAGES.length
        case rank_up_index
        when 0  # Recovery
          if @points >= 100 && @ranks[:RECOVERY] < 3
            @points -= 100
            @ranks[:RECOVERY] += 1
            pbMessage(_INTL("Recovery rank increased to {1}!", @ranks[:RECOVERY]))
            return true
          end
        when 1  # Items
          if @points >= 100 && @ranks[:ITEM] < 3
            @points -= 100
            @ranks[:ITEM] += 1
            pbMessage(_INTL("Items rank increased to {1}!", @ranks[:ITEM]))
            return true
          end
        when 2  # Info
          if @points >= 50 && @ranks[:INFO] < 2
            @points -= 50
            @ranks[:INFO] += 1
            pbMessage(_INTL("Info rank increased to {1}!", @ranks[:INFO]))
            return true
          end
        end
        pbMessage(_INTL("You don't have enough CP!"))
        return false
      elsif cmd == CastleSettings::ADVANTAGES.length + 3
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
    end

    def use_advantages
      @items.each do |advantage, _|
        data = CastleSettings::ADVANTAGES[advantage]
        apply_advantage(data[:effect])
      end
      @items = {}  # Clear used advantages
    end

    def apply_advantage(advantage)
      case advantage
      when :EXAMINE
        # Show opponent's Pokémon info
        pbMessage(_INTL("Opponent's Pokémon:"))
        $game_temp.battle_party.each do |pkmn|
          pbMessage(_INTL("{1} (Level {2})", pkmn.name, pkmn.level))
        end
      when :LEVEL_UP
        # Increase opponent's Pokémon levels by 5
        $game_temp.battle_party.each do |pkmn|
          pkmn.level = [pkmn.level + 5, 100].min
        end
      when :LEVEL_DOWN
        # Decrease opponent's Pokémon levels by 5
        $game_temp.battle_party.each do |pkmn|
          pkmn.level = [pkmn.level - 5, 1].max
        end
      when :STRENGTH
        # Show opponent's Pokémon stats
        pbMessage(_INTL("Opponent's Pokémon Stats:"))
        $game_temp.battle_party.each do |pkmn|
          pbMessage(_INTL("{1}: HP {2}, Atk {3}, Def {4}, Spd {5}, Sp.Atk {6}, Sp.Def {7}",
                        pkmn.name, pkmn.hp, pkmn.attack, pkmn.defense,
                        pkmn.speed, pkmn.spatk, pkmn.spdef))
        end
      when :MOVE
        # Show opponent's Pokémon moves
        pbMessage(_INTL("Opponent's Pokémon Moves:"))
        $game_temp.battle_party.each do |pkmn|
          pbMessage(_INTL("{1}:", pkmn.name))
          pkmn.moves.each do |move|
            pbMessage(_INTL("- {1}", move.name))
          end
        end
      when :HP_RECOVERY
        # Heal HP based on rank
        case @ranks[:RECOVERY]
        when 1
          $player.party.each { |pkmn| pkmn.hp = pkmn.totalhp }
        when 2
          $player.party.each do |pkmn|
            pkmn.moves.each do |move|
              move.pp = move.total_pp
            end
          end
        when 3
          $player.party.each do |pkmn|
            pkmn.hp = pkmn.totalhp
            pkmn.moves.each do |move|
              move.pp = move.total_pp
            end
          end
        end
      end
    end

    def calculate_battle_points
      points = 0
      
      # Number of Pokémon that have not fainted
      points += $player.party.count { |p| !p.fainted? } * 3
      
      # Number of Pokémon with full HP
      points += $player.party.count { |p| p.hp == p.totalhp } * 3
      
      # Number of Pokémon with at least half but not full HP
      points += $player.party.count { |p| p.hp >= p.totalhp / 2 && p.hp < p.totalhp } * 2
      
      # Number of Pokémon with less than half HP
      points += $player.party.count { |p| p.hp < p.totalhp / 2 } * 1
      
      # Number of Pokémon with no status ailments
      points += $player.party.count { |p| p.status == :NONE } * 1
      
      # PP usage bonus
      total_pp_used = $player.party.sum { |p| p.moves.sum { |m| m.total_pp - m.pp } }
      case total_pp_used
      when 0..5
        points += 8
      when 6..10
        points += 6
      when 11..15
        points += 4
      end
      
      # Opponent's Pokémon level bonus
      points += $game_temp.battle_party.count { |p| p.level >= @level_adjustment + 5 } * 7
      
      return [points, 50].min  # Cap at 50 points
    end

    def pbStartTrainerBattle(trainer)
      # Use purchased advantages
      use_advantages
      
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
        # Add Castle Points
        battle_points = calculate_battle_points
        @points += battle_points
        pbMessage(_INTL("You earned {1} Castle Points!", battle_points))
      else
        @lost = true
      end
      
      return decision == 1
    end

    def pbStartRound
      @current_round += 1
      @current_battle = 0
      @points = 10  # Start each round with 10 CP
      return @current_round <= 3  # Maximum 3 rounds
    end

    def pbStartBattle
      @current_battle += 1
      return @current_battle <= CastleSettings::BATTLES_PER_ROUND
    end
  end

  #--------------------------------------------------------------------------
  # * Castle Scene
  #--------------------------------------------------------------------------
  class CastleScene
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

  #--------------------------------------------------------------------------
  # * Castle Screen
  #--------------------------------------------------------------------------
  class CastleScreen
    def initialize(scene)
      @scene = scene
      @streak = 0
      @current_round = 1
      @current_battle = 1
      @challenge = CastleChallenge.new
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
            
            # Show advantages and get selection
            if !@challenge.show_advantages
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
        
        # Check if player reached Darach
        if @challenge.current_battle == CastleSettings::BATTLES_PER_ROUND && !@challenge.lost?
          pbMessage(_INTL("You've reached the final battle!"))
          pbMessage(_INTL("Darach, the Castle Valet, appears!"))
          
          # Create Darach battle
          brain = BattleFrontierPlugin.createBrainTeam(:CASTLE, @streak)
          if brain
            scene = Battle::Scene.new
            battle = Battle.new(scene, $player.party, brain.party, $player, brain)
            battle.internalBattle = false
            decision = battle.pbStartBattle
            if decision == 1
              pbMessage(_INTL("Congratulations! You've defeated Darach!"))
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

  #--------------------------------------------------------------------------
  # * Start Battle Castle
  #--------------------------------------------------------------------------
  def self.start_battle_castle
    scene = CastleScene.new
    screen = CastleScreen.new(scene)
    pbFadeOutIn {
      screen.pbStart
    }
  end
end 