# Hitbox-Api-For-Roblox-Studio
HitboxService - This module handles the creation and management of hitboxes for a given player.
	It creates and destroys hitboxes automatically based on the provided time, and handles the system
	to detect collisions with other characters.
	Usage:
		local HitboxService = require(path.to.HitboxService)
		local hitbox = HitboxService.new(player, size, timeToDestroy, distance)
		
		hitbox.onHit:Connect(function(character)
			print("Hit character:", character.Name)
		end)
		hitbox.onNonHit:Connect(function()
			print("Did not hit a character")
		end)
		
		-- Optional: Destroy the hitbox manually
		hitbox:Destroy()
		
	(Hitbox automatically starts)
	
	BY: garrinchafiller  (knuckles) - Discord
        Sabersr777       (vertigo) - Roblox
        
