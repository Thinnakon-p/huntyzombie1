local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- UI Setup
local screenGui = Instance.new("ScreenGui", Players.LocalPlayer:WaitForChild("PlayerGui"))
screenGui.Name = "AutoTP_UI"

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 200, 0, 150)
mainFrame.Position = UDim2.new(0.5, -100, 0.5, -75)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundTransparency = 1
title.Text = "Auto Teleport Control"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.SourceSansBold

local statusLabel = Instance.new("TextLabel", mainFrame)
statusLabel.Size = UDim2.new(1, 0, 0, 25)
statusLabel.Position = UDim2.new(0, 0, 0, 40)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Disabled"
statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
statusLabel.TextXAlignment = Enum.TextXAlignment.Left

local toggleButton = Instance.new("TextButton", mainFrame)
toggleButton.Size = UDim2.new(1, 0, 0, 35)
toggleButton.Position = UDim2.new(0, 0, 0, 70)
toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
toggleButton.Text = "Enable Auto TP"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSansBold

local closeButton = Instance.new("TextButton", mainFrame)
closeButton.Size = UDim2.new(1, 0, 0, 25)
closeButton.Position = UDim2.new(0, 0, 0, 110)
closeButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
closeButton.Text = "Close"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.SourceSansBold

-- Variables
local isEnabled = false
local currentFollowedPart = nil
local followConnection = nil
local targetPart = nil

-- Functions
local function startFollowing()
    -- Find the target part
    local camera = workspace:FindFirstChild("Camera")
    if not camera then return end
    
    targetPart = camera:FindFirstChild("Part")
    if not targetPart or not targetPart:IsA("BasePart") then
        statusLabel.Text = "Status: Part not found or not a BasePart"
        return
    end
    
    -- Follow the part
    currentFollowedPart = targetPart
    
    followConnection = RunService.RenderStepped:Connect(function()
        local player = Players.LocalPlayer
        if not player or not player.Character then return end
        
        -- Calculate position above the part
        local idealPos = targetPart.CFrame * CFrame.new(0, targetPart.Size.Y/2 + 2, 0)
        
        -- Move towards the ideal position smoothly
        local currPos = player.Character.PrimaryPart.Position
        local direction = (idealPos.Position - currPos).Unit
        
        local speed = 15
        local newPos = currPos + direction * speed
        
        -- Use Lerp for smoother movement
        local smoothNewPos = currPos:Lerp(newPos, 0.1)
        player.Character:SetPrimaryPartCFrame(CFrame.new(smoothNewPos))
    end)
    
    statusLabel.Text = "Status: Enabled"
    toggleButton.Text = "Disable Auto TP"
    print(`Started following part: {targetPart.Name}`)
end

local function stopFollowing()
    if followConnection then
        followConnection:Disconnect()
        followConnection = nil
    end
    currentFollowedPart = nil
    statusLabel.Text = "Status: Disabled"
    toggleButton.Text = "Enable Auto TP"
    print("Stopped following")
end

local function toggleAutoTP()
    if isEnabled then
        stopFollowing()
    else
        startFollowing()
    end
    isEnabled = not isEnabled
end

local function openUI()
    mainFrame.Visible = true
end

local function closeUI()
    mainFrame.Visible = false
end

-- Event connections
toggleButton.MouseButton1Click:Connect(toggleAutoTP)
closeButton.MouseButton1Click:Connect(closeUI)

UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.F1 then
        openUI()
    end
end)

-- Initialize and start
initializeTargets()
startFollowing()

-- Example usage:
-- stopFollowing() -- Stop following
-- startFollowing() -- Start following again
