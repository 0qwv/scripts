-- Modern Auto-Sword Script (Smart Team-Check)
-- Place this in a LocalScript

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Teams = game:GetService("Teams")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

local scriptRunning = true
local enabled = false
local attackRange = 9 

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

Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)

-- // LOGIC // --

local function isFFA()
	local activeTeams = Teams:GetTeams()
	if #activeTeams <= 1 then return true end -- No teams or only 1 team exists
	
	-- Check if everyone currently in game is on the same team
	local firstTeam = nil
	for _, p in pairs(Players:GetPlayers()) do
		if not firstTeam then
			firstTeam = p.Team
		elseif p.Team ~= firstTeam then
			return false -- Found someone on a different team
		end
	end
	return true
end

local function getClosestEnemy()
	local closestPlayer = nil
	local shortestDistance = attackRange
	local ffaMode = isFFA()

	for _, v in pairs(Players:GetPlayers()) do
		if v ~= player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
			-- Logic: Target if it's FFA OR if they are on a different team
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

-- Toggle Action
toggleBtn.MouseButton1Click:Connect(function()
	enabled = not enabled
	local targetColor = enabled and Color3.fromRGB(0, 170, 127) or Color3.fromRGB(45, 45, 45)
	TweenService:Create(toggleBtn, TweenInfo.new(0.3), {BackgroundColor3 = targetColor}):Play()
	toggleBtn.Text = enabled and "ON" or "OFF"
end)

-- Cleanup Function
local function shutdown()
	scriptRunning = false
	screenGui:Destroy()
end

closeBtn.MouseButton1Click:Connect(shutdown)

-- Main Loop
RunService.RenderStepped:Connect(function()
	if not scriptRunning or not enabled then return end
	
	character = player.Character
	if not character then return end
	hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

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
end)
