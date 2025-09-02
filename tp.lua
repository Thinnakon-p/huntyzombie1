-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Local player and character setup
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- Kavo UI Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Teleport GUI", "DarkTheme")

-- State variable for noclip
local noclipEnabled = false

-- TweenInfo for smooth teleportation
local tweenInfo = TweenInfo.new(
    0.8, -- Duration (increased for smoother TP)
    Enum.EasingStyle.Sine,
    Enum.EasingDirection.InOut,
    0,
    false,
    0
)

-- Function to toggle noclip
local function toggleNoclip(state)
    noclipEnabled = state
    if state then
        task.spawn(function()
            while noclipEnabled do
                for _, part in pairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
                RunService.Stepped:Wait()
            end
            -- Re-enable collisions when noclip is turned off
            for _, part in pairs(Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = true
                end
            end
        end)
    end
end

-- Function to teleport to specific coordinates
local function teleportToCoordinates()
    local targetPosition = Vector3.new(31.3162899, -10.5002289, 65.7594833, -0.101184517, 0, -0.994867682, 0, 1, 0, 0.994867682, 0, -0.101184517)
    local success, err = pcall(function()
        -- Enable noclip before starting the teleport
        toggleNoclip(true)
        task.wait(0.1) -- Brief delay to ensure noclip is fully applied
        
        Humanoid.PlatformStand = true -- Disable physics to prevent jitter
        local targetCFrame = CFrame.new(targetPosition)
        local tween = TweenService:Create(HumanoidRootPart, tweenInfo, {CFrame = targetCFrame})
        tween:Play()
        tween.Completed:Wait() -- Wait for tween to complete
        Humanoid.PlatformStand = false
        
        -- Disable noclip after teleporting if it wasn't enabled via toggle
        if not noclipEnabled then
            toggleNoclip(false)
        end
        
        print(string.format("Teleported to: X=%.2f, Y=%.2f, Z=%.2f", targetPosition.X, targetPosition.Y, targetPosition.Z))
    end)
    if not success then
        warn("Teleport failed: " .. tostring(err))
        Humanoid.PlatformStand = false
        toggleNoclip(false) -- Ensure noclip is disabled on failure
    end
end

-- UI setup
local TeleportTab = Window:NewTab("Teleport")
local TeleportSection = TeleportTab:NewSection("Teleport Controls")

TeleportSection:NewButton("Teleport to (96.86, 10.50, -36.75)", "Teleport to specific coordinates", function()
    teleportToCoordinates()
end)

local NoclipTab = Window:NewTab("Noclip")
local NoclipSection = NoclipTab:NewSection("Noclip Controls")

NoclipSection:NewToggle("Enable Noclip", "Toggle noclip (go through everything)", function(state)
    toggleNoclip(state)
end)

-- Handle character respawn
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart", 5)
    Humanoid = newChar:WaitForChild("Humanoid", 5)
    if noclipEnabled then
        toggleNoclip(true) -- Reapply noclip if enabled
    end
end)
