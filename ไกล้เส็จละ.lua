-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

-- Local player and character setup
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- Kavo UI Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Auto Skill & Smooth TP GUI", "DarkTheme")

-- State variables
local autoSkillEnabled = false
local autoTPEnabled = false
local autofarm = false
local originalCFrame = HumanoidRootPart.CFrame
local lastCFrame = originalCFrame
local infiniteJumpEnabled = false
local flyEnabled = false
local flySpeed = 50
local noclipEnabled = false
local currentFPS = 0
local positionLabel = nil
local fpsLabel = nil

-- TweenInfo for smooth teleportation
local tweenInfo = TweenInfo.new(
    0.8, -- Increased duration for slower TP
    Enum.EasingStyle.Sine,
    Enum.EasingDirection.InOut,
    0,
    false,
    0
)

-- Auto Skill functions
local function fireSkill(skillCode)
    local success, err = pcall(function()
        local args = { buffer.fromstring(skillCode) }
        local ByteNetReliable = ReplicatedStorage:WaitForChild("ByteNetReliable", 5)
        if ByteNetReliable then
            ByteNetReliable:FireServer(unpack(args))
        else
            warn("ByteNetReliable not found for skill: " .. skillCode)
        end
    end)
    if not success then
        warn("Failed to fire skill event: " .. tostring(err))
    end
end

local function autoSkillLoop()
    while autoSkillEnabled do
        fireSkill("\b\003\000") -- Z
        task.wait(0.1)
        fireSkill("\b\005\000") -- X
        task.wait(0.1)
        fireSkill("\b\006\000") -- C
        task.wait(0.1)
        fireSkill("\b\007\000") -- G
        task.wait(0.1)
        fireSkill("\f") -- E
        task.wait(0.1)
    end
end

-- Smooth teleport function using TweenService
local function smoothTeleport(targetCFrame)
    local success, err = pcall(function()
        Humanoid.PlatformStand = true
        local tween = TweenService:Create(HumanoidRootPart, tweenInfo, {CFrame = targetCFrame})
        tween:Play()
        tween.Completed:Wait()
        Humanoid.PlatformStand = false
        lastCFrame = targetCFrame
    end)
    if not success then
        warn("Smooth teleport failed: " .. tostring(err))
        Humanoid.PlatformStand = false
    end
end

-- Auto TP function
local function autoTP()
    local doors = workspace.School.Doors:GetChildren()
    
    if doors[2] and doors[2]:FindFirstChild("Root") then
        smoothTeleport(doors[2].Root.CFrame)
    else
        warn("ไม่พบ doors[2] หรือ doors[2].Root ใน workspace.School.Doors")
        return
    end

    if workspace.School.Doors:FindFirstChild("HallwayDoor") and workspace.School.Doors.HallwayDoor:FindFirstChild("Root") then
        smoothTeleport(workspace.School.Doors.HallwayDoor.Root.CFrame)
    else
        warn("ไม่พบ HallwayDoor หรือ HallwayDoor.Root ใน workspace.School.Doors")
        return
    end

    if doors[3] and doors[3]:FindFirstChild("Root") then
        smoothTeleport(doors[3].Root.CFrame)
    else
        warn("ไม่พบ doors[3] หรือ doors[3].Root ใน workspace.School.Doors")
        return
    end

    if doors[4] and doors[4]:FindFirstChild("Root") then
        smoothTeleport(doors[4].Root.CFrame)
    else
        warn("ไม่พบ doors[4] หรือ doors[4].Root ใน workspace.School.Doors")
        return
    end

    smoothTeleport(originalCFrame)
end

-- Auto Attack function
local function autoAttack()
    local success, err = pcall(function()
        local args = { buffer.fromstring("\b\004\000") }
        local ByteNetReliable = ReplicatedStorage:WaitForChild("ByteNetReliable", 5)
        if ByteNetReliable then
            ByteNetReliable:FireServer(unpack(args))
        else
            warn("ByteNetReliable not found for auto attack")
        end
    end)
    if not success then
        warn("Failed to fire auto attack event: " .. tostring(err))
    end
end

local function getNearbyEntities(range)
    local entities = {}
    local EntityFolder = workspace:WaitForChild("Entities", 10)
    if not EntityFolder then
        warn("EntityFolder not found in workspace")
        return entities
    end
    
    for _, entity in pairs(EntityFolder:GetDescendants()) do
        if entity:IsA("Model") and entity:FindFirstChild("HumanoidRootPart") then
            local entityRoot = entity.HumanoidRootPart
            local entityHumanoid = entity:FindFirstChild("Humanoid")
            local isAlive = entityHumanoid and entityHumanoid.Health > 0 or true
            if isAlive then
                local distance = (HumanoidRootPart.Position - entityRoot.Position).Magnitude
                if distance <= range then
                    table.insert(entities, {
                        Model = entity,
                        Root = entityRoot,
                        Humanoid = entityHumanoid,
                        Distance = distance
                    })
                end
            end
        end
    end
    
    table.sort(entities, function(a, b) return a.Distance < b.Distance end)
    print("Found entities: ", #entities)
    return entities
end

local function attackRoutine()
    while autofarm do
        local entities = getNearbyEntities(300)
        
        if #entities == 0 then
            print("No entities found within range")
            task.wait(1) -- Wait longer if no entities
            continue
        end
        
        local target = entities[1]
        print("Targeting entity: ", target.Model.Name, " at distance: ", target.Distance)
        
        -- Smooth TP to above target
        local targetPos = target.Root.CFrame + Vector3.new(0, 12, 0)
        smoothTeleport(targetPos)
        
        -- Lock position smoothly using RunService
        Humanoid.PlatformStand = true
        local connection
        connection = RunService.Heartbeat:Connect(function()
            if not autofarm then
                connection:Disconnect()
                return
            end
            local isAlive = target.Humanoid and target.Humanoid.Health > 0 or target.Model.Parent ~= nil
            if not isAlive then
                connection:Disconnect()
                return
            end
            HumanoidRootPart.CFrame = CFrame.new(
                target.Root.Position + Vector3.new(0, 8, 0),
                target.Root.Position
            )
        end)
        
        -- Attack loop
        while autofarm do
            local isAlive = target.Humanoid and target.Humanoid.Health > 0 or target.Model.Parent ~= nil
            if not isAlive then
                print("Target", target.Model.Name, "is dead or removed")
                connection:Disconnect()
                Humanoid.PlatformStand = false
                break
            end
            
            autoAttack()
            task.wait(0.1)
        end
        
        Humanoid.PlatformStand = false
    end
end

-- Infinite Jump function
UserInputService.JumpRequest:Connect(function()
    if infiniteJumpEnabled then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Fly function
local flyBodyVelocity = nil
local flyBodyGyro = nil

local function startFly()
    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    flyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBodyVelocity.Parent = HumanoidRootPart

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyBodyGyro.P = 9000
    flyBodyGyro.Parent = HumanoidRootPart

    Humanoid.PlatformStand = true

    task.spawn(function()
        while flyEnabled do
            local moveDirection = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDirection = moveDirection + Workspace.CurrentCamera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDirection = moveDirection - Workspace.CurrentCamera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDirection = moveDirection - Workspace.CurrentCamera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDirection = moveDirection + Workspace.CurrentCamera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDirection = moveDirection + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                moveDirection = moveDirection - Vector3.new(0, 1, 0)
            end

            if moveDirection.Magnitude > 0 then
                moveDirection = moveDirection.Unit * flySpeed
            end

            flyBodyVelocity.Velocity = moveDirection
            flyBodyGyro.CFrame = Workspace.CurrentCamera.CFrame

            task.wait()
        end

        if flyBodyVelocity then flyBodyVelocity:Destroy() end
        if flyBodyGyro then flyBodyGyro:Destroy() end
        Humanoid.PlatformStand = false
    end)
end

-- Noclip function
local function toggleNoclip(state)
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
        end)
    end
end

-- FPS Checker
local lastTime = tick()
local frameCount = 0

RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local currentTime = tick()
    if currentTime - lastTime >= 1 then
        currentFPS = frameCount
        frameCount = 0
        lastTime = currentTime
        if fpsLabel then
            fpsLabel.Text = "Current FPS: " .. tostring(currentFPS)
        end
    end
end)

-- Update Position
RunService.Heartbeat:Connect(function()
    if positionLabel then
        local pos = HumanoidRootPart.Position
        positionLabel.Text = string.format("Current Location: X=%.2f, Y=%.2f, Z=%.2f", pos.X, pos.Y, pos.Z)
    end
end)

-- Improve FPS function
local function improveFPS()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    Lighting.GlobalShadows = false
    Lighting.FogEnd = math.huge
    Lighting.Brightness = 2
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0
    
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Enabled = false
        end
        if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") then
            v.Enabled = false
        end
    end
    
    print("FPS optimizations applied")
end

-- Kavo UI Tabs
local AutoSkillTab = Window:NewTab("Auto Skill")
local AutoSkillSection = AutoSkillTab:NewSection("Auto Skill Controls")

AutoSkillSection:NewToggle("Enable Auto Skill", "Toggle auto skill loop", function(state)
    autoSkillEnabled = state
    if state then
        task.spawn(autoSkillLoop)
    end
end)

local AutoTPTab = Window:NewTab("Auto TP")
local AutoTPSection = AutoTPTab:NewSection("Auto TP Controls")

AutoTPSection:NewButton("Run Auto TP", "Run smooth teleport sequence once", function()
    if not autoTPEnabled then
        autoTPEnabled = true
        task.spawn(function()
            autoTP()
            autoTPEnabled = false
        end)
    end
end)

local AutoAttackTab = Window:NewTab("Auto Farm/Attack")
local AutoAttackSection = AutoAttackTab:NewSection("Auto Farm Controls")

AutoAttackSection:NewToggle("Enable Auto Farm", "Toggle auto farm loop", function(state)
    autofarm = state
    if state then
        task.spawn(attackRoutine)
    end
end)

local InfiniteJumpTab = Window:NewTab("Infinite Jump")
local InfiniteJumpSection = InfiniteJumpTab:NewSection("Infinite Jump Controls")

InfiniteJumpSection:NewToggle("Enable Infinite Jump", "Toggle infinite jump", function(state)
    infiniteJumpEnabled = state
end)

local FlyTab = Window:NewTab("Auto Fly")
local FlySection = FlyTab:NewSection("Fly Controls")

FlySection:NewToggle("Enable Fly", "Toggle fly mode (WASD/Space/Ctrl)", function(state)
    flyEnabled = state
    if state then
        startFly()
    end
end)

FlySection:NewSlider("Fly Speed", "Adjust fly speed", 500, 1, function(value)
    flySpeed = value
end)

local NoclipTab = Window:NewTab("Noclip")
local NoclipSection = NoclipTab:NewSection("Noclip Controls")

NoclipSection:NewToggle("Enable Noclip", "Toggle noclip (go through everything)", function(state)
    noclipEnabled = state
    toggleNoclip(state)
end)

local InfoTab = Window:NewTab("Info")
local InfoSection = InfoTab:NewSection("Position and FPS")

positionLabel = InfoSection:NewLabel("Current Location: Loading...")
fpsLabel = InfoSection:NewLabel("Current FPS: Loading...")

local FPSTab = Window:NewTab("FPS Optimizer")
local FPSSection = FPSTab:NewSection("FPS Controls")

FPSSection:NewButton("Improve FPS", "Apply optimizations for better FPS", function()
    improveFPS()
end)

-- Character respawn handler
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart", 5)
    Humanoid = newChar:WaitForChild("Humanoid", 5)
    originalCFrame = HumanoidRootPart.CFrame
    lastCFrame = originalCFrame
    
    if noclipEnabled then
        toggleNoclip(true)
    end
end)
