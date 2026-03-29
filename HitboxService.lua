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
		local params = Hitbox.NewParams()
		local hitbbox = HitboxService.new(params, 10, true) -- 10 seconds, debug active
		
		hitbox.onHit:Connect(function(character, parts ?) -- you can receive other parts that had touched the hitbox
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
        
        
    --OBS:
		this module has some spelling "errors," 
		such as "debuG." don't mistake that for stupidity; 
		it's just my coding style.        
]]

local HitboxService = {}
HitboxService.__index = HitboxService

HitboxService.ServiceFolder = Instance.new("Folder", game:GetService("ReplicatedStorage"))
HitboxService.ServiceFolder.Name = "HITBOX_"..tostring(math.random(100000000, 999999999))

HitboxService.HitboxEvent = Instance.new("RemoteEvent", HitboxService.ServiceFolder)
HitboxService.HitboxEvent.Name = "HitboxEvent"

HitboxService.MAX_VALUES = {
	Size = 50,
	Distance = 50,
	Time = 10
}

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
	assert(typeof(paramsHit.Size) == "Vector3", "Argument 2 must be a Vector3")
	assert(typeof(timeToDestroy) == "number", "Argument 3 must be a number")
	assert(typeof(paramsHit.Distance) == "number", "Argument 4 must be a number")
	--assert(typeof(paramsHit.Pos) == "Vector3" or paramsHit.Pos == nil, "Argument 5 must be a Vector3 or nil")
	assert(timeToDestroy >= 0, "Argument 3 must be greater than 0")
	if not paramsHit.Pos then
		assert(paramsHit.FollowObj, "FollowObj is required in this case")
	end

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
				if v.Parent:FindFirstChild("Humanoid") and not table.find(self.list, v.Parent) then
					table.insert(self.plrs, v.Parent)
					self.PlayerDetected:Fire(v)
					table.insert(self.list, v)
					self:destroy()
					return
				end
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
		DetectionMode = "OneTime"
	} 

	return defaultParams
end

function HitboxService.NewClientParams()
	return {HitboxService.NewParams(), {
		Time = 0.2,
		Debug = false
	}}
end

function HitboxService.IsItAHitParams(obj:any)
	return typeof(obj) == "table"
		and typeof(obj.Size) == "Vector3"
		and typeof(obj.Distance) == "number"
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

function HitboxService.Init()
	HitboxService.HitboxEvent.OnServerEvent:Connect(function(plr, ...)
		local params = {...}
		local hitbox = HitboxService.new(params[1], params[2])
		local localListennerHit
		local localListennerNonHit
		
		local hitParams = params[1]
		local config = params[2]
		
		if not HitboxService.IsItAHitParams(hitParams) then return end
		
		if hitParams.Size.Magnitude > HitboxService.MAX_VALUES.Size then return end
		if hitParams.Distance > HitboxService.MAX_VALUES.Distance then return end
		if config > HitboxService.MAX_VALUES.Time then return end
		
		local function clearUp()
			if localListennerHit then
				localListennerHit:Disconnect()
				localListennerHit = nil
			end
			if localListennerNonHit then
				localListennerNonHit:Disconnect()
				localListennerNonHit = nil
			end
		end
		
		localListennerHit = hitbox.onHit:Connect(function(...)
			HitboxService.HitboxEvent:FireClient(plr, "Hit", ...)
			clearUp()
		end)
		
		localListennerNonHit = hitbox.onNonHit:Connect(function(...)
			HitboxService.HitboxEvent:FireClient(plr, "NonHit", ...)
			clearUp()
		end)
		
	end)
end

return HitboxService
