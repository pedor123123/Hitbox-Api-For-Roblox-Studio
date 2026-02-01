--!strict
--[[

	HitboxService - This module handles the creation and management of hitboxes for a given player.
	It creates and destroys hitboxes automatically based on the provided time, and handles the system
	to detect collisions with other characters.
	
	3 Detections Mode
	Native Debug
	Static or Dinamic Hitboxes
	
	Usage:
		local HitboxService = require(path.to.HitboxService)
		local hitbox = HitboxService.new(player, size, timeToDestroy, distance)
		local params = Hitbox.NewParams()
		
		hitbox.onHit:Connect(function(character)
			print("Hit character:", character.Name)
		end)
		hitbox.onNonHit:Connect(function()
			print("Did not hit a character")
		end)
		
		-- Optional: Destroy the hitbox manually
		hitbox:Destroy()
		
	(Hitbox automatically starts)
	
	Detection Modes:
		- "OneTime" (default): Detect after getting collision.
		- "Multiple" : While the hitbox is active, check for collisions (dont detect the same object 2 times),
		- "MultiplePlus": Multiple, but ignore if already detected the object
	
	
	BY: garrinchafiller  (knuckles) - Discord
        Sabersr777       (vertigo) - Roblox
        
        
]]

local HitboxService = {}
HitboxService.__index = HitboxService

export type HitParams = {
	FilterObjs: {Instance},
	FilterMode: Enum.RaycastFilterType?,
	Size: Vector3,
	Distance: number,
	Pos: Vector3,
	FollowMode: string,
	FollowObj: Instance?,
	DetectionMode: "OneTime" | "Multiple" | "MultiplePlus"?,
}

function HitboxService.new(paramsHit: HitParams, timeToDestroy: number, debuG: boolean?)

	if not paramsHit then error("Params must be provided") end
	--[[assert(typeof(plr) == "Instance" and plr:IsA("Player"), "Argument 1 must be a Player")
	assert(typeof(size) == "Vector3", "Argument 2 must be a Vector3")
	assert(typeof(timeToDestroy) == "number", "Argument 3 must be a number")
	assert(typeof(distance) == "number", "Argument 4 must be a number")
	assert(typeof(pos) == "Vector3" or pos == nil, "Argument 5 must be a Vector3 or nil")
	assert(timeToDestroy >= 0, "Argument 3 must be greater than 0")]]
		
	
	local params = OverlapParams.new()
	params.FilterDescendantsInstances = paramsHit.FilterObjs or {}
	params.FilterType = paramsHit.FilterMode


	local self = setmetatable({}, HitboxService)
	local hitBox = Instance.new("Part")
	local motor6d = Instance.new("Motor6D")

	hitBox.Size = paramsHit.Size
	hitBox.Transparency = if debuG then 0.5 else 1
	hitBox.CanCollide = false
	hitBox.Massless = true
	hitBox.Anchored = false
	hitBox.Name = "HitBox"
	hitBox.CanQuery = false

	if paramsHit.Pos then
		hitBox.Position = paramsHit.Pos
	else
		motor6d.Part0 = paramsHit.FollowObj
		motor6d.Part1 = hitBox
		motor6d.C0 = CFrame.new(0, 0, paramsHit.Distance)
		motor6d.Parent = hitBox
	end

	hitBox.Parent = workspace

	hitBox.Name = "Hitbox"

	self.hitbox = hitBox
	self.PlayerDetected = Instance.new("BindableEvent")
	self.NonDetected = Instance.new("BindableEvent")
	self.plrs = {}
	self.timeToDestroy = timeToDestroy
	self.onHit = self.PlayerDetected.Event
	self.onNonHit = self.NonDetected.Event
	self.list = {}
	self._paramsHit = paramsHit

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

		local parts = workspace:GetPartBoundsInBox(hitBox.CFrame, hitBox.Size, params)
		
		if self._paramsHit.DetectionMode == "OneTime" then
			for i, v in pairs(parts) do
				self.PlayerDetected:Fire(v)
				table.insert(self.list, v)
				self:destroy()
				return 
			end
		elseif self._paramsHit.DetectionMode == "Multiple" then
			for i, v in pairs(parts) do
				if v.Parent:FindFirstChild("Humanoid") and not table.find(self.plrs, v.Parent) then
					table.insert(self.plrs, v.Parent)
					table.insert(self.list, {v, parts})
					self.PlayerDetected:Fire(v, parts)
				end
			end
		elseif self._paramsHit.DetectionMode == "MultiplePlus" then
			self.PlayerDetected:Fire(parts)
			table.insert(self.list, parts)
		end
	end)

	return self

end

--[[
FilterObjs: {Instance},
	FilterMode: string,
	Size: Vector3,
	Distance: number,
	Pos: Vector3,
	FollowMode: String,
	FollowObj: Instance?	
]]

function HitboxService.NewParams()
	
	local defaultParams:HitParams = {
		FilterObjs = {},
		FilterMode = Enum.RaycastFilterType.Exclude,
		Size = Vector3.new(1, 1, 1),
		Pos = nil, -- optional
		FollowMode = "Follow", -- Static
		FollowObj = nil, -- need if FollowMode is Follow,
		DetectionMode = "Default"
	} 
	
	return defaultParams
end

function HitboxService:destroy()
	
	if #self.list == 0 then
		self.NonDetected:Fire()
	end 
	self.hitbox:Destroy()
	self.plrs = {}
	self.plr = nil
	self._paramsHit = {}
	self.PlayerDetected:Destroy()
	self._conn:Disconnect()
	self.NonDetected:Destroy()
	setmetatable(self, nil)
end


return HitboxService
