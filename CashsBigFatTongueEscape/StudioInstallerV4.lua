local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

for _, target in ipairs({
    ServerScriptService:FindFirstChild("CashsTongueGame"),
    StarterPlayer.StarterPlayerScripts:FindFirstChild("CashsTongueController"),
    ReplicatedStorage:FindFirstChild("MonetizationConfig")
}) do
    if target then target:Destroy() end
end

local configScript = Instance.new("ModuleScript")
configScript.Name = "MonetizationConfig"
configScript.Source = [====[
return {
	GamePasses = {
		VIP = {
			Id = 0,
			Label = "VIP Tongue",
			Description = "Gold tongue, VIP tag, faster movement, and 50 percent more growth"
		},
		DoubleGrowth = {
			Id = 0,
			Label = "Double Growth",
			Description = "Permanently doubles every click and tongue gain"
		},
		SuperTongue = {
			Id = 0,
			Label = "Super Tongue",
			Description = "Extra grapple range, stronger pulls, and a purple tongue"
		}
	},
	Products = {
		Clicks500 = {
			Id = 0,
			Label = "500 Clicks",
			Description = "Instantly receive 500 clicks and tongue length"
		},
		Clicks5000 = {
			Id = 0,
			Label = "5000 Clicks",
			Description = "Instantly receive 5000 clicks and tongue length"
		},
		SkipCheckpoint = {
			Id = 0,
			Label = "Skip Checkpoint",
			Description = "Move forward by one checkpoint instantly"
		}
	}
}

]====]
configScript.Parent = ReplicatedStorage

local serverScript = Instance.new("Script")
serverScript.Name = "CashsTongueGame"
serverScript.Source = [====[
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
				pad.Name, pad.Material = "ZoneCheckpoint" .. zone, Enum.Material.Neon
				local checkpoint = block(points, "Checkpoint" .. zone, Vector3.new(2, 1, 2), current + Vector3.new(0, 3, 0), Color3.new(1, 1, 1))
				checkpoint.Transparency, checkpoint.CanCollide = 1, false
				pad.Touched:Connect(function(hit)
					local player = Players:GetPlayerFromCharacter(hit.Parent)
					local progress = player and player:FindFirstChild("Progress")
					if progress and zone > progress.Checkpoint.Value then
						progress.Checkpoint.Value = zone
						sessions[player].dirty = true
						feedback:FireClient(player, "ZONE COMPLETE: " .. NAMES[zone])
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

]====]
serverScript.Parent = ServerScriptService

local clientScript = Instance.new("LocalScript")
clientScript.Name = "CashsTongueController"
clientScript.Source = [====[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("TongueRemotes")
local action = remotes:WaitForChild("Action")
local feedback = remotes:WaitForChild("Feedback")
local Shop = require(ReplicatedStorage:WaitForChild("MonetizationConfig"))

local gui = Instance.new("ScreenGui")
gui.Name = "CashTongueUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function round(object, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, radius), object
end

local function outline(object, color, width)
	local stroke = Instance.new("UIStroke")
	stroke.Color, stroke.Thickness, stroke.Parent = color, width, object
end

local function gradient(object, first, second)
	local item = Instance.new("UIGradient")
	item.Color = ColorSequence.new(first, second)
	item.Rotation, item.Parent = 25, object
end

local title = Instance.new("TextLabel")
title.Size, title.Position = UDim2.fromOffset(470, 66), UDim2.new(0.5, -235, 0, 16)
title.BackgroundColor3, title.BackgroundTransparency = Color3.fromRGB(42, 24, 65), 0.04
title.Text = "CASH'S BIG FAT TONGUE ESCAPE"
title.TextColor3, title.Font, title.TextScaled = Color3.fromRGB(255, 220, 54), Enum.Font.GothamBlack, true
title.Parent = gui
round(title, 20)
outline(title, Color3.fromRGB(255, 84, 155), 3)

local stats = Instance.new("Frame")
stats.Size, stats.Position = UDim2.fromOffset(235, 190), UDim2.fromOffset(18, 95)
stats.BackgroundColor3, stats.BackgroundTransparency = Color3.fromRGB(34, 24, 52), 0.05
stats.Parent = gui
round(stats, 20)
outline(stats, Color3.fromRGB(255, 84, 155), 2)

local statsTitle = Instance.new("TextLabel")
statsTitle.Size, statsTitle.Position = UDim2.new(1, -20, 0, 36), UDim2.fromOffset(10, 8)
statsTitle.BackgroundTransparency, statsTitle.Text = 1, "YOUR TONGUE"
statsTitle.TextColor3, statsTitle.Font, statsTitle.TextScaled = Color3.fromRGB(255, 212, 55), Enum.Font.GothamBlack, true
statsTitle.Parent = stats

local statsText = Instance.new("TextLabel")
statsText.Size, statsText.Position = UDim2.new(1, -24, 1, -54), UDim2.fromOffset(12, 46)
statsText.BackgroundTransparency, statsText.Text = 1, "Loading..."
statsText.TextColor3, statsText.Font, statsText.TextSize = Color3.new(1, 1, 1), Enum.Font.GothamBold, 19
statsText.TextXAlignment, statsText.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
statsText.Parent = stats

local zone = Instance.new("TextLabel")
zone.Size, zone.Position = UDim2.fromOffset(310, 48), UDim2.new(0.5, -155, 0, 92)
zone.BackgroundColor3, zone.BackgroundTransparency = Color3.fromRGB(32, 27, 48), 0.1
zone.Text, zone.TextColor3, zone.Font, zone.TextScaled = "ZONE 1  CANDY MOUTH", Color3.new(1, 1, 1), Enum.Font.GothamBlack, true
zone.Parent = gui
round(zone, 15)

local growth = Instance.new("TextLabel")
growth.Size, growth.Position = UDim2.fromOffset(150, 52), UDim2.new(0.5, -75, 0, 147)
growth.BackgroundTransparency, growth.TextTransparency = 1, 1
growth.Text, growth.TextColor3, growth.Font, growth.TextScaled = "+1 TONGUE", Color3.fromRGB(255, 84, 155), Enum.Font.GothamBlack, true
growth.Parent = gui

local function button(name, text, position, color, size)
	local item = Instance.new("TextButton")
	item.Name, item.Text, item.Position = name, text, position
	item.Size = size or UDim2.fromOffset(215, 58)
	item.AnchorPoint = Vector2.new(1, 1)
	item.BackgroundColor3, item.TextColor3 = color, Color3.new(1, 1, 1)
	item.Font, item.TextScaled, item.AutoButtonColor, item.Parent = Enum.Font.GothamBlack, true, true, gui
	round(item, 17)
	outline(item, Color3.new(1, 1, 1), 2)
	return item
end

local lick = button("Lick", "EXTEND TONGUE", UDim2.new(1, -18, 1, -22), Color3.fromRGB(245, 72, 148), UDim2.fromOffset(230, 66))
local upgrade = button("Upgrade", "UPGRADE GROWTH", UDim2.new(1, -18, 1, -100), Color3.fromRGB(56, 157, 250))
local rebirth = button("Rebirth", "REBIRTH", UDim2.new(1, -18, 1, -170), Color3.fromRGB(148, 76, 244))
local shopButton = button("Shop", "SHOP", UDim2.new(1, -18, 0, 80), Color3.fromRGB(240, 171, 32), UDim2.fromOffset(145, 55))

local crosshair = Instance.new("TextLabel")
crosshair.Size, crosshair.Position = UDim2.fromOffset(46, 46), UDim2.new(0.5, -23, 0.5, -23)
crosshair.BackgroundTransparency, crosshair.Text = 1, "+"
crosshair.TextColor3, crosshair.TextStrokeTransparency = Color3.fromRGB(255, 80, 150), 0
crosshair.Font, crosshair.TextScaled, crosshair.Parent = Enum.Font.GothamBlack, true, gui

local rangeLabel = Instance.new("TextLabel")
rangeLabel.Size, rangeLabel.Position = UDim2.fromOffset(380, 46), UDim2.new(0.5, -190, 1, -55)
rangeLabel.BackgroundColor3, rangeLabel.BackgroundTransparency = Color3.fromRGB(30, 24, 45), 0.15
rangeLabel.Text, rangeLabel.TextColor3 = "Aim at a platform and extend your tongue", Color3.new(1, 1, 1)
rangeLabel.Font, rangeLabel.TextScaled, rangeLabel.Parent = Enum.Font.GothamBold, true, gui
round(rangeLabel, 15)

local message = Instance.new("TextLabel")
message.Size, message.Position = UDim2.fromOffset(520, 68), UDim2.new(0.5, -260, 0.5, 62)
message.BackgroundColor3, message.BackgroundTransparency = Color3.fromRGB(245, 72, 148), 1
message.TextTransparency, message.TextColor3 = 1, Color3.new(1, 1, 1)
message.Font, message.TextScaled, message.Parent = Enum.Font.GothamBlack, true, gui
round(message, 18)

local token = 0
local function announce(text)
	token += 1
	local mine = token
	message.Text = tostring(text)
	TweenService:Create(message, TweenInfo.new(0.16), {BackgroundTransparency = 0.08, TextTransparency = 0}):Play()
	task.delay(2, function()
		if token == mine then TweenService:Create(message, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextTransparency = 1}):Play() end
	end)
end

local shop = Instance.new("Frame")
shop.Size, shop.Position = UDim2.fromOffset(440, 500), UDim2.new(0.5, -220, 0.5, -250)
shop.BackgroundColor3, shop.Visible, shop.Parent = Color3.fromRGB(31, 22, 48), false, gui
round(shop, 22)
outline(shop, Color3.fromRGB(255, 195, 45), 3)

local shopTitle = Instance.new("TextLabel")
shopTitle.Size, shopTitle.Position = UDim2.new(1, -75, 0, 58), UDim2.fromOffset(18, 8)
shopTitle.BackgroundTransparency, shopTitle.Text = 1, "BIG FAT TONGUE SHOP"
shopTitle.TextColor3, shopTitle.Font, shopTitle.TextScaled, shopTitle.Parent = Color3.fromRGB(255, 215, 55), Enum.Font.GothamBlack, true, shop

local close = Instance.new("TextButton")
close.Size, close.Position = UDim2.fromOffset(48, 48), UDim2.new(1, -58, 0, 10)
close.BackgroundColor3, close.Text = Color3.fromRGB(230, 64, 100), "X"
close.TextColor3, close.Font, close.TextScaled, close.Parent = Color3.new(1, 1, 1), Enum.Font.GothamBlack, true, shop
round(close, 14)

local list = Instance.new("ScrollingFrame")
list.Size, list.Position = UDim2.new(1, -28, 1, -82), UDim2.fromOffset(14, 68)
list.BackgroundTransparency, list.BorderSizePixel, list.ScrollBarThickness = 1, 0, 6
list.CanvasSize, list.Parent = UDim2.fromOffset(0, 550), shop
local layout = Instance.new("UIListLayout")
layout.Padding, layout.Parent = UDim.new(0, 10), list

local function product(item, kind, color)
	local card = Instance.new("TextButton")
	card.Size, card.BackgroundColor3 = UDim2.new(1, -10, 0, 82), color
	card.Text = item.Label .. "\n" .. item.Description
	card.TextColor3, card.TextWrapped, card.Font, card.TextSize = Color3.new(1, 1, 1), true, Enum.Font.GothamBold, 15
	card.Parent = list
	round(card, 15)
	card.Activated:Connect(function()
		if item.Id <= 0 then announce("Publish first, then add this item ID") return end
		if kind == "Pass" then MarketplaceService:PromptGamePassPurchase(player, item.Id)
		else MarketplaceService:PromptProductPurchase(player, item.Id) end
	end)
end

product(Shop.GamePasses.VIP, "Pass", Color3.fromRGB(204, 146, 26))
product(Shop.GamePasses.DoubleGrowth, "Pass", Color3.fromRGB(226, 66, 143))
product(Shop.GamePasses.SuperTongue, "Pass", Color3.fromRGB(131, 67, 224))
product(Shop.Products.Clicks500, "Product", Color3.fromRGB(51, 153, 232))
product(Shop.Products.Clicks5000, "Product", Color3.fromRGB(36, 181, 128))
product(Shop.Products.SkipCheckpoint, "Product", Color3.fromRGB(231, 96, 52))

local names = {"Candy Mouth", "Frozen Teeth", "Spicy Throat", "Cosmic Belly", "Golden Escape"}
local function update()
	local values, progress = player:FindFirstChild("leaderstats"), player:FindFirstChild("Progress")
	if not values or not progress then return end
	local amount = progress.GrowthLevel.Value * math.max(1, values.Rebirths.Value + 1)
	if player:GetAttribute("HasDoubleGrowth") then amount *= 2 end
	if player:GetAttribute("HasVIP") then amount = math.max(1, math.floor(amount * 1.5)) end
	statsText.Text = string.format("Tongue  %d studs\nGrowth  +%d every second\nPoints  %d\nWins  %d\nRebirths  %d", values.TongueLength.Value, amount, values.Clicks.Value, values.Wins.Value, values.Rebirths.Value)
	local current = math.clamp(progress.Checkpoint.Value + 1, 1, 5)
	zone.Text = "ZONE " .. current .. "  " .. string.upper(names[current])
	upgrade.Text = "UPGRADE  " .. 250 * progress.GrowthLevel.Value
	rebirth.Text = "REBIRTH  " .. 3000 * (values.Rebirths.Value + 1)
end

task.spawn(function()
	local values, progress = player:WaitForChild("leaderstats"), player:WaitForChild("Progress")
	for _, object in ipairs(values:GetChildren()) do if object:IsA("ValueBase") then object.Changed:Connect(update) end end
	for _, object in ipairs(progress:GetChildren()) do if object:IsA("ValueBase") then object.Changed:Connect(update) end end
	update()
end)

local ready = true
local function extend()
	if not ready or shop.Visible then return end
	ready = false
	task.delay(0.3, function() ready = true end)
	local camera = workspace.CurrentCamera
	if not camera then return end
	local center = camera.ViewportSize * 0.5
	local ray = camera:ViewportPointToRay(center.X, center.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = player.Character and {player.Character} or {}
	local result = workspace:Raycast(ray.Origin, ray.Direction * 10000, params)
	if result then action:FireServer("Slide", result.Position) else announce("Aim directly at a coloured platform") end
end

feedback.OnClientEvent:Connect(function(kind, amount)
	if kind == "Growth" then
		growth.Text = "+" .. tostring(amount) .. " TONGUE"
		growth.Position = UDim2.new(0.5, -75, 0, 147)
		TweenService:Create(growth, TweenInfo.new(0.15), {TextTransparency = 0}):Play()
		TweenService:Create(growth, TweenInfo.new(0.65), {Position = UDim2.new(0.5, -75, 0, 120), TextTransparency = 1}):Play()
	elseif kind == "SlideStart" then
		lick.Text = "SLIDING!"
		local camera = workspace.CurrentCamera
		if camera then TweenService:Create(camera, TweenInfo.new(0.2), {FieldOfView = 78}):Play() end
	elseif kind == "Landed" then
		lick.Text = "EXTEND TONGUE"
		local camera = workspace.CurrentCamera
		if camera then TweenService:Create(camera, TweenInfo.new(0.25), {FieldOfView = 70}):Play() end
	else announce(kind) end
end)

lick.Activated:Connect(extend)
upgrade.Activated:Connect(function() action:FireServer("Upgrade") end)
rebirth.Activated:Connect(function() action:FireServer("Rebirth") end)
shopButton.Activated:Connect(function() shop.Visible = not shop.Visible end)
close.Activated:Connect(function() shop.Visible = false end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonR2 then extend() end
end)

if UserInputService.TouchEnabled then
	rangeLabel.Text = "Aim with the camera, then tap EXTEND TONGUE"
	stats.Size = UDim2.fromOffset(210, 178)
	shop.Size, shop.Position = UDim2.new(1, -30, 0.72, 0), UDim2.new(0, 15, 0.14, 0)
end

RunService.RenderStepped:Connect(function()
	local camera = workspace.CurrentCamera
	local values = player:FindFirstChild("leaderstats")
	if not camera or not values then return end
	local center = camera.ViewportSize * 0.5
	local ray = camera:ViewportPointToRay(center.X, center.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = player.Character and {player.Character} or {}
	local result = workspace:Raycast(ray.Origin, ray.Direction * 10000, params)
	if result and result.Instance:GetAttribute("TongueTarget") then
		local distance = player.Character and player.Character:FindFirstChild("Head") and (result.Position - player.Character.Head.Position).Magnitude or 0
		local range = values.TongueLength.Value + (player:GetAttribute("HasSuperTongue") and 30 or 0)
		crosshair.TextColor3 = distance <= range + 3 and Color3.fromRGB(80, 255, 130) or Color3.fromRGB(255, 75, 90)
		rangeLabel.Text = math.floor(distance) .. " studs away   Your tongue: " .. range
	else
		crosshair.TextColor3 = Color3.fromRGB(255, 80, 150)
		rangeLabel.Text = "Aim at a coloured platform"
	end
end)

]====]
clientScript.Parent = StarterPlayer.StarterPlayerScripts

local lighting = game:GetService("Lighting")
lighting.ClockTime = 14
lighting.Brightness = 2
lighting.Ambient = Color3.fromRGB(115, 105, 145)
lighting.OutdoorAmbient = Color3.fromRGB(170, 170, 190)

print("Cash's Big Fat Tongue Escape version four installed")
print("Grow, extend, slide, land, and escape")
