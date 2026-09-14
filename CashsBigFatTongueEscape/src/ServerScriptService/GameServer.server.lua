local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Debris = game:GetService("Debris")

local CONFIG = {
	StartingTongue = 12,
	ClickCooldown = 0.12,
	GrappleCooldown = 0.35,
	PullSpeed = 82,
	PullDuration = 0.55,
	MaxTongue = 2500,
	FinishReward = 250,
	RebirthBaseCost = 1000,
	UpgradeBaseCost = 150
}

local remotes = ReplicatedStorage:FindFirstChild("TongueRemotes") or Instance.new("Folder")
remotes.Name = "TongueRemotes"
remotes.Parent = ReplicatedStorage

local actionEvent = remotes:FindFirstChild("Action") or Instance.new("RemoteEvent")
actionEvent.Name = "Action"
actionEvent.Parent = remotes

local feedbackEvent = remotes:FindFirstChild("Feedback") or Instance.new("RemoteEvent")
feedbackEvent.Name = "Feedback"
feedbackEvent.Parent = remotes

local store = DataStoreService:GetDataStore("CashsBigFatTongueEscapeV1")
local sessions = {}

local function makeValue(className, name, value, parent)
	local item = Instance.new(className)
	item.Name = name
	item.Value = value
	item.Parent = parent
	return item
end

local function defaultData()
	return {
		Clicks = 0,
		TongueLength = CONFIG.StartingTongue,
		Wins = 0,
		Rebirths = 0,
		Checkpoint = 0,
		ClickLevel = 1
	}
end

local function sanitize(raw)
	local data = defaultData()
	if type(raw) == "table" then
		for key, fallback in pairs(data) do
			local value = tonumber(raw[key])
			if value then
				data[key] = math.max(0, math.floor(value))
			else
				data[key] = fallback
			end
		end
	end
	data.TongueLength = math.clamp(data.TongueLength, CONFIG.StartingTongue, CONFIG.MaxTongue)
	data.ClickLevel = math.max(1, data.ClickLevel)
	return data
end

local function loadPlayer(player)
	local data = defaultData()
	local ok, result = pcall(function()
		return store:GetAsync("p_" .. player.UserId)
	end)
	if ok then
		data = sanitize(result)
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	makeValue("IntValue", "Clicks", data.Clicks, leaderstats)
	makeValue("IntValue", "TongueLength", data.TongueLength, leaderstats)
	makeValue("IntValue", "Wins", data.Wins, leaderstats)
	makeValue("IntValue", "Rebirths", data.Rebirths, leaderstats)

	local progress = Instance.new("Folder")
	progress.Name = "Progress"
	progress.Parent = player
	makeValue("IntValue", "Checkpoint", data.Checkpoint, progress)
	makeValue("IntValue", "ClickLevel", data.ClickLevel, progress)

	sessions[player] = {lastClick = 0, lastGrapple = 0, dirty = false}

	player.CharacterAdded:Connect(function(character)
		task.wait(0.25)
		local checkpoint = progress.Checkpoint.Value
		local world = workspace:FindFirstChild("TongueEscapeWorld")
		local checkpoints = world and world:FindFirstChild("Checkpoints")
		local target = checkpoints and checkpoints:FindFirstChild("Checkpoint" .. checkpoint)
		local root = character:FindFirstChild("HumanoidRootPart")
		if target and root then
			character:PivotTo(target.CFrame + Vector3.new(0, 5, 0))
		end
	end)
end

local function snapshot(player)
	local stats = player:FindFirstChild("leaderstats")
	local progress = player:FindFirstChild("Progress")
	if not stats or not progress then return nil end
	return {
		Clicks = stats.Clicks.Value,
		TongueLength = stats.TongueLength.Value,
		Wins = stats.Wins.Value,
		Rebirths = stats.Rebirths.Value,
		Checkpoint = progress.Checkpoint.Value,
		ClickLevel = progress.ClickLevel.Value
	}
end

local function savePlayer(player)
	local data = snapshot(player)
	if not data then return end
	pcall(function()
		store:UpdateAsync("p_" .. player.UserId, function()
			return data
		end)
	end)
end

local function click(player)
	local session = sessions[player]
	local stats = player:FindFirstChild("leaderstats")
	local progress = player:FindFirstChild("Progress")
	if not session or not stats or not progress then return end
	local now = os.clock()
	if now - session.lastClick < CONFIG.ClickCooldown then return end
	session.lastClick = now
	local gain = progress.ClickLevel.Value * math.max(1, stats.Rebirths.Value + 1)
	stats.Clicks.Value += gain
	stats.TongueLength.Value = math.min(CONFIG.MaxTongue, stats.TongueLength.Value + gain)
	session.dirty = true
end

local function grapple(player, target)
	if typeof(target) ~= "Vector3" then return end
	local session = sessions[player]
	local character = player.Character
	local stats = player:FindFirstChild("leaderstats")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local head = character and character:FindFirstChild("Head")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not session or not stats or not root or not head or not humanoid or humanoid.Health <= 0 then return end

	local now = os.clock()
	if now - session.lastGrapple < CONFIG.GrappleCooldown then return end
	local offset = target - head.Position
	local distance = offset.Magnitude
	if distance < 3 or distance > stats.TongueLength.Value + 2 then
		feedbackEvent:FireClient(player, "Too far away")
		return
	end
	if head.CFrame.LookVector:Dot(offset.Unit) < 0.15 then return end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}
	local result = workspace:Raycast(head.Position, offset, params)
	if not result or (result.Position - target).Magnitude > 4 then return end
	session.lastGrapple = now

	local mouth = Instance.new("Attachment")
	mouth.Name = "TongueMouth"
	mouth.Position = Vector3.new(0, -0.15, -0.52)
	mouth.Parent = head

	local anchor = Instance.new("Part")
	anchor.Name = "TongueAnchor"
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Position = result.Position
	anchor.Parent = workspace
	local endpoint = Instance.new("Attachment")
	endpoint.Parent = anchor

	local beam = Instance.new("Beam")
	beam.Attachment0 = mouth
	beam.Attachment1 = endpoint
	beam.Width0 = 0.65
	beam.Width1 = 0.34
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 72, 148), Color3.fromRGB(255, 165, 205))
	beam.FaceCamera = true
	beam.LightEmission = 0.35
	beam.TextureSpeed = 2
	beam.Parent = mouth

	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "TonguePull"
	velocity.Attachment0 = root:FindFirstChild("RootAttachment") or Instance.new("Attachment", root)
	velocity.MaxForce = 70000
	velocity.VectorVelocity = (result.Position - root.Position).Unit * CONFIG.PullSpeed + Vector3.new(0, 16, 0)
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.Parent = root

	Debris:AddItem(mouth, CONFIG.PullDuration)
	Debris:AddItem(anchor, CONFIG.PullDuration)
	Debris:AddItem(velocity, CONFIG.PullDuration)
end

local function buyUpgrade(player)
	local stats = player:FindFirstChild("leaderstats")
	local progress = player:FindFirstChild("Progress")
	if not stats or not progress then return end
	local cost = CONFIG.UpgradeBaseCost * progress.ClickLevel.Value
	if stats.Clicks.Value < cost then
		feedbackEvent:FireClient(player, "Need " .. cost .. " clicks")
		return
	end
	stats.Clicks.Value -= cost
	progress.ClickLevel.Value += 1
	sessions[player].dirty = true
	feedbackEvent:FireClient(player, "Click power upgraded")
end

local function rebirth(player)
	local stats = player:FindFirstChild("leaderstats")
	local progress = player:FindFirstChild("Progress")
	if not stats or not progress then return end
	local cost = CONFIG.RebirthBaseCost * (stats.Rebirths.Value + 1)
	if stats.Clicks.Value < cost then
		feedbackEvent:FireClient(player, "Need " .. cost .. " clicks")
		return
	end
	stats.Clicks.Value = 0
	stats.TongueLength.Value = CONFIG.StartingTongue
	stats.Rebirths.Value += 1
	progress.Checkpoint.Value = 0
	sessions[player].dirty = true
	feedbackEvent:FireClient(player, "Rebirth complete")
	player:LoadCharacter()
end

actionEvent.OnServerEvent:Connect(function(player, action, payload)
	if action == "Click" then
		click(player)
	elseif action == "Grapple" then
		grapple(player, payload)
	elseif action == "Upgrade" then
		buyUpgrade(player)
	elseif action == "Rebirth" then
		rebirth(player)
	end
end)

Players.PlayerAdded:Connect(loadPlayer)
Players.PlayerRemoving:Connect(function(player)
	savePlayer(player)
	sessions[player] = nil
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		savePlayer(player)
	end
	task.wait(2)
end)

task.spawn(function()
	while task.wait(60) do
		for player, session in pairs(sessions) do
			if session.dirty and player.Parent then
				savePlayer(player)
				session.dirty = false
			end
		end
	end
end)

local function newPart(parent, name, size, position, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function buildWorld()
	local old = workspace:FindFirstChild("TongueEscapeWorld")
	if old then old:Destroy() end
	local world = Instance.new("Folder")
	world.Name = "TongueEscapeWorld"
	world.Parent = workspace
	local checkpoints = Instance.new("Folder")
	checkpoints.Name = "Checkpoints"
	checkpoints.Parent = world

	local base = newPart(world, "StartIsland", Vector3.new(90, 4, 90), Vector3.new(0, 0, 0), Color3.fromRGB(61, 190, 92), Enum.Material.Grass)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "StartSpawn"
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 3, 0)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Color = Color3.fromRGB(255, 220, 60)
	spawn.Parent = world

	local deathFloor = newPart(world, "Slime", Vector3.new(500, 3, 500), Vector3.new(0, -22, 260), Color3.fromRGB(115, 255, 55), Enum.Material.Neon)
	deathFloor.Touched:Connect(function(hit)
		local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.Health = 0 end
	end)

	local colors = {
		Color3.fromRGB(255, 92, 148),
		Color3.fromRGB(80, 190, 255),
		Color3.fromRGB(255, 183, 55),
		Color3.fromRGB(160, 95, 255)
	}
	local last = Vector3.new(0, 8, 28)
	for index = 1, 36 do
		local side = (index % 2 == 0) and 1 or -1
		local x = side * (10 + (index % 4) * 5)
		local y = 7 + index * 6
		local z = 28 + index * 13
		last = Vector3.new(x, y, z)
		local width = (index % 5 == 0) and 9 or 15
		local platform = newPart(world, "TonguePlatform" .. index, Vector3.new(width, 2, 9), last, colors[(index - 1) % #colors + 1], Enum.Material.SmoothPlastic)
		if index % 6 == 0 then
			local checkpointNumber = index / 6
			platform.Name = "Checkpoint" .. checkpointNumber
			platform.Color = Color3.fromRGB(255, 230, 40)
			platform.Material = Enum.Material.Neon
			platform.Parent = checkpoints
			platform.Touched:Connect(function(hit)
				local player = Players:GetPlayerFromCharacter(hit.Parent)
				local progress = player and player:FindFirstChild("Progress")
				if progress and checkpointNumber > progress.Checkpoint.Value then
					progress.Checkpoint.Value = checkpointNumber
					sessions[player].dirty = true
					feedbackEvent:FireClient(player, "Checkpoint " .. checkpointNumber)
				end
			end)
		end
		if index % 4 == 0 then
			local pole = newPart(world, "GrapplePole" .. index, Vector3.new(3, 14, 3), last + Vector3.new(-side * 12, 7, 4), Color3.fromRGB(255, 110, 180), Enum.Material.Neon)
			pole.Shape = Enum.PartType.Cylinder
			pole.Orientation = Vector3.new(0, 0, 90)
		end
	end

	local finish = newPart(world, "Finish", Vector3.new(34, 3, 34), last + Vector3.new(0, 12, 18), Color3.fromRGB(255, 213, 40), Enum.Material.Neon)
	local finishDebounce = {}
	finish.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player or finishDebounce[player] then return end
		finishDebounce[player] = true
		local stats = player:FindFirstChild("leaderstats")
		local progress = player:FindFirstChild("Progress")
		if stats and progress and progress.Checkpoint.Value >= 6 then
			stats.Wins.Value += 1
			stats.Clicks.Value += CONFIG.FinishReward
			progress.Checkpoint.Value = 0
			sessions[player].dirty = true
			feedbackEvent:FireClient(player, "ESCAPED! +1 Win and +" .. CONFIG.FinishReward .. " Clicks")
			task.delay(1, function()
				if player.Parent then player:LoadCharacter() end
			end)
		end
		task.delay(3, function() finishDebounce[player] = nil end)
	end)

	workspace.FallenPartsDestroyHeight = -40
	base:SetAttribute("GameTitle", "Cash's Big Fat Tongue Escape")
end

buildWorld()
