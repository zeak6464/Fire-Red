# Battle Frontier Plugin

A comprehensive Battle Frontier system for Pokémon Essentials v21, featuring multiple battle facilities with unique mechanics.

## Facilities

### Battle Hall
- Single Pokémon battles (1v1)
- Choose one Pokémon (Level 30+) for your entire run
- Battle through different type specialists
- Each type has a rank system (1-10)
- Types are removed from selection after being battled in a round
- 10 battles per round
- Face Hall Matron Argenta at battle 50 and 170
- Opponent levels scale based on your Pokémon's level and type ranks
- Gain fans based on total record with different Pokémon

### Battle Arcade
- 3v3 battles
- Random events before each battle
- Point system for event selection
- 7 battles per round
- Face Arcade Star Dahlia at the end of round
- Events affect battle conditions

### Battle Castle
- Castle Points (CP) system
- Purchase items and advantages with CP
- Earn CP based on battle performance
- 7 battles per round
- Face Castle Valet Darach
- Ranking system for unlocking better advantages

### Battle Factory
- Rental Pokémon battles
- Swap Pokémon after wins
- 7 battles per round
- Face Factory Head Thorton
- Different Pokémon pools based on level rules

### Battle Hall
- Single Pokémon challenges
- Type-based opponents
- Rank up system per type
- 10 battles per round
- Face Hall Matron Argenta
- Fan system based on records

### Battle Tower
- Standard 3v3 battles
- Consecutive battle challenges
- 7 battles per round
- Face Tower Tycoon Palmer
- Classic battle facility

### Battle Arena
- 3v3 battles with special rules
- Mind, Skill, and Body judging system
- 7 battles per round
- Face Arena Captain Tucker
- Unique battle mechanics

### Battle Pike
- Random room challenges
- Heal or battle rooms
- 7 rooms per round
- Face Pike Queen Lucy
- Strategic room choice system

### Battle Pyramid
- Exploration-based facility
- Item management
- Dark rooms and traps
- Face Pyramid King Brandon
- Survival challenge mechanics

### Battle Palace
- Nature-based battle style
- Pokémon act independently
- 7 battles per round
- Face Palace Maven Spenser
- Unique battle mechanics

### Battle Dome
- Tournament-style battles
- 16 trainers compete
- Face Dome Ace Tucker
- Strategic opponent analysis

## Features
- Level 50 and Open Level rules
- Battle Points (BP) reward system
- Frontier Brain challenges
- Save and continue progress
- Unique mechanics per facility
- Comprehensive ranking systems
- Record tracking
- Special battle rules and conditions

## Prize Shop System
The Battle Frontier includes a comprehensive prize shop where trainers can spend their hard-earned Battle Points (BP). The shop features:

### Item Categories
- **Berries** (2-4 BP)
  - Status-curing berries (Cheri, Chesto, Pecha, etc.)
  - HP/PP restoring berries (Oran, Leppa, Sitrus)
  - Special berries (Lum, Persim)
  
- **Battle Items** (3 BP)
  - X Items (Attack, Defense, Sp. Atk, etc.)
  - Status items
  
- **Hold Items** (48 BP)
  - Focus Band/Sash
  - Leftovers
  - Shell Bell
  
- **Special Items** (25-200 BP)
  - Ability Capsule
  - Bottle Caps
  - Gold Bottle Caps

### Shop Features
- Real-time BP balance display
- Item descriptions
- Purchase confirmation
- Automatic inventory management
- Save system integration

## Installation
1. Place the Battle Frontier folder in your game's Plugins directory
2. Set up facility entrances and NPCs
3. Configure facility settings if needed
4. Add prize shop NPCs to your maps

## Usage

### Basic Usage
To open the prize shop in your game, use:
```ruby
BattlePrizeShop.open_shop
```

### Technical Usage

#### Battle Points System
```ruby
# Initialize Battle Points
$PokemonGlobal.battlePoints = BattlePoints.new

# Add points
$PokemonGlobal.battlePoints.add_points(amount)

# Spend points
$PokemonGlobal.battlePoints.spend_points(amount)

# Check current points
current_points = $PokemonGlobal.battlePoints.points
```

#### Symbol System
```ruby
# Initialize Symbols
$PokemonGlobal.frontierSymbols = FrontierSymbols.new

# Award a symbol
$PokemonGlobal.frontierSymbols.award_symbol(facility, :silver)  # or :gold

# Check for symbol
has_symbol = $PokemonGlobal.frontierSymbols.has_symbol?(facility, :silver)
```

#### Frontier Brain System
```ruby
# Check if current battle is a Frontier Brain battle
is_brain_battle = FrontierBrainSystem.is_brain_battle?(facility, battle_number)

# Get Frontier Brain data
brain = FrontierBrainSystem.get_brain(facility, battle_type)
```

#### Customizing Prize Shop
```ruby
# Add new items to the shop
BattlePrizeShop::PRIZES[:NEWITEM] = BattlePrizeItem.new(
  :NEWITEM,           # Item ID
  "New Item Name",    # Display name
  10,                 # BP cost
  "Item description"  # Description
)

# Modify existing items
BattlePrizeShop::PRIZES[:EXISTINGITEM].cost = 15  # Change cost
```

#### Battle Challenge Integration
```ruby
# Award points after battle
challenge.pbAwardPoints(amount)

# Award symbol after Frontier Brain battle
challenge.pbAwardSymbol(facility, :silver)

# Check for Frontier Brain battle
if challenge.pbIsBrainBattle?
  brain = challenge.pbGetBrain
  # Handle Frontier Brain battle
end
```

#### Direct Facility Loading
```ruby
# Load directly into Battle Hall
def pbStartBattleHall
  challenge = BattleChallenge.new
  challenge.set("hall", 10, pbBattleHallRules(false, false))
  if !pbEntryScreen(challenge)
    pbMessage(_INTL("You need at least one Pokémon to enter the Battle Hall."))
    return false
  end
  challenge.pbStartChallenge
end

# Load into Battle Tower
def pbStartBattleTower
  challenge = BattleChallenge.new
  challenge.set("tower", 7, pbBattleTowerRules(false, false))
  challenge.pbStartChallenge
end

# Load into Battle Factory
def pbStartBattleFactory
  challenge = BattleChallenge.new
  challenge.set("factory", 7, pbBattleFactoryRules(false, false))
  challenge.pbStartChallenge
end

# Load into Battle Dome
def pbStartBattleDome
  challenge = BattleChallenge.new
  challenge.set("dome", 7, pbBattleDomeRules(false, false))
  challenge.pbStartChallenge
end

# Load into Battle Pike
def pbStartBattlePike
  challenge = BattleChallenge.new
  challenge.set("pike", 7, pbBattlePikeRules(false, false))
  challenge.pbStartChallenge
end

# Load into Battle Pyramid
def pbStartBattlePyramid
  challenge = BattleChallenge.new
  challenge.set("pyramid", 10, pbBattlePyramidRules(false, false))
  challenge.pbStartChallenge
end

# Load into Battle Castle
def pbStartBattleCastle
  challenge = BattleChallenge.new
  challenge.set("castle", 7, pbBattleCastleRules(false, false))
  challenge.pbStartChallenge
end

# Load into Battle Arcade
def pbStartBattleArcade
  challenge = BattleChallenge.new
  challenge.set("arcade", 7, pbBattleArcadeRules(false, false))
  challenge.pbStartChallenge
end

# Load into Battle Arena
def pbStartBattleArena
  challenge = BattleChallenge.new
  challenge.set("arena", 7, pbBattleArenaRules(false, false))
  challenge.pbStartChallenge
end

# Load into Battle Palace
def pbStartBattlePalace
  challenge = BattleChallenge.new
  challenge.set("palace", 7, pbBattlePalaceRules(false, false))
  challenge.pbStartChallenge
end

# Direct loading with custom settings
def pbStartCustomChallenge(facility, num_rounds, rules)
  challenge = BattleChallenge.new
  challenge.set(facility, num_rounds, rules)
  challenge.pbStartChallenge
end
```

#### Event Setup for Direct Loading
```ruby
# Battle Hall Entrance
def pbBattleHallEntrance
  if pbConfirmMessage(_INTL("Would you like to enter the Battle Hall?"))
    pbStartBattleHall
  end
end

# Battle Tower Entrance
def pbBattleTowerEntrance
  if pbConfirmMessage(_INTL("Would you like to enter the Battle Tower?"))
    pbStartBattleTower
  end
end

# Battle Factory Entrance
def pbBattleFactoryEntrance
  if pbConfirmMessage(_INTL("Would you like to enter the Battle Factory?"))
    pbStartBattleFactory
  end
end

# Battle Dome Entrance
def pbBattleDomeEntrance
  if pbConfirmMessage(_INTL("Would you like to enter the Battle Dome?"))
    pbStartBattleDome
  end
end

# Battle Pike Entrance
def pbBattlePikeEntrance
  if pbConfirmMessage(_INTL("Would you like to enter the Battle Pike?"))
    pbStartBattlePike
  end
end

# Battle Pyramid Entrance
def pbBattlePyramidEntrance
  if pbConfirmMessage(_INTL("Would you like to enter the Battle Pyramid?"))
    pbStartBattlePyramid
  end
end

# Battle Castle Entrance
def pbBattleCastleEntrance
  if pbConfirmMessage(_INTL("Would you like to enter the Battle Castle?"))
    pbStartBattleCastle
  end
end

# Battle Arcade Entrance
def pbBattleArcadeEntrance
  if pbConfirmMessage(_INTL("Would you like to enter the Battle Arcade?"))
    pbStartBattleArcade
  end
end

# Battle Arena Entrance
def pbBattleArenaEntrance
  if pbConfirmMessage(_INTL("Would you like to enter the Battle Arena?"))
    pbStartBattleArena
  end
end

# Battle Palace Entrance
def pbBattlePalaceEntrance
  if pbConfirmMessage(_INTL("Would you like to enter the Battle Palace?"))
    pbStartBattlePalace
  end
end

# Level Check Version (Example for Battle Hall)
def pbBattleHallEntranceWithCheck
  if $player.party.any? { |pkmn| pkmn.level >= 30 }
    if pbConfirmMessage(_INTL("Would you like to enter the Battle Hall?"))
      pbStartBattleHall
    end
  else
    pbMessage(_INTL("You need at least one Pokémon at level 30 or higher."))
  end
end
```

#### Custom Challenge Settings
```ruby
# Create custom rules for any facility
def pbCustomFacilityRules(facility)
  rules = PokemonChallengeRules.new
  rules.setLevelAdjustment(CappedLevelAdjustment.new(50))
  rules.addPokemonRule(StandardRestriction.new)
  rules.addTeamRule(SpeciesClause.new)
  rules.addTeamRule(ItemClause.new)
  
  # Add facility-specific rules
  case facility
  when "hall"
    rules.addPokemonRule(MinimumLevelRestriction.new(30))
  when "factory"
    rules.addPokemonRule(RentalRestriction.new)
  when "pyramid"
    rules.addItemRule(NoItemRestriction.new)
  end
  
  return rules
end

# Start challenge with custom rules for any facility
def pbStartCustomFacilityChallenge(facility, num_rounds)
  challenge = BattleChallenge.new
  challenge.set(facility, num_rounds, pbCustomFacilityRules(facility))
  challenge.pbStartChallenge
end
```

### Event Setup Examples

#### Prize Shop NPC
```ruby
# In an event's script command
def pbPrizeShopNPC
  BattlePrizeShop.open_shop
end
```

#### Frontier Brain Battle
```ruby
# In an event's script command
def pbFrontierBrainBattle
  if pbIsBrainBattle?
    brain = pbGetBrain
    pbMessage(_INTL("Frontier Brain {1} wants to battle!", brain.name))
    # Battle logic here
  end
end
```

### Save System Integration
The Battle Frontier systems automatically integrate with the game's save system. All data is stored in `$PokemonGlobal`:
- `$PokemonGlobal.battlePoints` - Stores BP
- `$PokemonGlobal.frontierSymbols` - Stores earned symbols
- `$PokemonGlobal.challenge` - Stores current challenge data

### Customization Options

#### Battle Points
- Modify point rewards in `BattleSystems.rb`
- Adjust point costs in `BattlePrizeShop.rb`
- Customize point display format

#### Symbols
- Add new facilities in `FrontierSymbols::SYMBOLS`
- Modify symbol requirements
- Customize symbol display

#### Frontier Brains
- Add new Frontier Brains in `FrontierBrainSystem::BRAINS`
- Modify team compositions
- Adjust battle requirements

#### Prize Shop
- Add/remove items
- Modify prices
- Change item categories
- Customize shop interface

### Common Issues and Solutions

1. **Prize Shop Not Opening**
   - Ensure `$PokemonGlobal.battlePoints` is initialized
   - Check for proper plugin loading order
   - Verify event script syntax

2. **Symbols Not Saving**
   - Confirm `$PokemonGlobal.frontierSymbols` initialization
   - Check save system integration
   - Verify symbol award conditions

3. **Frontier Brain Battles Not Triggering**
   - Verify battle number tracking
   - Check facility type matching
   - Confirm brain data exists

## Dependencies
- Pokémon Essentials v21 or later
- EBDX (Elite Battle DX) compatible

## Credits
- Based on the Battle Frontier from Pokémon Platinum
- Adapted for Pokémon Essentials
- Original concept by Game Freak 