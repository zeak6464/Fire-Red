#===============================================================================
# * Cry Number Support
#===============================================================================
# This plugin allows playing Pokémon cries using their Pokédex numbers
# instead of requiring their internal names as symbols.

module GameData
  class Species
    #---------------------------------------------------------------------------
    # * Play cry using Pokédex number
    #---------------------------------------------------------------------------
    def self.play_cry_by_number(number, form = 0, volume = 90, pitch = 100)
      # Convert number to 0-based index
      index = number - 1
      # Get species symbol from index
      species = self.keys[index]
      # Play cry if species exists
      self.play_cry(species, form, volume, pitch) if species
    end

    #---------------------------------------------------------------------------
    # * Override original play_cry to support numbers
    #---------------------------------------------------------------------------
    class << self
      alias_method :original_play_cry, :play_cry
      def play_cry(species, form = 0, volume = 90, pitch = 100)
        if species.is_a?(Integer)
          play_cry_by_number(species, form, volume, pitch)
        else
          # Pass only the required arguments to the original method
          original_play_cry(species, form, volume)
        end
      end
    end
  end
end 