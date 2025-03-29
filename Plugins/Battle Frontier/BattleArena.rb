#===============================================================================
# Battle Arena Scene and Screen
#===============================================================================
class BattleArenaScene
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

  def pbShowJudgment(mind, skill, body)
    pbMessage(_INTL("Mind Points: {1}", mind))
    pbMessage(_INTL("Skill Points: {1}", skill))
    pbMessage(_INTL("Body Points: {1}", body))
  end
end

class BattleArenaScreen
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
    pbMessage(_INTL("Welcome to the Battle Arena!"))
    pbMessage(_INTL("Here, battles are decided by judging after 3 turns!"))
    pbMessage(_INTL("You'll be judged on Mind, Skill, and Body!"))
    pbMessage(_INTL("Win 27 battles to face Greta, the Arena Tycoon!"))
    
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
        _INTL("BLACKBELT"),
        :BLACKBELT
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
      
      # Sequential one-on-one battles
      wins = 0
      3.times do |j|
        # Skip third round if already won 2 rounds
        if j == 2 && wins >= 2
          pbMessage(_INTL("You've already won 2 rounds! Round 3 is skipped!"))
          break
        end
        
        pbMessage(_INTL("Round {1} of 3!", j + 1))
        
        # Create single Pokémon parties for this round
        player_party = [$player.party[j]]
        opponent_party = [trainer.party[j]]
        
        # Create battle scene
        scene = Battle::Scene.new
        
        # Create battle with Arena rules
        battle = BattleArenaBattle.new(scene, player_party, opponent_party, $player, trainer)
        battle.internalBattle = false
        battle.rules["arenabattle"] = true  # Special rule for 3-turn battles
        battle.rules["turncount"] = 3       # Battles are judged after 3 turns
        battle.rules["maxTurns"] = 3        # Force battle to end after 3 turns
        battle.rules["noSwitch"] = true     # No switching allowed
        battle.rules["noBag"] = true        # No items allowed
        
        # Start battle
        decision = battle.pbStartBattle
        
        # Force end battle after 3 turns
        if battle.turnCount >= 3
          battle.pbAbort
          decision = 0  # Reset to draw for judgment
          
          # Calculate ratings (2 points for winning category, 1 for tie)
          ratings1 = [0, 0, 0]  # Player ratings
          ratings2 = [0, 0, 0]  # Opponent ratings
          
          # Mind rating - Based on offensive moves used
          mind1 = 0
          mind2 = 0
          player_party[0].moves.each do |move|
            if move.damagingMove?
              mind1 += 1
            elsif move.function_code == "ProtectUser" || move.function_code == "UserEnduresFaintingThisTurn"
              mind1 -= 1
            end
          end
          opponent_party[0].moves.each do |move|
            if move.damagingMove?
              mind2 += 1
            elsif move.function_code == "ProtectUser" || move.function_code == "UserEnduresFaintingThisTurn"
              mind2 -= 1
            end
          end
          
          if mind1 == mind2
            ratings1[0] = 1
            ratings2[0] = 1
          elsif mind1 > mind2
            ratings1[0] = 2
          else
            ratings2[0] = 2
          end
          
          # Skill rating - Based on damage dealt
          skill1 = player_party[0].effects[PBEffects::DamageDealt] || 0
          skill2 = opponent_party[0].effects[PBEffects::DamageDealt] || 0
          
          if skill1 == skill2
            ratings1[1] = 1
            ratings2[1] = 1
          elsif skill1 > skill2
            ratings1[1] = 2
          else
            ratings2[1] = 2
          end
          
          # Body rating - Based on remaining HP percentage
          body1 = player_party[0].hp * 100 / player_party[0].totalhp
          body2 = opponent_party[0].hp * 100 / opponent_party[0].totalhp
          if body1 == body2
            ratings1[2] = 1
            ratings2[2] = 1
          elsif body1 > body2
            ratings1[2] = 2
          else
            ratings2[2] = 2
          end
          
          # Show judgment
          pbMessage(_INTL("Time for judgment!"))
          pbMessage(_INTL("Your Pokémon:"))
          @scene.pbShowJudgment(ratings1[0], ratings1[1], ratings1[2])
          pbMessage(_INTL("Opponent's Pokémon:"))
          @scene.pbShowJudgment(ratings2[0], ratings2[1], ratings2[2])
          
          # Calculate total points
          your_total = ratings1.sum
          opp_total = ratings2.sum
          
          # Determine winner
          if your_total > opp_total
            decision = 1  # Player wins
            pbMessage(_INTL("You win the judgment!"))
          elsif your_total < opp_total
            decision = 2  # Opponent wins
            pbMessage(_INTL("You lose the judgment..."))
          else
            decision = 0  # Draw
            pbMessage(_INTL("It's a tie! Both Pokémon are eliminated!"))
          end
        end
        
        # Handle round result
        if decision == 1  # Won
          wins += 1
          pbMessage(_INTL("You won this round!"))
        elsif decision == 2  # Lost
          pbMessage(_INTL("You lost this round..."))
          next  # Continue to next round even if lost
        else  # Draw
          pbMessage(_INTL("This round is a draw!"))
          next  # Continue to next round even if drew
        end
        
        # Heal Pokémon between rounds
        player_party[0].heal
        opponent_party[0].heal
      end
      
      # Handle battle result
      if wins >= 2  # Won at least 2 rounds
        @streak += 1
        pbMessage(_INTL("Congratulations! You won the battle!"))
        # Add BP
        $PokemonGlobal.battlePoints += BattleFrontierPlugin::Settings::POINTS_PER_WIN
        
        # Check if we should face Greta
        if @streak == 27
          pbMessage(_INTL("Incredible! You've won 27 battles in a row!"))
          pbMessage(_INTL("Greta, the Arena Tycoon, wishes to battle you!"))
          # Create Greta battle
          brain = BattleFrontierPlugin.createBrainTeam(:ARENA, @streak)
          if brain
            scene = Battle::Scene.new
            battle = BattleArenaBattle.new(scene, $player.party, brain.party, $player, brain)
            battle.rules["arenabattle"] = true
            battle.rules["turncount"] = 3
            decision = battle.pbStartBattle
            if decision == 1
              pbMessage(_INTL("Congratulations! You've defeated Greta!"))
              $PokemonGlobal.battlePoints += 10  # Bonus BP for defeating Brain
            end
          end
        end
      else  # Lost or drew
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