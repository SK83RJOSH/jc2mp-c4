class "C4Spawner"

C4Spawner.MaxC4 = 10
C4Spawner.SpawnDelay = 1

function C4Spawner:__init()
	self.timer = Timer()
	self.playerData = {}

	Events:Subscribe("ModuleLoad", self, self.ModuleLoad)
	Events:Subscribe("PlayerJoin", self, self.PlayerJoin)
	Events:Subscribe("PlayerQuit", self, self.PlayerQuit)
	Events:Subscribe("EntityDespawn", self, self.EntityDespawn)
	Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
	Network:Subscribe("Spawn", self, self.Spawn)
	Network:Subscribe("Detonate", self, self.Detonate)
end

function C4Spawner:ModuleLoad()
	for player in Server:GetPlayers() do
		C4Spawner:PlayerJoin({player = player})
	end
end

function C4Spawner:PlayerJoin(args)
	local player = args.player

	self.playerData[player:GetId()] = {
		count = 0,
		timer = Timer()
	}
end

function C4Spawner:PlayerQuit(args)
	local player = args.player

	for k, c4 in pairs(C4Manager.C4) do
		if c4:GetOwner() == player then
			c4:Remove()
		end
	end

	self.playerData[player:GetId()] = nil
end

function C4Spawner:EntityDespawn(args)
	local entity = args.entity

	for k, c4 in pairs(C4Manager.C4) do
		local parent = c4:GetParent()
		local owner = c4:GetOwner()
		local playerData = self.playerData[owner:GetId()]

		if parent and parent.__type == entity.__type and parent == entity then
			c4:Remove()
			playerData.count = playerData.count - 1
		end
	end
end

function C4Spawner:ModuleUnload()
	for k, c4 in pairs(C4Manager.C4) do
		c4:Remove()
	end
end

function C4Spawner:Spawn(args, sender)
	local playerData = self.playerData[sender:GetId()]

	if playerData.count < C4Spawner.MaxC4 then
		local timeRemaining = math.max(math.floor(C4Spawner.SpawnDelay - playerData.timer:GetSeconds()), 0)

		if timeRemaining == 0 then
			playerData.timer:Restart()
			playerData.count = playerData.count + 1
			
			args.values.type = C4.__type
			args.values.owner = sender

			WorldNetworkObject.Create(args):SetStreamDistance(500)
		else
			sender:SendChatMessage("Please wait " .. timeRemaining .. " second" .. (timeRemaining ~= 1 and "s" or "") .. " before placing another satchel!", Color.Yellow)
		end
	else
		sender:SendChatMessage("You cannot place more than " .. C4Spawner.MaxC4 .. " satchel" .. (C4Spawner.MaxC4 ~= 1 and "s" or "") .. " at a time!", Color.Yellow)
	end
end

function C4Spawner:Detonate(args, sender)
	local playerData = self.playerData[sender:GetId()]

	for k, c4 in pairs(C4Manager.C4) do
		if c4:GetOwner() == sender then
			c4:Detonate()
		end
	end

	playerData.count = 0
end

C4Spawner = C4Spawner()
