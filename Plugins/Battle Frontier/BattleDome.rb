#===============================================================================
# Battle Dome Tournament System
#===============================================================================

#===============================================================================
# Battle Dome Scene
#===============================================================================
class BattleDomeScene
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

  def pbShowBracket(bracket)
    # TODO: Show tournament bracket visualization
    pbMessage(_INTL("Tournament Bracket"))
    bracket.getCurrentMatches.each do |match|
      pbMessage(_INTL("{1} VS {2}", match[0].name, match[1].name))
    end
  end
end

#===============================================================================
# Battle Dome Screen
#===============================================================================
class BattleDomeScreen
  def initialize(scene)
    @scene = scene
    @challenge = BattleFrontierPlugin::DomeChallenge.new
    @oldParty = nil
  end

  def pbStart
    # Save the current party
    @oldParty = $player.party.clone
    
    # Start the scene
    @scene.pbStart
    
    # Start the challenge
    if @challenge.start
      # Show initial bracket
      @scene.pbShowBracket(@challenge.bracket)
      
      # Continue until tournament is complete
      until @challenge.isComplete?
        # Start the next match
        winner = @challenge.pbStartMatch
        break if !winner
        
        # Show updated bracket
        @scene.pbShowBracket(@challenge.bracket)
      end
      
      # Get tournament winner
      @challenge.getWinner
    end
    
    # End the scene
    @scene.pbEnd
    
    # Restore the original party
    $player.party = @oldParty
  end
end

module BattleFrontierPlugin
  #--------------------------------------------------------------------------
  # * Battle Dome Settings
  #--------------------------------------------------------------------------
  module DomeSettings
    TOURNAMENT_SIZE = 16
    ROUNDS = 4  # 16 -> 8 -> 4 -> 2 -> 1
    
    # Trainer Names
    MALE_NAMES = [
      "Alex", "Brandon", "Cameron", "Daniel", "Ethan",
      "Felix", "Gregory", "Henry", "Isaac", "James",
      "Keith", "Lucas", "Marcus", "Nathan", "Owen",
      "Paul", "Quinn", "Ryan", "Scott", "Tyler"
    ]
    
    FEMALE_NAMES = [
      "Alice", "Beth", "Claire", "Diana", "Emma",
      "Fiona", "Grace", "Hannah", "Iris", "Julia",
      "Karen", "Lisa", "Maria", "Nina", "Olivia",
      "Penny", "Quinn", "Rachel", "Sarah", "Tara"
    ]

    def self.createTuckerTeam(streak)
      case streak
      when 5
        return [
          [:SALAMENCE, 50],
          [:SWAMPERT, 50],
          [:SCIZOR, 50]
        ]
      when 10
        return [
          [:SALAMENCE, 50],
          [:SWAMPERT, 50],
          [:SCIZOR, 50]
        ]
      else
        return []
      end
    end
  end

  #--------------------------------------------------------------------------
  # * Tournament Bracket
  #--------------------------------------------------------------------------
  class TournamentBracket
    attr_reader :rounds
    attr_reader :currentRound
    attr_reader :winners
    attr_accessor :level_adjustment

    def initialize(level_adjustment = 50)
      @rounds = []
      @currentRound = 0
      @winners = []
      @trainers = []
      @level_adjustment = level_adjustment
      generateBracket
    end

    def generateBracket
      # Generate 16 random trainers
      trainers = generateTrainers(DomeSettings::TOURNAMENT_SIZE)
      
      # Create first round matches
      firstRound = []
      (0...trainers.length).step(2) do |i|
        firstRound.push([trainers[i], trainers[i+1]])
      end
      @rounds.push(firstRound)
    end

    def generateTrainers(count)
      trainers = []
      count.times do
        trainer = generateTrainer
        trainers.push(trainer)
      end
      return trainers
    end

    def generateTrainer
      # Randomly choose between male and female Cooltrainer
      is_male = rand(2) == 0
      trainer_type = is_male ? "COOLTRAINER_M" : "COOLTRAINER_F"
      trainer_name = if is_male
        DomeSettings::MALE_NAMES.sample
      else
        DomeSettings::FEMALE_NAMES.sample
      end
      
      trainer = NPCTrainer.new(trainer_name, trainer_type.to_sym)
      trainer.id = $player.make_foreign_ID
      
      # Generate 3 random Pokemon for the trainer at appropriate level
      3.times do
        species = GameData::Species.keys.sample
        pokemon = Pokemon.new(species, @level_adjustment)
        trainer.party.push(pokemon)
      end
      return trainer
    end

    def nextRound
      return false if @currentRound >= DomeSettings::ROUNDS
      
      currentWinners = []
      getCurrentMatches.each do |match|
        winner = simulateMatch(match[0], match[1])
        currentWinners.push(winner)
      end
      
      @winners.push(currentWinners)
      @currentRound += 1
      
      if @currentRound < DomeSettings::ROUNDS
        nextRoundMatches = []
        (0...currentWinners.length).step(2) do |i|
          nextRoundMatches.push([currentWinners[i], currentWinners[i+1]])
        end
        @rounds.push(nextRoundMatches)
      end
      
      return true
    end

    def simulateMatch(trainer1, trainer2)
      # For now, randomly choose a winner
      # In a real implementation, this would be an actual battle
      return rand(2) == 0 ? trainer1 : trainer2
    end

    def getCurrentMatches
      return @rounds[@currentRound] if @currentRound < @rounds.length
      return []
    end

    def isFinalRound?
      return @currentRound == DomeSettings::ROUNDS
    end
  end

  #--------------------------------------------------------------------------
  # * Battle Dome Challenge
  #--------------------------------------------------------------------------
  class DomeChallenge
    attr_reader :bracket
    
    def initialize
      @level_adjustment = 50  # Default to Level 50
      @bracket = nil
      @currentMatch = 0  # Track current match in the round
      @wins = 0
      @current_location = nil
      # Initialize Battle Frontier if not already done
      $game_battle_frontier = BattleFrontierPlugin::BattleFrontier.new if !$game_battle_frontier
    end

    def start
      # Store current location before starting
      @current_location = [$game_map.map_id, $game_player.x, $game_player.y]
      
      pbMessage(_INTL("Welcome to the Battle Dome Tournament!"))
      pbMessage(_INTL("16 trainers will compete in a tournament."))
      pbMessage(_INTL("Win 4 rounds to face Tucker, the Dome Ace!"))
      
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
      
      # Create tournament bracket with chosen level
      @bracket = TournamentBracket.new(@level_adjustment)
      
      # Replace one of the random trainers with the player in the first round matches
      first_round = @bracket.rounds[0]
      match_index = rand(first_round.length)
      trainer_index = rand(2)
      first_round[match_index][trainer_index] = $player
      
      return true
    end

    def pbStartMatch
      matches = @bracket.getCurrentMatches
      return false if matches.empty?
      
      # Get current match
      match = matches[@currentMatch]
      return false if !match
      
      trainer1 = match[0]
      trainer2 = match[1]
      
      # Show round info
      pbMessage(_INTL("Round {1}", @bracket.currentRound + 1))
      pbMessage(_INTL("Match {1}", @currentMatch + 1))
      
      # If player is in this match
      if trainer1 == $player || trainer2 == $player
        opponent = trainer1 == $player ? trainer2 : trainer1
        
        # Show opponent info
        pbShowOpponentInfo(opponent)
        
        # Create battle scene
        scene = Battle::Scene.new
        
        # Create battle
        battle = Battle.new(scene, $player.party, opponent.party, $player, opponent)
        battle.internalBattle = false
        
        # Start battle
        decision = battle.pbStartBattle
        
        if decision == 1  # Won
          recordWin($player)
          pbMessage(_INTL("You won the match!"))
          # Add BP using the plugin's system
          $game_battle_frontier.addBattlePoints(BattleFrontierPlugin::Settings::POINTS_PER_WIN)
          winner = $player
        else
          pbMessage(_INTL("You lost the match..."))
          winner = opponent
        end
        
        # Heal player's Pokémon after battle
        $player.party.each { |pkmn| pkmn.heal }
      else
        # Simulate NPC vs NPC battle
        winner = @bracket.simulateMatch(trainer1, trainer2)
        pbMessage(_INTL("{1} won the match!", winner.name))
      end
      
      # Move to next match
      @currentMatch += 1
      
      # If all matches in current round are complete, move to next round
      if @currentMatch >= matches.length
        @currentMatch = 0
        @bracket.nextRound
      end
      
      return winner
    end

    def isComplete?
      return false if !@bracket
      @bracket.isFinalRound? && @currentMatch >= @bracket.getCurrentMatches.length
    end

    def getWinner
      return nil if !@bracket
      winner = @bracket.winners.last[0] if @bracket.winners.length > 0
      
      # If player won the tournament, face Tucker
      if winner == $player
        pbMessage(_INTL("Congratulations! You've won the tournament!"))
        pbMessage(_INTL("Tucker, the Dome Ace, wishes to battle you!"))
        
        # Create Tucker battle
        brain = BattleFrontierPlugin.createBrainTeam(:DOME, @wins)
        if brain
          scene = Battle::Scene.new
          battle = Battle.new(scene, $player.party, brain.party, $player, brain)
          decision = battle.pbStartBattle
          if decision == 1
            pbMessage(_INTL("Congratulations! You've defeated Tucker!"))
            # Add BP using the plugin's system
            $game_battle_frontier.addBattlePoints(10)  # Bonus BP for defeating Brain
          end
        end
      end
      
      return winner
    end

    def pbShowOpponentInfo(trainer)
      pbMessage(_INTL("Opponent: {1}", trainer.name))
      pbMessage(_INTL("Pokémon:"))
      trainer.party.each do |pkmn|
        pbMessage(_INTL("- {1} (Lv.{2})", pkmn.name, pkmn.level))
      end
      pbMessage(_INTL("Battle Style: {1}", get_battle_style(trainer)))
      pbMessage(_INTL("Training Focus: {1}", get_training_focus(trainer)))
    end

    def get_battle_style(trainer)
      styles = [
        "Offensive",
        "Defensive",
        "Balanced",
        "Speed-based",
        "Tactical"
      ]
      return styles.sample
    end

    def get_training_focus(trainer)
      focuses = [
        "Attack",
        "Defense",
        "Speed",
        "Special Attack",
        "Special Defense",
        "HP",
        "Mixed"
      ]
      return focuses.sample
    end

    def pbChoosePokemon(trainer)
      commands = []
      trainer.party.each do |pkmn|
        commands << pkmn.name
      end
      
      pbMessage(_INTL("Choose two Pokémon for battle:"))
      chosen = []
      2.times do
        command = pbShowCommands(nil, commands, -1)
        next if command < 0
        chosen << trainer.party[command]
        commands.delete_at(command)
      end
      
      return chosen
    end

    def simulateMatch(trainer1, trainer2)
      # If player is involved, they should win
      return $player if trainer1 == $player || trainer2 == $player
      # Otherwise simulate normally
      @bracket.simulateMatch(trainer1, trainer2)
    end

    def recordWin(trainer)
      @wins += 1 if trainer == $player
    end
  end

  #--------------------------------------------------------------------------
  # * Battle Dome Leader (Tucker)
  #--------------------------------------------------------------------------
  def self.createTuckerTeam(streak)
    team = DomeSettings.createTuckerTeam(streak)
    return nil if team.empty?
    
    trainer = NPCTrainer.new("TUCKER", :POKEMONTRAINER_Male)
    team.each do |species, level|
      trainer.party.push(Pokemon.new(species, level))
    end
    return trainer
  end

  def self.createBrainTeam(streak)
    trainer = NPCTrainer.new("TUCKER", :FRONTIER_BRAIN)
    team = DomeSettings.createTuckerTeam(streak)
    return nil if team.empty?
    
    team.each do |species, level|
      trainer.party.push(Pokemon.new(species, level))
    end
    return trainer
  end
end 