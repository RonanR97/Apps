local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local Monetization = require(ReplicatedStorage:WaitForChild("MonetizationConfig"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("TongueRemotes")
local actionEvent = remotes:WaitForChild("Action")
local feedbackEvent = remotes:WaitForChild("Feedback")
local camera = workspace.CurrentCamera

local gui = Instance.new("ScreenGui")
gui.Name = "TongueEscapeUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function round(object, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = object
end

local function stroke(object, color, thickness)
	local item = Instance.new("UIStroke")
	item.Color = color
	item.Thickness = thickness
	item.Parent = object
end

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.fromOffset(430, 58)
title.Position = UDim2.new(0.5, -215, 0, 18)
title.BackgroundColor3 = Color3.fromRGB(36, 21, 52)
title.BackgroundTransparency = 0.08
title.Text = "CASH'S BIG FAT TONGUE ESCAPE"
title.TextColor3 = Color3.fromRGB(255, 128, 188)
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.Parent = gui
round(title, 18)
stroke(title, Color3.fromRGB(255, 205, 70), 3)

local statsPanel = Instance.new("Frame")
statsPanel.Size = UDim2.fromOffset(230, 170)
statsPanel.Position = UDim2.fromOffset(18, 92)
statsPanel.BackgroundColor3 = Color3.fromRGB(30, 24, 43)
statsPanel.BackgroundTransparency = 0.08
statsPanel.Parent = gui
round(statsPanel, 18)
stroke(statsPanel, Color3.fromRGB(255, 105, 170), 2)

local statsText = Instance.new("TextLabel")
statsText.Size = UDim2.new(1, -24, 1, -20)
statsText.Position = UDim2.fromOffset(12, 10)
statsText.BackgroundTransparency = 1
statsText.TextColor3 = Color3.new(1, 1, 1)
statsText.TextXAlignment = Enum.TextXAlignment.Left
statsText.TextYAlignment = Enum.TextYAlignment.Top
statsText.Font = Enum.Font.GothamBold
statsText.TextSize = 20
statsText.Parent = statsPanel

local function makeButton(name, text, position, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.fromOffset(210, 56)
	button.Position = position
	button.AnchorPoint = Vector2.new(1, 1)
	button.BackgroundColor3 = color
	button.Text = text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBlack
	button.TextScaled = true
	button.AutoButtonColor = true
	button.Parent = gui
	round(button, 16)
	stroke(button, Color3.new(1, 1, 1), 2)
	return button
end

local tongueButton = makeButton("TongueButton", "LICK + GRAPPLE", UDim2.new(1, -20, 1, -24), Color3.fromRGB(244, 74, 151))
local upgradeButton = makeButton("UpgradeButton", "UPGRADE", UDim2.new(1, -20, 1, -92), Color3.fromRGB(70, 155, 255))
local rebirthButton = makeButton("RebirthButton", "REBIRTH", UDim2.new(1, -20, 1, -160), Color3.fromRGB(145, 80, 240))

local crosshair = Instance.new("TextLabel")
crosshair.Size = UDim2.fromOffset(40, 40)
crosshair.Position = UDim2.new(0.5, -20, 0.5, -20)
crosshair.BackgroundTransparency = 1
crosshair.Text = "+"
crosshair.TextColor3 = Color3.fromRGB(255, 90, 160)
crosshair.TextStrokeTransparency = 0
crosshair.Font = Enum.Font.GothamBlack
crosshair.TextScaled = true
crosshair.Parent = gui

local hint = Instance.new("TextLabel")
hint.Size = UDim2.fromOffset(500, 42)
hint.Position = UDim2.new(0.5, -250, 1, -52)
hint.BackgroundColor3 = Color3.fromRGB(25, 20, 35)
hint.BackgroundTransparency = 0.2
hint.Text = "Aim at a platform and click, tap, or press E"
hint.TextColor3 = Color3.new(1, 1, 1)
hint.Font = Enum.Font.GothamBold
hint.TextScaled = true
hint.Parent = gui
round(hint, 14)

local message = Instance.new("TextLabel")
message.Size = UDim2.fromOffset(520, 64)
message.Position = UDim2.new(0.5, -260, 0.5, 70)
message.BackgroundColor3 = Color3.fromRGB(255, 80, 155)
message.BackgroundTransparency = 1
message.TextTransparency = 1
message.TextColor3 = Color3.new(1, 1, 1)
message.TextStrokeTransparency = 0.5
message.Font = Enum.Font.GothamBlack
message.TextScaled = true
message.Parent = gui
round(message, 18)

local messageToken = 0
local function showMessage(text)
	messageToken += 1
	local token = messageToken
	message.Text = tostring(text)
	TweenService:Create(message, TweenInfo.new(0.15), {BackgroundTransparency = 0.08, TextTransparency = 0}):Play()
	task.delay(2.1, function()
		if token == messageToken then
			TweenService:Create(message, TweenInfo.new(0.35), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
		end
	end)
end
feedbackEvent.OnClientEvent:Connect(showMessage)

local shopButton = Instance.new("TextButton")
shopButton.Name = "ShopButton"
shopButton.Size = UDim2.fromOffset(145, 52)
shopButton.Position = UDim2.new(1, -165, 0, 18)
shopButton.BackgroundColor3 = Color3.fromRGB(255, 190, 35)
shopButton.Text = "🛒 SHOP"
shopButton.TextColor3 = Color3.fromRGB(45, 25, 60)
shopButton.Font = Enum.Font.GothamBlack
shopButton.TextScaled = true
shopButton.Parent = gui
round(shopButton, 16)
stroke(shopButton, Color3.new(1, 1, 1), 2)

local shop = Instance.new("Frame")
shop.Name = "PremiumShop"
shop.Size = UDim2.fromOffset(430, 490)
shop.Position = UDim2.new(0.5, -215, 0.5, -245)
shop.BackgroundColor3 = Color3.fromRGB(31, 22, 48)
shop.Visible = false
shop.Parent = gui
round(shop, 22)
stroke(shop, Color3.fromRGB(255, 193, 50), 3)

local shopTitle = Instance.new("TextLabel")
shopTitle.Size = UDim2.new(1, -70, 0, 55)
shopTitle.Position = UDim2.fromOffset(18, 8)
shopTitle.BackgroundTransparency = 1
shopTitle.Text = "BIG FAT TONGUE SHOP"
shopTitle.TextColor3 = Color3.fromRGB(255, 212, 62)
shopTitle.Font = Enum.Font.GothamBlack
shopTitle.TextScaled = true
shopTitle.Parent = shop

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(46, 46)
close.Position = UDim2.new(1, -55, 0, 9)
close.BackgroundColor3 = Color3.fromRGB(235, 70, 100)
close.Text = "X"
close.TextColor3 = Color3.new(1, 1, 1)
close.Font = Enum.Font.GothamBlack
close.TextScaled = true
close.Parent = shop
round(close, 14)

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -28, 1, -78)
list.Position = UDim2.fromOffset(14, 66)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.CanvasSize = UDim2.fromOffset(0, 540)
list.Parent = shop
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.Parent = list

local function addShopItem(item, itemType, accent)
	local card = Instance.new("TextButton")
	card.Size = UDim2.new(1, -10, 0, 80)
	card.BackgroundColor3 = accent
	card.Text = item.Label .. "\n" .. item.Description
	card.TextColor3 = Color3.new(1, 1, 1)
	card.TextWrapped = true
	card.Font = Enum.Font.GothamBold
	card.TextSize = 15
	card.Parent = list
	round(card, 15)
	stroke(card, Color3.new(1, 1, 1), 1.5)
	card.Activated:Connect(function()
		if item.Id <= 0 then
			showMessage("Publish first, then add this item ID")
			return
		end
		if itemType == "Pass" then
			MarketplaceService:PromptGamePassPurchase(player, item.Id)
		else
			MarketplaceService:PromptProductPurchase(player, item.Id)
		end
	end)
end

addShopItem(Monetization.GamePasses.VIP, "Pass", Color3.fromRGB(210, 148, 25))
addShopItem(Monetization.GamePasses.DoubleGrowth, "Pass", Color3.fromRGB(230, 70, 145))
addShopItem(Monetization.GamePasses.SuperTongue, "Pass", Color3.fromRGB(130, 70, 225))
addShopItem(Monetization.Products.Clicks500, "Product", Color3.fromRGB(55, 155, 235))
addShopItem(Monetization.Products.Clicks5000, "Product", Color3.fromRGB(35, 185, 135))
addShopItem(Monetization.Products.SkipCheckpoint, "Product", Color3.fromRGB(235, 100, 55))

shopButton.Activated:Connect(function() shop.Visible = not shop.Visible end)
close.Activated:Connect(function() shop.Visible = false end)

local function updateStats()
	local stats = player:FindFirstChild("leaderstats")
	local progress = player:FindFirstChild("Progress")
	if not stats or not progress then return end
	local multiplier = progress.ClickLevel.Value * math.max(1, stats.Rebirths.Value + 1)
	statsText.Text = string.format(
		"👅 Tongue  %d studs\n🖱 Clicks  %d\n🏆 Wins  %d\n✨ Rebirths  %d\n⚡ Power  +%d",
		stats.TongueLength.Value,
		stats.Clicks.Value,
		stats.Wins.Value,
		stats.Rebirths.Value,
		multiplier
	)
	upgradeButton.Text = "UPGRADE  " .. (150 * progress.ClickLevel.Value)
	rebirthButton.Text = "REBIRTH  " .. (1000 * (stats.Rebirths.Value + 1))
end

task.spawn(function()
	local stats = player:WaitForChild("leaderstats")
	local progress = player:WaitForChild("Progress")
	for _, value in ipairs(stats:GetChildren()) do
		if value:IsA("ValueBase") then value.Changed:Connect(updateStats) end
	end
	for _, value in ipairs(progress:GetChildren()) do
		if value:IsA("ValueBase") then value.Changed:Connect(updateStats) end
	end
	updateStats()
end)

local ready = true
local function activateTongue()
	if not ready then return end
	ready = false
	task.delay(0.13, function() ready = true end)
	actionEvent:FireServer("Click")

	camera = workspace.CurrentCamera
	if not camera then return end
	local viewport = camera.ViewportSize
	local ray = camera:ViewportPointToRay(viewport.X * 0.5, viewport.Y * 0.5)
	local character = player.Character
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = character and {character} or {}
	local result = workspace:Raycast(ray.Origin, ray.Direction * 2500, params)
	if result then
		actionEvent:FireServer("Grapple", result.Position)
	end
end

tongueButton.Activated:Connect(activateTongue)
upgradeButton.Activated:Connect(function() actionEvent:FireServer("Upgrade") end)
rebirthButton.Activated:Connect(function() actionEvent:FireServer("Rebirth") end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonR2 then
		activateTongue()
	end
end)

if UserInputService.TouchEnabled then
	hint.Text = "Aim with the camera, then tap LICK + GRAPPLE"
else
	tongueButton.Size = UDim2.fromOffset(190, 48)
end
