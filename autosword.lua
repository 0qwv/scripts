-- Modern Auto-Sword & Farm Script (STFO Edition)
-- Place this in a LocalScript

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Teams = game:GetService("Teams")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

-- // STATE VARIABLES // --
local scriptRunning = true
local swordEnabled = false
local farmEnabled = false

local attackRange = 8 
local farmDetectRange = 18

local startPos = nil
local farmPos = nil

-- // UI SETUP // --
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "QWVSwordGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 240, 0, 140) 
mainFrame.Position = UDim2.new(0.5, -120, 0.4, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true 
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

-- X Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 25, 0, 25)
closeBtn.Position = UDim2.new(1, -30, 0, 5)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.TextSize = 24
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "qwv sword script"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

-- Tooltip Popup Box (Hidden by default)
local tooltipBox = Instance.new("Frame")
tooltipBox.Size = UDim2.new(0, 180, 0, 60)
tooltipBox.Position = UDim2.new(1, 5, 0.5, 0)
tooltipBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
tooltipBox.BorderSizePixel = 0
tooltipBox.Visible = false
tooltipBox.ZIndex = 20
tooltipBox.Parent = mainFrame

Instance.new("UICorner", tooltipBox).CornerRadius = UDim.new(0, 6)
local stroke = Instance.new("UIStroke", tooltipBox)
stroke.Color = Color3.fromRGB(60, 60, 60)
stroke.Thickness = 1

local tooltipText = Instance.new("TextLabel")
tooltipText.Size = UDim2.new(0.9, 0, 0.9, 0)
tooltipText.Position = UDim2.new(0.05, 0, 0.05, 0)
tooltipText.BackgroundTransparency = 1
tooltipText.Text = "to use: go really close to the edge of the spawn border but stay inside, and face the outside, then turn it on"
tooltipText.TextColor3 = Color3.fromRGB(200, 200, 200)
tooltipText.TextSize = 11
tooltipText.Font = Enum.Font.Gotham
tooltipText.TextWrapped = true
tooltipText.ZIndex = 21
tooltipText.Parent = tooltipBox

-- Helper function to create uniform toggle buttons
local function createToggleRow(name, yOffset, showHelp)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(0.9, 0, 0, 40)
	container.Position = UDim2.new(0.05, 0, 0, yOffset)
	container.BackgroundTransparency = 1
	container.Parent = mainFrame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.6, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = name
	label.TextColor3 = Color3.fromRGB(200, 200, 200)
	label.TextSize = 13
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container

	if showHelp then
		local helpIcon = Instance.new("TextLabel")
		helpIcon.Size = UDim2.new(0, 16, 0, 16)
		helpIcon.Position = UDim2.new(0, label.TextBounds.X + 5, 0.5, -8)
		helpIcon.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		helpIcon.Text = "?"
		helpIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
		helpIcon.TextSize = 12
		helpIcon.Font = Enum.Font.GothamBold
		helpIcon.Active = true
		helpIcon.Parent = container
		Instance.new("UICorner", helpIcon).CornerRadius = UDim.new(1, 0)

		helpIcon.MouseEnter:Connect(function() tooltipBox.Visible = true end)
		helpIcon.MouseLeave:Connect(function() tooltipBox.Visible = false end)
	end

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 50, 0, 24)
	btn.Position = UDim2.new(1, -50, 0.5, -12)
	btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	btn.Text = "OFF"
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 10
	btn.AutoButtonColor = false
	btn.Parent = container

	Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
	return btn
end

local btnAutoSword = createToggleRow("auto sword", 40, false)
local btnFarmTime = createToggleRow("farm time (stfo)", 85, true)

-- // LOGIC FUNCTIONS // --
local function isFFA()
	local activeTeams = Teams:GetTeams()
	if #activeTeams <= 1 then return true end 
	local firstTeam = nil
	for _, p in pairs(Players:GetPlayers()) do
		if not firstTeam then firstTeam = p.Team
		elseif p.Team ~= firstTeam then return false end
	end
	return true
end

local function getClosestEnemy()
	local closestPlayer, shortestDistance = nil, attackRange
	local ffaMode = isFFA()
	for _, v in pairs(Players:GetPlayers()) do
		if v ~= player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
			if ffaMode or (v.Team ~= player.Team) then
				local targetHum = v.Character:FindFirstChild("Humanoid")
				if targetHum and targetHum.Health > 0 then
					local distance = (hrp.Position - v.Character.HumanoidRootPart.Position).Magnitude
					if distance < shortestDistance then
						closestPlayer = v
						shortestDistance = distance
					end
				end
			end
		end
	end
	return closestPlayer
end

local function isAnyPlayerWithin(radius)
	for _, v in pairs(Players:GetPlayers()) do
		if v ~= player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
			local targetHum = v.Character:FindFirstChild("Humanoid")
			if targetHum and targetHum.Health > 0 then
				if (hrp.Position - v.Character.HumanoidRootPart.Position).Magnitude <= radius then
					return true
				end
			end
		end
	end
	return false
end

-- // CONNECTIONS // --
local function animateToggle(btn, state)
	local targetColor = state and Color3.fromRGB(0, 170, 127) or Color3.fromRGB(45, 45, 45)
	TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = targetColor}):Play()
	btn.Text = state and "ON" or "OFF"
end

btnAutoSword.MouseButton1Click:Connect(function()
	swordEnabled = not swordEnabled
	animateToggle(btnAutoSword, swordEnabled)
end)

btnFarmTime.MouseButton1Click:Connect(function()
	farmEnabled = not farmEnabled
	animateToggle(btnFarmTime, farmEnabled)
	if farmEnabled and hrp then
		startPos = hrp.Position
		farmPos = (hrp.CFrame * CFrame.new(0, 0, -2)).Position 
	end
end)

local mainLoop
mainLoop = RunService.Heartbeat:Connect(function()
	if not scriptRunning then return end
	character = player.Character
	if not character then return end
	hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not hrp or not humanoid then return end

	if farmEnabled and startPos and farmPos then
		if isAnyPlayerWithin(farmDetectRange) then
			humanoid:MoveTo(startPos)
		else
			humanoid:MoveTo(farmPos)
		end
	end

	if swordEnabled then
		local target = getClosestEnemy()
		if target and target.Character then
			local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
			if targetHRP then
				local lookPos = Vector3.new(targetHRP.Position.X, hrp.Position.Y, targetHRP.Position.Z)
				hrp.CFrame = CFrame.lookAt(hrp.Position, lookPos)
				local tool = character:FindFirstChildOfClass("Tool")
				if tool then tool:Activate() end
			end
		end
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	scriptRunning = false
	if mainLoop then mainLoop:Disconnect() end
	screenGui:Destroy()
end)
