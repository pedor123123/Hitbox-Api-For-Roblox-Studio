--!strict

--[[

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
        
]]

local HitboxService = {}
HitboxService.__index = HitboxService

function HitboxService.new(plr: Player, size: Vector3, timeToDestroy: number, distance: number, pos: Vector3?, debuG: boolean?)
	
	assert(typeof(plr) == "Instance" and plr:IsA("Player"), "Argument 1 must be a Player")
	assert(typeof(size) == "Vector3", "Argument 2 must be a Vector3")
	assert(typeof(timeToDestroy) == "number", "Argument 3 must be a number")
	assert(typeof(distance) == "number", "Argument 4 must be a number")
	assert(typeof(pos) == "Vector3" or pos == nil, "Argument 5 must be a Vector3 or nil")
	assert(timeToDestroy >= 0, "Argument 3 must be greater than 0")
	local params = OverlapParams.new()
	params.FilterDescendantsInstances = {plr.Character}
	params.FilterType = Enum.RaycastFilterType.Exclude
	
	local self = setmetatable({}, HitboxService)
	local hitBox = Instance.new("Part")
	local motor6d = Instance.new("Motor6D")
	
	hitBox.Size = size
	hitBox.Transparency = 1
	hitBox.CanCollide = false
	hitBox.Massless = true
	hitBox.Anchored = false
	hitBox.Name = "HitBox"
	hitBox.CanQuery = false
	
	if debuG then
		hitBox.Transparency = 0.5
		hitBox.Color = Color3.fromRGB(255, 0, 0)
	end
	
	if pos then
		hitBox.Position = pos
	else
		motor6d.Part0 = plr.Character.HumanoidRootPart
		motor6d.Part1 = hitBox
		motor6d.C0 = CFrame.new(0, 0, distance)
		motor6d.Parent = hitBox
	end
	
	hitBox.Parent = plr.Character
	
	hitBox.Name = plr.Name.." Hitbox"
	
	self.hitbox = hitBox
	self.plr = plr
	self.PlayerDetected = Instance.new("BindableEvent")
	self.NonDetected = Instance.new("BindableEvent")
	self.plrs = {}
	self.timeToDestroy = timeToDestroy
	self.onHit = self.PlayerDetected.Event
	self.onNonHit = self.NonDetected.Event
	
	local elapsed = 0
	self._conn = game:GetService("RunService").Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed >= self.timeToDestroy then
			if #self.plrs > 0 then
				self:destroy()
				return 
			end

			self.NonDetected:Fire()
			self:destroy()
			return 
		end
		
		local parts = workspace:GetPartBoundsInBox(hitBox.CFrame, size, params)

		for i, v in pairs(parts) do
			if v.Parent:FindFirstChild("Humanoid") then
				if not table.find(self.plrs, v.Parent.Name) then
					if v:IsA("Accessory") or v:IsA("Tool") then continue end
					table.insert(self.plrs, v.Parent.Name)
					self.PlayerDetected:Fire(v.Parent)
				end
			end
		end
	end)
	
	return self
	
end

function HitboxService:destroy()
	self.hitbox:Destroy()
	self.plrs = {}
	self.plr = nil
	self.PlayerDetected:Destroy()
	self._conn:Disconnect()
	self.NonDetected:Destroy()
	setmetatable(self, nil)
end


return HitboxService

