local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Variables
local currentFollowedPart = nil
local followConnection = nil
local autoSkillConnection = nil
local isAutoSkillEnabled = false
local targetIndices = {6, 7, 8, 9, 10, 11, 12, 13}
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
    
    currentFollowedPart = targetParts[1]
    
    followConnection = RunService.RenderStepped:Connect(function()
        local player = Players.LocalPlayer
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local offset = CFrame.new(0, currentFollowedPart.Size.Y/2 + 2, 0)
            hrp.CFrame = currentFollowedPart.CFrame * offset
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

local function getTargetPart()
    local camera = workspace:FindFirstChild("Camera")
    if not camera then return nil end
    local part = camera:FindFirstChild("Part")
    if part and part:IsA("BasePart") then return part end
    return nil
end

local function teleportToPart()
    local targetPart = getTargetPart()
    if not targetPart then
        print("Part not found in Camera or not a BasePart")
        return
    end
    
    local player = Players.LocalPlayer
    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = player.Character.HumanoidRootPart
        local offset = CFrame.new(0, targetPart.Size.Y/2 + 2, 0)
        hrp.CFrame = targetPart.CFrame * offset
        print(`Teleported to above {targetPart.Name}`)
    else
        print("Player or character not found")
    end
end

local function startAutoSkill()
    if autoSkillConnection then
        print("Auto-Skill already running")
        return
    end
    
    isAutoSkillEnabled = true
    autoSkillConnection = RunService.RenderStepped:Connect(function()
        local targetPart = getTargetPart()
        if not targetPart then
            print("Auto-Skill: Part not found, stopping auto-skill")
            stopAutoSkill()
            return
        end
        
        local player = Players.LocalPlayer
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local offset = CFrame.new(0, targetPart.Size.Y/2 + 2, 0)
            hrp.CFrame = targetPart.CFrame * offset -- ตำแหน่งตามเป้าหมาย
            
            -- เรียกใช้ Auto Attack (สมมติว่าเชื่อมโยงกับ HZWeapon)
            local ReplicatedFirst = game:GetService("ReplicatedFirst")
            local HZWeapon = ReplicatedFirst.GameCore:WaitForChild("HZWeapon", 10)
            if HZWeapon then
                local weaponHandlerFunc = require(HZWeapon)
                local weaponHandler = weaponHandlerFunc.new(player, "Bat", {
                    functions = {},
                    combatProperties = {animations = {toolslash = "ChefAttack1"}, abilityData = "YourAbilityData"}
                }, workspace.CallSeo594.Bat)
                if weaponHandler and weaponHandler:activate({
                    localPlayer = player,
                    localCharacter = player.Character,
                    charRootPart = hrp
                }) then
                    local ReplicatedStorage = game:GetService("ReplicatedStorage")
                    local ReplicaSetValues = ReplicatedStorage:WaitForChild("ReplicaSetValues", 10)
                    if ReplicaSetValues then
                        ReplicaSetValues:FireServer({
                            targetId = targetPart.Name,
                            damage = 10,
                            time = workspace:GetServerTimeNow()
                        })
                    end
                end
            end
        end
    end)
    
    print("Started auto-skill on Part")
end

local function stopAutoSkill()
    if autoSkillConnection then
        autoSkillConnection:Disconnect()
        autoSkillConnection = nil
    end
    isAutoSkillEnabled = false
    print("Stopped auto-skill")
end

local function startFollowingPart()
    stopFollowing()
    local targetPart = getTargetPart()
    if not targetPart then
        print("Part not found")
        return
    end
    
    currentFollowedPart = targetPart
    
    followConnection = RunService.RenderStepped:Connect(function()
        local tp = getTargetPart()
        local player = Players.LocalPlayer
        if not tp or not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
        local hrp = player.Character.HumanoidRootPart
        local offset = CFrame.new(0, tp.Size.Y/2 + 2, 0)
        hrp.CFrame = tp.CFrame * offset
    end)
    
    print(`Started following Part`)
end

local function checkPartExists()
    local targetPart = getTargetPart()
    if targetPart then
        print("workspace.Camera.Part exists!")
        initializeTargets()
        print(`There are {#targetParts} additional indexed parts available.`)
    else
        print("workspace.Camera.Part does not exist.")
    end
end

-- Check if followed part still exists
RunService.Stepped:Connect(function()
    if not currentFollowedPart then return end
    
    if not currentFollowedPart:IsDescendantOf(workspace) then
        print(`Part "{currentFollowedPart.Name}" disappeared! Stopping follow.`)
        stopFollowing()
        
        if #targetParts > 1 then
            table.remove(targetParts, 1)
            startFollowing()
        else
            print("No more parts to follow")
        end
    end
end)

-- Initialize and execute
initializeTargets()
teleportToPart()  -- Perform initial TP
startAutoSkill()  -- Start auto-skill loop after initial TP

-- Example usage:
-- teleportToPart()
-- startAutoSkill()
-- stopAutoSkill()
-- startFollowingPart()
-- checkPartExists()
