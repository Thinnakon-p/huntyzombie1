local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Variables
local currentFollowedPart = nil
local followConnection = nil
local targetIndices = {6, 7, 8, 9, 10, 11, 12, 13}
local currentTargetIndex = 1
local targetParts = {}

-- Functions
local function initializeTargets()
    local camera = workspace:FindFirstChild("Camera")
    if not camera then return end
    
    targetParts = {}
    for i = 1, #targetIndices do
        local idx = targetIndices[i]
        local part = camera:GetChildren()[idx]
        if part and part:IsA("BasePart") then
            table.insert(targetParts, part)
        end
    end
    
    print(`Initialized {#targetParts} target parts`)
end

local function startFollowing()
    if #targetParts == 0 then
        print("No target parts available")
        return
    end
    
    -- Follow the first available part
    currentFollowedPart = targetParts[1]
    
    followConnection = RunService.RenderStepped:Connect(function()
        local player = Players.LocalPlayer
        if player and player.Character then
            local pos = currentFollowedPart.CFrame * CFrame.new(0, currentFollowedPart.Size.Y/2 + 2, 0)
            player.Character:MoveTo(pos.Position)
        end
    end)
    
    print(`Started following part: {currentFollowedPart.Name}`)
end

local function stopFollowing()
    if followConnection then
        followConnection:Disconnect()
        followConnection = nil
    end
    currentFollowedPart = nil
    print("Stopped following")
end

-- Check if followed part still exists every second
RunService.Stepped:Connect(function()
    if not currentFollowedPart then return end
    
    -- Check if part still exists in the scene
    if not currentFollowedPart:IsDescendantOf(workspace) then
        print(`Part "{currentFollowedPart.Name}" disappeared! Stopping follow.`)
        stopFollowing()
        
        -- Try to follow next available part
        if #targetParts > 1 then
            table.remove(targetParts, 1) -- Remove the lost part
            startFollowing() -- Start following the new first part
        else
            print("No more parts to follow")
        end
    end
end)

-- Initialize and start
initializeTargets()
startFollowing()

-- Example usage:
-- stopFollowing() -- Stop following
-- initializeTargets() -- Re-initialize targets
-- startFollowing() -- Start following again
