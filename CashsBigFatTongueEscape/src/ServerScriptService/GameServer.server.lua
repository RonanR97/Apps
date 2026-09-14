local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Shop = require(ReplicatedStorage:WaitForChild("MonetizationConfig"))

local C = {
	StartTongue = 40, MaxTongue = 10000, GrowthTime = 1,
	SlideCooldown = 0.7, SlideSpeed = 72, UpgradeCost = 250,
	RebirthCost = 3000, FinishReward = 1000, Zones = 5, Pads = 8,
}

local remotes = ReplicatedStorage:FindFirstChild("TongueRemotes") or Instance.new("Folder")
remotes.Name = "TongueRemotes"
remotes.Parent = ReplicatedStorage
local action = remotes:FindFirstChild("Action") or Instance.new("RemoteEvent")
action.Name = "Action"
action.Parent = remotes
local feedback = remotes:FindFirstChild("Feedback") or Instance.new("RemoteEvent")
feedback.Name = "Feedback"
feedback.Parent = remotes

local store
pcall(function() store = DataStoreService:GetDataStore("CashsBigFatTongueEscapeV4") end)
local sessions = {}

local function value(className, name, initial, parent)
	local item = Instance.new(className)
	item.Name, item.Value, item.Parent = name, initial, parent
	return item
end

local function defaults()
	return {Clicks = 0, TongueLength = C.StartTongue, Wins = 0, Rebirths = 0, Checkpoint = 0, GrowthLevel = 1}
end

local function clean(raw)
	local data = defaults()
	if type(raw) == "table" then
		for key, fallback in pairs(data) do
			local number = tonumber(raw[key])
			data[key] = number and math.max(0, math.floor(number)) or fallback
		end
	end
	data.TongueLength = math.clamp(data.TongueLength, C.StartTongue, C.MaxTongue)
	data.GrowthLevel = math.max(1, data.GrowthLevel)
	data.Checkpoint = math.clamp(data.Checkpoint, 0, C.Zones)
	return data
end

local function snapshot(player)
	local stats, progress = player:FindFirstChild("leaderstats"), player:FindFirstChild("Progress")
	if not stats or not progress then return end
	return {
		Clicks = stats.Clicks.Value, TongueLength = stats.TongueLength.Value,
		Wins = stats.Wins.Value, Rebirths = stats.Rebirths.Value,
		Checkpoint = progress.Checkpoint.Value, GrowthLevel = progress.GrowthLevel.Value,
	}
end

local function save(player)
	if not store then return end
	local data = snapshot(player)
	if not data then return end
	pcall(function() store:UpdateAsync("player_" .. player.UserId, function() return data end) end)
end

local function owns(player, pass)
	if not pass or pass.Id <= 0 then return false end
	local ok, result = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.Id) end)
	return ok and result
end

local function refreshPasses(player)
	player:SetAttribute("HasVIP", owns(player, Shop.GamePasses.VIP))
	player:SetAttribute("HasDoubleGrowth", owns(player, Shop.GamePasses.DoubleGrowth))
	player:SetAttribute("HasSuperTongue", owns(player, Shop.GamePasses.SuperTongue))
end

local function growth(player)
	local stats, progress = player:FindFirstChild("leaderstats"), player:FindFirstChild("Progress")
	if not stats or not progress then return 1 end
	local amount = progress.GrowthLevel.Value * math.max(1, stats.Rebirths.Value + 1)
	if player:GetAttribute("HasDoubleGrowth") then amount *= 2 end
	if player:GetAttribute("HasVIP") then amount = math.max(1, math.floor(amount * 1.5)) end
	return amount
end

local function tongueColor(player)
	if player:GetAttribute("HasVIP") then return Color3.fromRGB(255, 214, 45) end
	if player:GetAttribute("HasSuperTongue") then return Color3.fromRGB(172, 74, 255) end
	return Color3.fromRGB(255, 82, 154)
end

local function mouthTongue(player, character)
	local head = character:WaitForChild("Head", 5)
	if not head then return end
	local old = character:FindFirstChild("CashTongueTip")
	if old then old:Destroy() end
	local tongue = Instance.new("Part")
	tongue.Name = "CashTongueTip"
	tongue.Size = Vector3.new(0.85, 0.38, 2.4)
	tongue.Color = tongueColor(player)
	local premiumTongue = player:GetAttribute("HasVIP") or player:GetAttribute("HasSuperTongue")
	tongue.Material = premiumTongue and Enum.Material.Neon or Enum.Material.SmoothPlastic
	tongue.CanCollide, tongue.CanTouch, tongue.CanQuery = false, false, false
	tongue.Massless, tongue.CastShadow, tongue.Parent = true, false, character
	local weld = Instance.new("Weld")
	weld.Part0, weld.Part1, weld.C0, weld.Parent = head, tongue, CFrame.new(0, -0.23, -1.55), tongue
end

local function checkpointTeleport(player, character)
	local progress = player:FindFirstChild("Progress")
	local world = workspace:FindFirstChild("CashTongueWorld")
	local points = world and world:FindFirstChild("CheckpointSpawns")
	local target = points and progress and points:FindFirstChild("Checkpoint" .. progress.Checkpoint.Value)
	if target then character:PivotTo(target.CFrame + Vector3.new(0, 4, 0)) end
end

local function load(player)
	local data = defaults()
	if store then
		local ok, result = pcall(function() return store:GetAsync("player_" .. player.UserId) end)
		if ok then data = clean(result) end
	end
	local stats = Instance.new("Folder")
	stats.Name, stats.Parent = "leaderstats", player
	value("IntValue", "TongueLength", data.TongueLength, stats)
	value("IntValue", "Clicks", data.Clicks, stats)
	value("IntValue", "Wins", data.Wins, stats)
	value("IntValue", "Rebirths", data.Rebirths, stats)
	local progress = Instance.new("Folder")
	progress.Name, progress.Parent = "Progress", player
	value("IntValue", "Checkpoint", data.Checkpoint, progress)
	value("IntValue", "GrowthLevel", data.GrowthLevel, progress)
	sessions[player] = {lastSlide = 0, sliding = false, dirty = false}
	refreshPasses(player)
	player.CharacterAdded:Connect(function(character)
		mouthTongue(player, character)
		local humanoid = character:WaitForChild("Humanoid", 5)
		if humanoid and player:GetAttribute("HasVIP") then humanoid.WalkSpeed = 20 end
		task.wait(0.2)
		checkpointTeleport(player, character)
	end)
end

local function tongueBridge(player, origin, destination, lifetime)
	local distance = (destination - origin).Magnitude
	local bridge = Instance.new("Part")
	bridge.Name = "ExtendedTongue"
	bridge.Size = Vector3.new(2.8, 0.55, distance)
	bridge.CFrame = CFrame.lookAt((origin + destination) * 0.5, destination)
	bridge.Color, bridge.Material = tongueColor(player), Enum.Material.Neon
	bridge.Anchored, bridge.CanCollide, bridge.CanTouch, bridge.CanQuery = true, true, false, false
	bridge.Parent = workspace
	Debris:AddItem(bridge, lifetime)
end

local function slide(player, target)
	local session, character, stats = sessions[player], player.Character, player:FindFirstChild("leaderstats")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local head = character and character:FindFirstChild("Head")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not session or not stats or not root or not head or not humanoid or typeof(target) ~= "Vector3" then return end
	if session.sliding or humanoid.Health <= 0 or os.clock() - session.lastSlide < C.SlideCooldown then return end
	local offset = target - head.Position
	local maximum = stats.TongueLength.Value + (player:GetAttribute("HasSuperTongue") and 30 or 0)
	if offset.Magnitude > maximum + 3 then
		feedback:FireClient(player, "Too far! Need " .. math.ceil(offset.Magnitude) .. " studs")
		return
	end
	local params = RaycastParams.new()
	params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, {character}
	local hit = workspace:Raycast(head.Position, offset, params)
	if not hit or (hit.Position - target).Magnitude > 4 then return end
	if not hit.Instance:GetAttribute("TongueTarget") then
		feedback:FireClient(player, "Aim at a coloured platform")
		return
	end

	session.lastSlide, session.sliding = os.clock(), true
	local destination = hit.Position + Vector3.new(0, 3.4, 0)
	local speed = C.SlideSpeed * (player:GetAttribute("HasSuperTongue") and 1.25 or 1)
	local duration = math.clamp((destination - root.Position).Magnitude / speed, 0.4, 1.5)
	tongueBridge(player, head.Position, hit.Position, duration + 0.5)
	feedback:FireClient(player, "SlideStart", duration)
	humanoid.AutoRotate, humanoid.PlatformStand, root.Anchored = false, true, true
	local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {CFrame = CFrame.new(destination)})
	tween:Play()
	tween.Completed:Wait()
	if root.Parent and humanoid.Parent then
		root.Anchored, humanoid.PlatformStand, humanoid.AutoRotate = false, false, true
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
	session.sliding = false
	feedback:FireClient(player, "Landed")
end

local function upgrade(player)
	local stats, progress = player:FindFirstChild("leaderstats"), player:FindFirstChild("Progress")
	if not stats or not progress then return end
	local cost = C.UpgradeCost * progress.GrowthLevel.Value
	if stats.Clicks.Value < cost then feedback:FireClient(player, "Need " .. cost .. " growth points") return end
	stats.Clicks.Value -= cost
	progress.GrowthLevel.Value += 1
	sessions[player].dirty = true
	feedback:FireClient(player, "Growth upgraded to +" .. growth(player))
end

local function rebirth(player)
	local stats, progress = player:FindFirstChild("leaderstats"), player:FindFirstChild("Progress")
	if not stats or not progress then return end
	local cost = C.RebirthCost * (stats.Rebirths.Value + 1)
	if stats.Clicks.Value < cost then feedback:FireClient(player, "Need " .. cost .. " growth points") return end
	stats.Clicks.Value, stats.TongueLength.Value = 0, C.StartTongue
	stats.Rebirths.Value += 1
	progress.Checkpoint.Value = 0
	sessions[player].dirty = true
	player:LoadCharacter()
	feedback:FireClient(player, "Rebirth complete!")
end

action.OnServerEvent:Connect(function(player, request, payload)
	if request == "Slide" then task.spawn(slide, player, payload)
	elseif request == "Upgrade" then upgrade(player)
	elseif request == "Rebirth" then rebirth(player) end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, id, bought)
	if not bought then return end
	for _, pass in pairs(Shop.GamePasses) do
		if pass.Id == id then
			refreshPasses(player)
			if player.Character then mouthTongue(player, player.Character) end
			feedback:FireClient(player, pass.Label .. " unlocked!")
			break
		end
	end
end)

MarketplaceService.ProcessReceipt = function(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
	local stats, progress = player:FindFirstChild("leaderstats"), player:FindFirstChild("Progress")
	if not stats or not progress then return Enum.ProductPurchaseDecision.NotProcessedYet end
	local id = receipt.ProductId
	if id > 0 and id == Shop.Products.Clicks500.Id then
		stats.Clicks.Value += 500
		stats.TongueLength.Value = math.min(C.MaxTongue, stats.TongueLength.Value + 500)
	elseif id > 0 and id == Shop.Products.Clicks5000.Id then
		stats.Clicks.Value += 5000
		stats.TongueLength.Value = math.min(C.MaxTongue, stats.TongueLength.Value + 5000)
	elseif id > 0 and id == Shop.Products.SkipCheckpoint.Id then
		progress.Checkpoint.Value = math.min(C.Zones, progress.Checkpoint.Value + 1)
		if player.Character then checkpointTeleport(player, player.Character) end
	else return Enum.ProductPurchaseDecision.NotProcessedYet end
	if sessions[player] then sessions[player].dirty = true end
	save(player)
	feedback:FireClient(player, "Purchase delivered!")
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

Players.PlayerAdded:Connect(load)
Players.PlayerRemoving:Connect(function(player) save(player) sessions[player] = nil end)
game:BindToClose(function() for _, player in ipairs(Players:GetPlayers()) do save(player) end task.wait(2) end)

task.spawn(function()
	while task.wait(C.GrowthTime) do
		for player, session in pairs(sessions) do
			local stats = player:FindFirstChild("leaderstats")
			if stats and player.Parent then
				local amount = growth(player)
				stats.Clicks.Value += amount
				stats.TongueLength.Value = math.min(C.MaxTongue, stats.TongueLength.Value + amount)
				session.dirty = true
				feedback:FireClient(player, "Growth", amount)
			end
		end
	end
end)

task.spawn(function()
	while task.wait(60) do
		for player, session in pairs(sessions) do
			if session.dirty and player.Parent then save(player) session.dirty = false end
		end
	end
end)

local function block(parent, name, size, position, color, material)
	local object = Instance.new("Part")
	object.Name, object.Size, object.Position = name, size, position
	object.Anchored, object.Color, object.Material = true, color, material or Enum.Material.SmoothPlastic
	object.TopSurface, object.BottomSurface, object.Parent = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth, parent
	return object
end

local COLORS = {
	Color3.fromRGB(255, 94, 155), Color3.fromRGB(70, 188, 255),
	Color3.fromRGB(255, 185, 45), Color3.fromRGB(161, 89, 255),
	Color3.fromRGB(73, 225, 145),
}
local NAMES = {"Candy Mouth", "Frozen Teeth", "Spicy Throat", "Cosmic Belly", "Golden Escape"}

local function sign(target, text, color)
	local gui = Instance.new("BillboardGui")
	gui.Size, gui.StudsOffset, gui.AlwaysOnTop, gui.Parent = UDim2.fromOffset(250, 70), Vector3.new(0, 5, 0), true, target
	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundTransparency, label.Text = UDim2.fromScale(1, 1), 1, text
	label.TextColor3, label.TextStrokeTransparency = color, 0
	label.Font, label.TextScaled, label.Parent = Enum.Font.GothamBlack, true, gui
end

local function buildWorld()
	local old = workspace:FindFirstChild("CashTongueWorld")
	if old then old:Destroy() end
	local world = Instance.new("Folder")
	world.Name, world.Parent = "CashTongueWorld", workspace
	local points = Instance.new("Folder")
	points.Name, points.Parent = "CheckpointSpawns", world
	local start = block(world, "StartIsland", Vector3.new(90, 4, 90), Vector3.new(0, 0, 0), Color3.fromRGB(80, 205, 105), Enum.Material.Grass)
	start:SetAttribute("TongueTarget", true)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name, spawn.Size, spawn.Position = "StartSpawn", Vector3.new(14, 1, 14), Vector3.new(0, 3, 0)
	spawn.Anchored, spawn.Neutral, spawn.Color, spawn.Parent = true, true, Color3.fromRGB(255, 225, 55), world
	local marker = block(points, "Checkpoint0", Vector3.new(2, 1, 2), Vector3.new(0, 3, 0), Color3.new(1, 1, 1))
	marker.Transparency, marker.CanCollide = 1, false
	sign(spawn, "GROW YOUR TONGUE\nAIM AND SLIDE", Color3.fromRGB(255, 235, 80))
	local slime = block(world, "Slime", Vector3.new(850, 4, 1200), Vector3.new(0, -24, 520), Color3.fromRGB(97, 255, 60), Enum.Material.Neon)
	slime.Touched:Connect(function(hit) local human = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid") if human then human.Health = 0 end end)

	local current, number = Vector3.new(0, 7, 34), 0
	for zone = 1, C.Zones do
		local range = 32 + (zone - 1) * 18
		for index = 1, C.Pads do
			number += 1
			local side = number % 2 == 0 and 1 or -1
			local x, y = side * (8 + number % 3 * 4), 4 + zone
			local z = math.sqrt(math.max(100, range * range - x * x - y * y))
			if number == 1 then current = Vector3.new(-8, 7, 38) else current += Vector3.new(x, y, z) end
			local pad = block(world, "Platform" .. number, Vector3.new(20, 2, 15), current, COLORS[zone])
			pad:SetAttribute("TongueTarget", true)
			pad:SetAttribute("Zone", zone)
			if index == 1 then sign(pad, "ZONE " .. zone .. "\n" .. NAMES[zone], COLORS[zone]) end
			if index == C.Pads then
				local checkpointZone = zone
				pad.Name, pad.Material = "ZoneCheckpoint" .. zone, Enum.Material.Neon
				local checkpoint = block(points, "Checkpoint" .. zone, Vector3.new(2, 1, 2), current + Vector3.new(0, 3, 0), Color3.new(1, 1, 1))
				checkpoint.Transparency, checkpoint.CanCollide = 1, false
				pad.Touched:Connect(function(hit)
					local player = Players:GetPlayerFromCharacter(hit.Parent)
					local progress = player and player:FindFirstChild("Progress")
					if progress and checkpointZone > progress.Checkpoint.Value then
						progress.Checkpoint.Value = checkpointZone
						sessions[player].dirty = true
						feedback:FireClient(player, "ZONE COMPLETE: " .. NAMES[checkpointZone])
					end
				end)
			end
		end
	end
	local finish = block(world, "GoldenFinish", Vector3.new(48, 4, 48), current + Vector3.new(0, 12, 38), Color3.fromRGB(255, 214, 48), Enum.Material.Neon)
	finish:SetAttribute("TongueTarget", true)
	sign(finish, "CASH ESCAPED!", Color3.fromRGB(255, 235, 80))
	local debounce = {}
	finish.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player or debounce[player] then return end
		local stats, progress = player:FindFirstChild("leaderstats"), player:FindFirstChild("Progress")
		if not stats or not progress or progress.Checkpoint.Value < C.Zones then return end
		debounce[player] = true
		stats.Wins.Value += 1
		stats.Clicks.Value += C.FinishReward
		progress.Checkpoint.Value = 0
		sessions[player].dirty = true
		feedback:FireClient(player, "ESCAPED! +1 WIN +1000 GROWTH")
		task.delay(2, function() if player.Parent then player:LoadCharacter() end end)
		task.delay(5, function() debounce[player] = nil end)
	end)
end

buildWorld()
