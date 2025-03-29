#===============================================================================
# Battle Rules for Battle Frontier
#===============================================================================

#===============================================================================
# Battle Dome Rules
#===============================================================================
def pbBattleDomeRules(double, openlevel)
  ret = PokemonChallengeRules.new
  if openlevel
    ret.setLevelAdjustment(OpenLevelAdjustment.new(60))
  else
    ret.setLevelAdjustment(CappedLevelAdjustment.new(50))
  end
  ret.addPokemonRule(StandardRestriction.new)
  ret.addTeamRule(SpeciesClause.new)
  ret.addTeamRule(ItemClause.new)
  ret.addBattleRule(SoulDewBattleClause.new)
  ret.addBattleRule(PerishSongClause.new)
  ret.setDoubleBattle(double)
  ret.setBattleType(BattleDome.new)
  return ret
end

#===============================================================================
# Battle Pike Rules
#===============================================================================
def pbBattlePikeRules(double, openlevel)
  ret = PokemonChallengeRules.new
  if openlevel
    ret.setLevelAdjustment(OpenLevelAdjustment.new(60))
  else
    ret.setLevelAdjustment(CappedLevelAdjustment.new(50))
  end
  ret.addPokemonRule(StandardRestriction.new)
  ret.addTeamRule(SpeciesClause.new)
  ret.addTeamRule(ItemClause.new)
  ret.addBattleRule(SoulDewBattleClause.new)
  ret.addBattleRule(SleepClause.new)
  ret.addBattleRule(FreezeClause.new)
  ret.setDoubleBattle(double)
  ret.setBattleType(BattlePike.new)
  return ret
end

#===============================================================================
# Battle Pyramid Rules
#===============================================================================
def pbBattlePyramidRules(double, openlevel)
  ret = PokemonChallengeRules.new
  if openlevel
    ret.setLevelAdjustment(OpenLevelAdjustment.new(60))
  else
    ret.setLevelAdjustment(CappedLevelAdjustment.new(50))
  end
  ret.addPokemonRule(StandardRestriction.new)
  ret.addTeamRule(SpeciesClause.new)
  ret.addTeamRule(ItemClause.new)
  ret.addBattleRule(SoulDewBattleClause.new)
  ret.addBattleRule(SleepClause.new)
  ret.addBattleRule(FreezeClause.new)
  ret.addBattleRule(SelfdestructClause.new)
  ret.setDoubleBattle(double)
  ret.setBattleType(BattlePyramid.new)
  return ret
end 