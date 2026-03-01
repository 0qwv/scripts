-- Modern Auto-Sword & Farm Script (STFO Edition + Side-Lock Flanker)
-- Place this in a LocalScript

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Teams = game:GetService("Teams")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

-- // MOVEMENT CONTROL SETUP // --
local PlayerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local Controls = PlayerModule:GetControls()

-- // STATE VARIABLES // --
local scriptRunning = true
local swordEnabled = false
local farmEnabled = false
local jukeEnabled = false 

local attackRange = 8 
local farmDetectRange = 18
local jukeRange = 6.3 -- Fixed 8-stud distance
local currentSide = 1 -- 1 for Right side, -1 for Left side

local startPos = nil
local farmPos = nil

-- // UI SETUP // --
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "QWVSwordGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 180) 
mainFrame.Position = UDim2.new(0.5, -120, 0.4, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.Active = true
mainFrame.Draggable = true 
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

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

-- Helper function to create uniform toggle buttons
local function createToggleRow(name, yOffset)
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

local btnAutoSword = createToggleRow("auto sword", 40)
local btnFarmTime = createToggleRow("farm time (stfo)", 85)
local btnAutoJuke = createToggleRow("auto juke", 130)

-- // LOGIC FUNCTIONS // --
local function getClosestEnemy(customRange)
	local range = customRange or attackRange
	local closestPlayer, shortestDistance = nil, range
	for _, v in pairs(Players:GetPlayers()) do
		if v ~= player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
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
	return closestPlayer
end

local function animateToggle(btn, state)
	local targetColor = state and Color3.fromRGB(0, 170, 127) or Color3.fromRGB(45, 45, 45)
	TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = targetColor}):Play()
	btn.Text = state and "ON" or "OFF"
end

-- // BUTTON CLICKS // --
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

btnAutoJuke.MouseButton1Click:Connect(function()
	jukeEnabled = not jukeEnabled
	animateToggle(btnAutoJuke, jukeEnabled)
	if not jukeEnabled then Controls:Enable() end
end)

-- // MAIN LOOP // --
local mainLoop
mainLoop = RunService.Heartbeat:Connect(function()
	if not scriptRunning then return end
	character = player.Character
	if not character then return end
	hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not hrp or not humanoid then return end

	local tool = character:FindFirstChildOfClass("Tool")
	local activeTarget = nil

	-- 1. Auto Sword
	if swordEnabled and tool then
		activeTarget = getClosestEnemy(attackRange)
		if activeTarget and activeTarget.Character then
			local targetHRP = activeTarget.Character:FindFirstChild("HumanoidRootPart")
			if targetHRP then
				hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(targetHRP.Position.X, hrp.Position.Y, targetHRP.Position.Z))
				tool:Activate()
			end
		end
	end

	-- 2. "Side-Lock" Auto Juke
	if jukeEnabled then
		if tool then
			local jukeTarget = activeTarget or getClosestEnemy(jukeRange + 4)
			
			if jukeTarget and jukeTarget.Character and jukeTarget.Character:FindFirstChild("HumanoidRootPart") then
				local tHRP = jukeTarget.Character.HumanoidRootPart
				local dist = (hrp.Position - tHRP.Position).Magnitude
				
				if dist <= jukeRange + 5 then
					Controls:Disable() -- Take control of movement

					-- Calculate Flank Positions (8 studs to the left and right)
					local leftFlank = (tHRP.CFrame * CFrame.new(-jukeRange, 0, -3)).Position
					local rightFlank = (tHRP.CFrame * CFrame.new(jukeRange, 0, 3)).Position

					-- Check which side is currently closer to us (quickest way)
					local distToLeft = (hrp.Position - leftFlank).Magnitude
					local distToRight = (hrp.Position - rightFlank).Magnitude

					-- Choose the side and "Lock" to it
					local goalPos = (distToLeft < distToRight) and leftFlank or rightFlank
					
					-- Move to the specific side-point
					humanoid:MoveTo(goalPos)
				else
					Controls:Enable()
				end
			else
				Controls:Enable()
			end
		else
			Controls:Enable()
		end
	end

	-- 3. Farm Logic
	if farmEnabled and not (jukeEnabled and tool and getClosestEnemy(jukeRange + 4)) then
		Controls:Enable()
		if startPos and farmPos then
			local targetNearby = getClosestEnemy(farmDetectRange)
			humanoid:MoveTo(targetNearby and startPos or farmPos)
		end
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	scriptRunning = false
	Controls:Enable()
	if mainLoop then mainLoop:Disconnect() end
	screenGui:Destroy()
end)
