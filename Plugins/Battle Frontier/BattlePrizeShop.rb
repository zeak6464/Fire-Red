#===============================================================================
# Battle Frontier Prize Shop
#===============================================================================

#===============================================================================
# Prize Item Data
#===============================================================================
class BattlePrizeItem
  attr_reader :id, :name, :cost, :description

  def initialize(id, name, cost, description)
    @id = id
    @name = name
    @cost = cost
    @description = description
  end
end

#===============================================================================
# Prize Shop
#===============================================================================
class BattlePrizeShop
  PRIZES = {
    # Berries
    :CHERIBERRY => BattlePrizeItem.new(:CHERIBERRY, "Cheri Berry", 2, "Cures paralysis."),
    :CHESTOBERRY => BattlePrizeItem.new(:CHESTOBERRY, "Chesto Berry", 2, "Cures sleep."),
    :PECHABERRY => BattlePrizeItem.new(:PECHABERRY, "Pecha Berry", 2, "Cures poison."),
    :RAWSTBERRY => BattlePrizeItem.new(:RAWSTBERRY, "Rawst Berry", 2, "Cures burn."),
    :ASPEARBERRY => BattlePrizeItem.new(:ASPEARBERRY, "Aspear Berry", 2, "Cures freeze."),
    :LEPPABERRY => BattlePrizeItem.new(:LEPPABERRY, "Leppa Berry", 2, "Restores 10 PP."),
    :ORANBERRY => BattlePrizeItem.new(:ORANBERRY, "Oran Berry", 2, "Restores 10 HP."),
    :PERSIMBERRY => BattlePrizeItem.new(:PERSIMBERRY, "Persim Berry", 2, "Cures confusion."),
    :LUMBERRY => BattlePrizeItem.new(:LUMBERRY, "Lum Berry", 4, "Cures any status condition."),
    :SITRUSBERRY => BattlePrizeItem.new(:SITRUSBERRY, "Sitrus Berry", 4, "Restores 30 HP."),
    
    # Battle Items
    :XATTACK => BattlePrizeItem.new(:XATTACK, "X Attack", 3, "Raises Attack."),
    :XDEFEND => BattlePrizeItem.new(:XDEFEND, "X Defend", 3, "Raises Defense."),
    :XSPATK => BattlePrizeItem.new(:XSPATK, "X Sp. Atk", 3, "Raises Sp. Atk."),
    :XSPDEF => BattlePrizeItem.new(:XSPDEF, "X Sp. Def", 3, "Raises Sp. Def."),
    :XSPEED => BattlePrizeItem.new(:XSPEED, "X Speed", 3, "Raises Speed."),
    :XACCURACY => BattlePrizeItem.new(:XACCURACY, "X Accuracy", 3, "Raises accuracy."),
    
    # Hold Items
    :FOCUSBAND => BattlePrizeItem.new(:FOCUSBAND, "Focus Band", 48, "May prevent fainting."),
    :FOCUSSASH => BattlePrizeItem.new(:FOCUSSASH, "Focus Sash", 48, "Prevents fainting from full HP."),
    :LEFTOVERS => BattlePrizeItem.new(:LEFTOVERS, "Leftovers", 48, "Restores HP gradually."),
    :SHELLBELL => BattlePrizeItem.new(:SHELLBELL, "Shell Bell", 48, "Restores HP when attacking."),
    
    # Special Items
    :ABILITYCAPSULE => BattlePrizeItem.new(:ABILITYCAPSULE, "Ability Capsule", 200, "Changes ability."),
    :BOTTLECAP => BattlePrizeItem.new(:BOTTLECAP, "Bottle Cap", 25, "Maximizes one IV."),
    :GOLDBOTTLECAP => BattlePrizeItem.new(:GOLDBOTTLECAP, "Gold Bottle Cap", 150, "Maximizes all IVs.")
  }

  def self.open_shop
    return if !$PokemonGlobal.battlePoints
    points = $PokemonGlobal.battlePoints.load_points
    loop do
      cmd = pbMessage("You have #{points} BP. What would you like to do?",
        ["Buy Items", "Exit"])
      break if cmd == 1
      pbShowPrizeList(points)
    end
  end

  def self.pbShowPrizeList(points)
    commands = []
    items = []
    PRIZES.each do |id, item|
      commands.push("#{item.name} (#{item.cost} BP)")
      items.push(id)
    end
    commands.push("Cancel")
    
    loop do
      cmd = pbMessage("Select an item to buy:", commands)
      break if cmd == commands.length - 1
      
      item = PRIZES[items[cmd]]
      if points >= item.cost
        if pbConfirmMessage("Buy #{item.name} for #{item.cost} BP?")
          $PokemonBag.pbStoreItem(item.id)
          $PokemonGlobal.battlePoints.spend_points(item.cost)
          points -= item.cost
          pbMessage("You bought #{item.name}!")
        end
      else
        pbMessage("You don't have enough BP!")
      end
    end
  end
end