#-------------------------------------------------------------------------------
#  SILVERWIND
#-------------------------------------------------------------------------------
EliteBattle.defineMoveAnimation(:SILVERWIND) do
# set up animation
  fp = {}
  fp["bg"] = Sprite.new(@viewport)
  fp["bg"].bitmap = Bitmap.new(@viewport.width,@viewport.height)
  fp["bg"].bitmap.fill_rect(0,0,fp["bg"].bitmap.width,fp["bg"].bitmap.height,Color.new(104,146,164))
  fp["bg"].opacity = 0
  fp["wave"] = AnimatedPlane.new(@viewport)
  fp["wave"].bitmap = Bitmap.new(1026,@viewport.height)
  fp["wave"].bitmap.stretch_blt(Rect.new(0,0,fp["wave"].bitmap.width,fp["wave"].bitmap.height),pbBitmap("Graphics/EBDX/Animations/Moves/eb132_3"),Rect.new(0,0,1026,212))
  fp["wave"].opacity = 0
  fp["wave"].z = 50
  rndx = []
  rndy = []
  @vector.set(EliteBattle.get_vector(:DUAL))
  @vector.inc = 0.1
  pulse = 10
  shake = [4,4,4,4]
  # start animation
  for j in 0...80#64
    pbSEPlay("Anim/Silverwind",150) if j == 24
    fp["wave"].ox += 48
    fp["wave"].opacity += pulse
    pulse = -5 if fp["wave"].opacity > 160
    pulse = +5 if fp["wave"].opacity < 100
    fp["bg"].opacity += 1 if fp["bg"].opacity < 255*0.35
    for i in 0...4
      next if !(@targetIsPlayer ? [0,2] : [1,3]).include?(i)
      next if !(@sprites["pokemon_#{i}"] && @sprites["pokemon_#{i}"].visible) || @sprites["pokemon_#{i}"].disposed?
      @sprites["pokemon_#{i}"].tone.all += 3 if j.between?(16,48)
      if j >= 32
        @sprites["pokemon_#{i}"].ox += shake[i]
        shake[i] = -4 if @sprites["pokemon_#{i}"].ox > @sprites["pokemon_#{i}"].bitmap.width/2 + 2
        shake[i] = 4 if @sprites["pokemon_#{i}"].ox < @sprites["pokemon_#{i}"].bitmap.width/2 - 2
      end
    end
	ax, ay = @userSprite.getAnchor
    cx, cy = @targetSprite.getCenter(true)
    pbSEPlay("Anim/Wind8",50) if j%24==0 && j <= 60
    @sprites["pokemon_#{@userIndex}"].tone.all += 3 if j < 32
    @sprites["pokemon_#{@userIndex}"].still
    @scene.wait(1,true)
  end
  for i in 0...4
    next if !(@targetIsPlayer ? [0,2] : [1,3]).include?(i)
    next if !(@sprites["pokemon_#{i}"] && @sprites["pokemon_#{i}"].visible) || @sprites["pokemon_#{i}"].disposed?
    @sprites["pokemon_#{i}"].ox = @sprites["pokemon_#{i}"].bitmap.width/2
  end
  for j in 0...64
    fp["wave"].ox += 48
    if j < 32
      fp["wave"].opacity += pulse
      pulse = -5 if fp["wave"].opacity > 160
      pulse = +5 if fp["wave"].opacity < 100
    end
    fp["wave"].opacity -= 4 if j >= 32
    fp["bg"].opacity -= 4 if j >= 32
    for i in 0...4
      next if !(@targetIsPlayer ? [0,2] : [1,3]).include?(i)
      next if !(@sprites["pokemon_#{i}"] && @sprites["pokemon_#{i}"].visible)
      @sprites["pokemon_#{i}"].tone.all -= 3 if j >= 32
    end
    @sprites["pokemon_#{@userIndex}"].tone.all -= 3 if j >= 32
    @sprites["pokemon_#{@userIndex}"].still
    @scene.wait(1,true)
  end
  @vector.reset if !@multiHit
  @vector.inc = 0.2
  pbDisposeSpriteHash(fp)
end