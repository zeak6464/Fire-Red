#===============================================================================
# Battle Types for Battle Frontier
#===============================================================================

#===============================================================================
# Battle Dome
#===============================================================================
class BattleDome < BattleType
  def pbCreateBattle(scene, trainer1, trainer2)
    return PokeBattle_RecordedBattle.new(scene, trainer1.party, trainer2.party, trainer1, trainer2)
  end
end

#===============================================================================
# Battle Pike
#===============================================================================
class BattlePike < BattleType
  def pbCreateBattle(scene, trainer1, trainer2)
    return PokeBattle_RecordedBattle.new(scene, trainer1.party, trainer2.party, trainer1, trainer2)
  end
end

#===============================================================================
# Battle Pyramid
#===============================================================================
class BattlePyramid < BattleType
  def pbCreateBattle(scene, trainer1, trainer2)
    return PokeBattle_RecordedBattle.new(scene, trainer1.party, trainer2.party, trainer1, trainer2)
  end
end 