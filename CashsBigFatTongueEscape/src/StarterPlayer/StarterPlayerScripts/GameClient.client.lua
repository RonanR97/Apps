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
	elseif kind == "TongueOut" then
		lick.Text = "EXTENDING..."
		crosshair.TextColor3 = Color3.fromRGB(255, 220, 55)
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
