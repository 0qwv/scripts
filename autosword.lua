-- Modern Auto-Sword Script
-- Place this in a LocalScript

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

-- // UI SETUP // --
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "QWVSwordGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 220, 0, 100)
mainFrame.Position = UDim2.new(0.5, -110, 0.4, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 10)
uiCorner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "qwv sword script"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

local container = Instance.new("Frame")
container.Size = UDim2.new(0.9, 0, 0, 40)
container.Position = UDim2.new(0.05, 0, 0.5, 0)
container.BackgroundTransparency = 1
container.Parent = mainFrame

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0.6, 0, 1, 0)
label.BackgroundTransparency = 1
label.Text = "auto sword"
label.TextColor3 = Color3.fromRGB(200, 200, 200)
label.TextSize = 14
label.Font = Enum.Font.Gotham
label.TextXAlignment = Enum.TextXAlignment.Left
label.Parent = container

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 50, 0, 24)
toggleBtn.Position = UDim2.new(1, -55, 0.5, -12)
toggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
toggleBtn.Text = "OFF"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 10
toggleBtn.AutoButtonColor = false
toggleBtn.Parent = container

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(1, 0)
btnCorner.Parent = toggleBtn

-- // STATE & LOGIC // --
local enabled = false
local attackRange = 15 -- Adjust range here

local function getClosestEnemy()
	local closestPlayer = nil
	local shortestDistance = attackRange

	for _, v in pairs(Players:GetPlayers()) do
		if v ~= player and v.Team ~= player.Team and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
			if v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
				local distance = (hrp.Position - v.Character.HumanoidRootPart.Position).Magnitude
				if distance < shortestDistance then
					closestPlayer = v
					shortestDistance = distance
				end
			end
		end
	end
	return closestPlayer
end

-- Toggle Animation
toggleBtn.MouseButton1Click:Connect(function()
	enabled = not enabled
	
	local targetColor = enabled and Color3.fromRGB(0, 170, 127) or Color3.fromRGB(45, 45, 45)
	local targetText = enabled and "ON" or "OFF"
	
	TweenService:Create(toggleBtn, TweenInfo.new(0.3), {BackgroundColor3 = targetColor}):Play()
	toggleBtn.Text = targetText
end)

-- Main Loop
RunService.RenderStepped:Connect(function()
	if not enabled then return end
	
	-- Refresh Character Ref
	character = player.Character
	if not character then return end
	hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local target = getClosestEnemy()
	
	if target and target.Character then
		local targetHRP = target.Character.HumanoidRootPart
		
		-- 1. Rotate to face target (Horizontal Axis Only)
		local lookPos = Vector3.new(targetHRP.Position.X, hrp.Position.Y, targetHRP.Position.Z)
		hrp.CFrame = CFrame.lookAt(hrp.Position, lookPos)
		
		-- 2. Use Sword
		local tool = character:FindFirstChildOfClass("Tool")
		if tool then
			tool:Activate()
		end
	end
end)
