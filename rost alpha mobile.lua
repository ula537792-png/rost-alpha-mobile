local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local UI_COLORS = {
    BG = Color3.fromRGB(15, 13, 22),
    TAB_INACTIVE = Color3.fromRGB(25, 20, 36),
    TAB_ACTIVE = Color3.fromRGB(150, 60, 220),
    CHECKBOX_OFF = Color3.fromRGB(35, 28, 50),
    CHECKBOX_ON = Color3.fromRGB(150, 60, 220),
    TEXT = Color3.fromRGB(220, 215, 235),
    VISIBLE = Color3.fromRGB(0, 255, 0),
    HIDDEN = Color3.fromRGB(255, 0, 0),
    NPC_COLOR = Color3.fromRGB(0, 100, 255),
    HEMP_COLOR = Color3.fromRGB(0, 255, 100),
    TRACER = Color3.fromRGB(255, 255, 255)
}

local ORE_COLORS = {
    stone = Color3.fromRGB(169, 169, 169),
    sulfur = Color3.fromRGB(255, 230, 0),
    iron = Color3.fromRGB(180, 80, 40)
}

local CRATE_COLORS = {
    crate = Color3.fromRGB(255, 255, 0),
    foodbox = Color3.fromRGB(0, 255, 0),
    militarycrate = Color3.fromRGB(0, 255, 0),
    toolbox = Color3.fromRGB(255, 0, 0),
    elitecrate = Color3.fromRGB(152, 251, 152),
    airdrop = Color3.fromRGB(255, 0, 0)
}

local Settings = {
    Enabled = {
        Ores = false, Stone = false, Sulfur = false, Iron = false,
        NPCs = false, Hemp = false, 
        VisibleCrate = false, Crate = false, FoodBox = false, MilitaryCrate = false, ToolBox = false, EliteCrate = false, Airdrop = false,
        Aimbot = false, ShowFOV = false,
        Prediction = false,
        Box = false, Chams = false, Name = false, HealthBar = false, HPText = false, Distance = false,
        OffscreenArrows = false,
        IgnoreTransparent = true, WallCheck = false,
        FullBright = false, Spider = false, SpeedHack = false, BulletTracers = false,
        infJump = false, EnableFOV = false, FreeCam = false, Fly = false
    },
    AimTriggerMode = "Automatically", -- Варианты: "Automatically", "Button"
    AutoShootActive = false,
    SpiderActive = false,
    SpeedHackActive = false,
    WallCheckActive = false,
    FreeCamActive = false,
    InfJumpActive = false,
    FlyActive = false,
    AimPart = "Head",
    Smoothing = 0.2,
    Distance = 500,
    AimbotFOV = 300,
    AimbotRange = 500,
    MaxDist = 1000,
    ArrowDist = 2000,
    TextSize = 14,
    BarThickness = 4,
    Transparency = 0.5,
    SpeedMultiplier = 1,
    FlySpeed = 50,
    CurrentSpeed = 1,
    CameraFOV = 70,
    TracerColor = Color3.fromRGB(255, 255, 255)
}

local function isVisible(targetPart)
    if not Settings.WallCheckActive then return true end
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {player.Character, camera}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local rayOrigin = camera.CFrame.Position
    local rayDirection = (targetPart.Position - rayOrigin)

    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

    if raycastResult then
        local hitPart = raycastResult.Instance
        if Settings.Enabled.IgnoreTransparent and (hitPart.Transparency > 0.5 or hitPart:IsA("Terrain") or hitPart:IsA("Decal")) then
            raycastParams.FilterDescendantsInstances = {player.Character, camera, hitPart}
            raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
            if not raycastResult then return true end
        end
        return hitPart:IsDescendantOf(targetPart.Parent)
    end
    return true
end

local function getTargetPart(character)
    return character:FindFirstChild(Settings.AimPart) or character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
end

local function getPrediction(target)
    local targetPart = getTargetPart(target)
    if not targetPart then return target.HumanoidRootPart.Position end
    local basePos = targetPart.Position
    if not Settings.Enabled.Prediction then return basePos end
    local distance = (basePos - camera.CFrame.Position).Magnitude
    local bulletSpeed = 5000 
    local flightTime = distance / bulletSpeed
    local predictedPos = basePos + (target.HumanoidRootPart.Velocity * flightTime)
    local gravityDrop = 0.5 * workspace.Gravity * (flightTime ^ 2)
    return predictedPos + Vector3.new(0, gravityDrop, 0)
end

local function updateOffscreenIndicator(indicator, rootPart)
    local vector, onScreen = camera:WorldToViewportPoint(rootPart.Position)
    if vector.Z < 0 then
        indicator.Visible = false
    else
        indicator.Visible = true
        local screenCenter = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
        local look = (rootPart.Position - camera.CFrame.Position).Unit
        local rel = camera.CFrame:VectorToObjectSpace(look)
        local angle = math.atan2(rel.Y, rel.X)
        indicator.Position = UDim2.new(0, screenCenter.X + math.cos(angle) * 200, 0, screenCenter.Y + math.sin(angle) * 200)
    end
end

local function drawTracer(targetPos)
    local char = player.Character
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    local beam = Instance.new("Beam", workspace.Terrain)
    local a0 = Instance.new("Attachment", workspace.Terrain); a0.Position = rootPart.Position
    local a1 = Instance.new("Attachment", workspace.Terrain); a1.Position = targetPos
    beam.Attachment0 = a0; beam.Attachment1 = a1
    beam.Color = ColorSequence.new(Settings.TracerColor)
    beam.Width0 = 0.05; beam.Width1 = 0.05
    beam.Transparency = NumberSequence.new(0.3)
    task.delay(0.2, function() beam:Destroy(); a0:Destroy(); a1:Destroy() end)
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Inverium"
screenGui.DisplayOrder = 999
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = CoreGui

local uiScale = Instance.new("UIScale", screenGui)
local function updateUIScale()
    local viewportSize = camera.ViewportSize
    local baseResolution = Vector2.new(1280, 720)
    local scaleX = viewportSize.X / baseResolution.X
    local scaleY = viewportSize.Y / baseResolution.Y
    local scale = math.clamp(math.min(scaleX, scaleY), 0.6, 1.2)
    uiScale.Scale = scale
end
updateUIScale()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateUIScale)

local toggleMenuBtn = Instance.new("TextButton", screenGui)
toggleMenuBtn.Size = UDim2.new(0, 100, 0, 40)
toggleMenuBtn.Position = UDim2.new(0, 20, 0, 20)
toggleMenuBtn.BackgroundColor3 = Color3.fromRGB(20, 17, 28)
toggleMenuBtn.TextColor3 = Color3.fromRGB(180, 140, 220)
toggleMenuBtn.Text = "MENU"
toggleMenuBtn.Font = Enum.Font.FredokaOne
toggleMenuBtn.TextSize = 15
toggleMenuBtn.ZIndex = 100
Instance.new("UICorner", toggleMenuBtn).CornerRadius = UDim.new(0, 8)
local toggleStroke = Instance.new("UIStroke", toggleMenuBtn)
toggleStroke.Color = Color3.fromRGB(100, 70, 140)
toggleStroke.Transparency = 0.4
toggleStroke.Thickness = 1

local draggingToggle, dragInputToggle, dragStartToggle, startPosToggle
toggleMenuBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingToggle = true
        dragStartToggle = input.Position
        startPosToggle = toggleMenuBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                draggingToggle = false
            end
        end)
    end
end)

toggleMenuBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInputToggle = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInputToggle and draggingToggle then
        local delta = input.Position - dragStartToggle
        toggleMenuBtn.Position = UDim2.new(startPosToggle.X.Scale, startPosToggle.X.Offset + delta.X, startPosToggle.Y.Scale, startPosToggle.Y.Offset + delta.Y)
    end
end)

local lockedTarget = nil

local resetAimBtn = Instance.new("TextButton", screenGui)
resetAimBtn.Size = UDim2.new(0, 110, 0, 36)
resetAimBtn.Position = UDim2.new(0.5, -55, 0, 20)
resetAimBtn.BackgroundColor3 = Color3.fromRGB(20, 17, 28)
resetAimBtn.TextColor3 = Color3.fromRGB(200, 160, 240)
resetAimBtn.Text = "Reset Aim"
resetAimBtn.Font = Enum.Font.FredokaOne
resetAimBtn.TextSize = 14
resetAimBtn.ZIndex = 100
Instance.new("UICorner", resetAimBtn).CornerRadius = UDim.new(0, 8)
local resetAimStroke = Instance.new("UIStroke", resetAimBtn)
resetAimStroke.Color = Color3.fromRGB(120, 80, 160)
resetAimStroke.Transparency = 0.4
resetAimStroke.Thickness = 1

resetAimBtn.MouseButton1Click:Connect(function()
    lockedTarget = nil
end)

local draggingReset, dragInputReset, dragStartReset, startPosReset
resetAimBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingReset = true
        dragStartReset = input.Position
        startPosReset = resetAimBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                draggingReset = false
            end
        end)
    end
end)

resetAimBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInputReset = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInputReset and draggingReset then
        local delta = input.Position - dragStartReset
        resetAimBtn.Position = UDim2.new(startPosReset.X.Scale, startPosReset.X.Offset + delta.X, startPosReset.Y.Scale, startPosReset.Y.Offset + delta.Y)
    end
end)

local aimButtonActive = false
local screenAimBtn = Instance.new("TextButton", screenGui)
screenAimBtn.Size = UDim2.new(0, 120, 0, 42)
screenAimBtn.Position = UDim2.new(0.5, -60, 0.8, 0)
screenAimBtn.BackgroundColor3 = Color3.fromRGB(20, 17, 28)
screenAimBtn.TextColor3 = Color3.fromRGB(150, 60, 220)
screenAimBtn.Text = "AIM: OFF"
screenAimBtn.Font = Enum.Font.FredokaOne
screenAimBtn.TextSize = 14
screenAimBtn.Visible = false
screenAimBtn.ZIndex = 100
Instance.new("UICorner", screenAimBtn).CornerRadius = UDim.new(0, 8)
local screenAimStroke = Instance.new("UIStroke", screenAimBtn)
screenAimStroke.Color = Color3.fromRGB(150, 60, 220)
screenAimStroke.Transparency = 0.4
screenAimStroke.Thickness = 1.5

screenAimBtn.MouseButton1Click:Connect(function()
    aimButtonActive = not aimButtonActive
    if aimButtonActive then
        screenAimBtn.TextColor3 = Color3.fromRGB(0, 255, 120)
        screenAimBtn.Text = "AIM: ON"
        screenAimStroke.Color = Color3.fromRGB(0, 255, 120)
    else
        screenAimBtn.TextColor3 = Color3.fromRGB(150, 60, 220)
        screenAimBtn.Text = "AIM: OFF"
        screenAimStroke.Color = Color3.fromRGB(150, 60, 220)
        lockedTarget = nil
    end
end)

local draggingAimBtn, dragInputAimBtn, dragStartAimBtn, startPosAimBtn
screenAimBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingAimBtn = true
        dragStartAimBtn = input.Position
        startPosAimBtn = screenAimBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                draggingAimBtn = false
            end
        end)
    end
end)

screenAimBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInputAimBtn = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInputAimBtn and draggingAimBtn then
        local delta = input.Position - dragStartAimBtn
        screenAimBtn.Position = UDim2.new(startPosAimBtn.X.Scale, startPosAimBtn.X.Offset + delta.X, startPosAimBtn.Y.Scale, startPosAimBtn.Y.Offset + delta.Y)
    end
end)

local statusContainer = Instance.new("Frame", screenGui)
statusContainer.Name = "StatusContainer"
statusContainer.Size = UDim2.new(0, 200, 0, 200)
statusContainer.Position = UDim2.new(0, 20, 0, 75)
statusContainer.BackgroundTransparency = 1
statusContainer.ZIndex = 5

local statusLayout = Instance.new("UIListLayout", statusContainer)
statusLayout.Padding = UDim.new(0, 4)
statusLayout.SortOrder = Enum.SortOrder.LayoutOrder

local statusLabels = {}
local function createStatusIndicator(keyName, displayName)
    local label = Instance.new("TextLabel", statusContainer)
    label.Size = UDim2.new(1, 0, 0, 22)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.FredokaOne
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 5
    statusLabels[keyName] = {Label = label, Name = displayName}
end

createStatusIndicator("WallCheckActive", "Wall Check")
createStatusIndicator("SpiderActive", "Spider")
createStatusIndicator("SpeedHackActive", "SpeedHack")
createStatusIndicator("InfJumpActive", "InfJump")
createStatusIndicator("FreeCamActive", "FreeCam")
createStatusIndicator("FlyActive", "Fly")

RunService.RenderStepped:Connect(function()
    for key, data in pairs(statusLabels) do
        local isActive = Settings[key]
        data.Label.Text = data.Name .. ": " .. (isActive and "[ON]" or "[OFF]")
        data.Label.TextColor3 = isActive and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(150, 150, 150)
    end
end)

local welcomeFrame = Instance.new("Frame", screenGui)
welcomeFrame.Size = UDim2.new(0, 350, 0, 100)
welcomeFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
welcomeFrame.AnchorPoint = Vector2.new(0.5, 0.5)
welcomeFrame.BackgroundColor3 = UI_COLORS.BG
welcomeFrame.BorderSizePixel = 0
welcomeFrame.BackgroundTransparency = 1
welcomeFrame.ZIndex = 5

Instance.new("UICorner", welcomeFrame).CornerRadius = UDim.new(0, 12)

local welcomeStroke = Instance.new("UIStroke", welcomeFrame)
welcomeStroke.Color = UI_COLORS.TAB_ACTIVE
welcomeStroke.Transparency = 1
welcomeStroke.Thickness = 1.5

local welcomeText = Instance.new("TextLabel", welcomeFrame)
welcomeText.Size = UDim2.new(1, 0, 1, 0)
welcomeText.Text = "Welcome to Inverium"
welcomeText.TextColor3 = UI_COLORS.TEXT
welcomeText.Font = Enum.Font.FredokaOne
welcomeText.TextSize = 18
welcomeText.BackgroundTransparency = 1
welcomeText.TextTransparency = 1
welcomeText.ZIndex = 6

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 700, 0, 500)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = UI_COLORS.BG
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Visible = false
mainFrame.BackgroundTransparency = 1
mainFrame.ClipsDescendants = true

toggleMenuBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = UI_COLORS.TAB_ACTIVE
mainStroke.Transparency = 1
mainStroke.Thickness = 1.5

local bgContainer = Instance.new("Frame", mainFrame)
bgContainer.Size = UDim2.new(1, 0, 1, 0)
bgContainer.BackgroundTransparency = 1
bgContainer.ZIndex = 0

local function spawnParticle()
    if not mainFrame.Parent then return end
    local p = Instance.new("Frame", bgContainer)
    local size = math.random(4, 8)
    p.Size = UDim2.new(0, size, 0, size)
    local startX = math.random()
    p.Position = UDim2.new(startX, 0, 1.1, 0)
    p.BackgroundColor3 = UI_COLORS.TAB_ACTIVE
    p.BackgroundTransparency = math.random(2, 6) / 10
    p.BorderSizePixel = 0
    p.ZIndex = 1
    Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)
    
    local duration = math.random(3, 6)
    local endX = startX + (math.random() - 0.5) * 0.3
    
    local tween = TweenService:Create(p, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Position = UDim2.new(endX, 0, -0.1, 0),
        BackgroundTransparency = 1
    })
    
    tween:Play()
    tween.Completed:Connect(function()
        p:Destroy()
        spawnParticle()
    end)
end

local function startParticles()
    for i = 1, 15 do
        task.delay(math.random() * 2, spawnParticle)
    end
end

local uiCorner = Instance.new("UICorner", mainFrame)
uiCorner.CornerRadius = UDim.new(0, 12)

local fovCircle = Instance.new("Frame", screenGui)
fovCircle.Name = "FOVCircle"
fovCircle.Size = UDim2.new(0, Settings.AimbotFOV * 2, 0, Settings.AimbotFOV * 2)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
fovCircle.ZIndex = 10
local stroke = Instance.new("UIStroke", fovCircle)
stroke.Color = Color3.new(1, 1, 1)
stroke.Thickness = 2
local corner = Instance.new("UICorner", fovCircle)
corner.CornerRadius = UDim.new(1, 0)

local header = Instance.new("TextLabel", mainFrame)
header.Text = "inverium"
header.Size = UDim2.new(0, 150, 0, 50)
header.Font = Enum.Font.FredokaOne
header.TextSize = 22
header.TextColor3 = UI_COLORS.TAB_ACTIVE
header.BackgroundTransparency = 1
header.ZIndex = 2

local tabs = {"Combat", "Player Visuals", "World Visuals", "Misc"}
local tabContents = {}
local currentTab = "Combat"

local function switchTab(tabName)
    currentTab = tabName
    for name, content in pairs(tabContents) do
        content.Visible = (name == tabName)
    end
    local container = mainFrame:FindFirstChild("TabContainer")
    if container then
        for _, btn in pairs(container:GetChildren()) do
            if btn:IsA("TextButton") then
                btn.BackgroundColor3 = (btn.Text == tabName) and UI_COLORS.TAB_ACTIVE or UI_COLORS.TAB_INACTIVE
            end
        end
    end
end

local tabContainer = Instance.new("Frame", mainFrame)
tabContainer.Name = "TabContainer"
tabContainer.Size = UDim2.new(1, -160, 0, 40)
tabContainer.Position = UDim2.new(0, 150, 0, 5)
tabContainer.BackgroundTransparency = 1
tabContainer.ZIndex = 2

for i, name in ipairs(tabs) do
    local btn = Instance.new("TextButton", tabContainer)
    btn.Size = UDim2.new(1/#tabs, -5, 1, 0)
    btn.Position = UDim2.new((i-1)/#tabs, 0, 0, 0)
    btn.Text = name
    btn.Font = Enum.Font.FredokaOne
    btn.TextColor3 = UI_COLORS.TEXT
    btn.BackgroundColor3 = (name == currentTab) and UI_COLORS.TAB_ACTIVE or UI_COLORS.TAB_INACTIVE
    btn.BorderSizePixel = 0
    btn.ZIndex = 2
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function() switchTab(name) end)

    local scroll = Instance.new("ScrollingFrame", mainFrame)
    scroll.Size = UDim2.new(1, -20, 1, -70)
    scroll.Position = UDim2.new(0, 10, 0, 60)
    scroll.BackgroundTransparency = 1
    scroll.Visible = (name == currentTab)
    scroll.ScrollBarThickness = 6
    scroll.ZIndex = 2
    Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 5)
    Instance.new("UIPadding", scroll).PaddingLeft = UDim.new(0, 10)
    tabContents[name] = scroll
end

local checkboxList = {}

local function createCheckbox(name, parent, settingKey)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, -20, 0, 30)
    container.BackgroundTransparency = 1
    container.ZIndex = 2

    local box = Instance.new("TextButton", container)
    box.Size = UDim2.new(0, 18, 0, 18)
    box.Position = UDim2.new(0, 0, 0, 5)
    box.BackgroundColor3 = Settings.Enabled[settingKey] and UI_COLORS.CHECKBOX_ON or UI_COLORS.CHECKBOX_OFF
    box.Text = ""
    box.ZIndex = 2
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)

    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(1, -30, 1, 0)
    label.Position = UDim2.new(0, 25, 0, 0)
    label.Text = name
    label.TextColor3 = UI_COLORS.TEXT
    label.Font = Enum.Font.FredokaOne
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.ZIndex = 2

    box.MouseButton1Click:Connect(function()
        Settings.Enabled[settingKey] = not Settings.Enabled[settingKey]
        box.BackgroundColor3 = Settings.Enabled[settingKey] and UI_COLORS.CHECKBOX_ON or UI_COLORS.CHECKBOX_OFF
        if settingKey == "ShowFOV" then fovCircle.Visible = Settings.Enabled.ShowFOV end
    end)

    if parent == tabContents["World Visuals"] then
        table.insert(checkboxList, {Box = box, Key = settingKey})
    end
end

local function createActivationButton(parent, labelText, activeKey)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -20, 0, 30)
    btn.Text = labelText .. ": " .. (Settings[activeKey] and "ON" or "OFF")
    btn.BackgroundColor3 = Settings[activeKey] and UI_COLORS.CHECKBOX_ON or UI_COLORS.TAB_INACTIVE
    btn.TextColor3 = UI_COLORS.TEXT
    btn.Font = Enum.Font.FredokaOne
    btn.ZIndex = 2
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    btn.MouseButton1Click:Connect(function()
        Settings[activeKey] = not Settings[activeKey]
        btn.Text = labelText .. ": " .. (Settings[activeKey] and "ON" or "OFF")
        btn.BackgroundColor3 = Settings[activeKey] and UI_COLORS.CHECKBOX_ON or UI_COLORS.TAB_INACTIVE
    end)
end

local function createSlider(name, parent, min, max, settingKey)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, -20, 0, 50)
    container.BackgroundTransparency = 1
    container.ZIndex = 2

    local label = Instance.new("TextLabel", container)
    label.Text = name .. ": " .. string.format("%.2f", Settings[settingKey])
    label.TextColor3 = UI_COLORS.TEXT
    label.Font = Enum.Font.FredokaOne
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.ZIndex = 2

    local bg = Instance.new("Frame", container)
    bg.Size = UDim2.new(1, 0, 0, 10)
    bg.Position = UDim2.new(0, 0, 0, 25)
    bg.BackgroundColor3 = UI_COLORS.CHECKBOX_OFF
    bg.ZIndex = 2
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 5)

    local bar = Instance.new("Frame", bg)
    bar.Size = UDim2.new(math.clamp((Settings[settingKey]-min)/(max-min), 0, 1), 0, 1, 0)
    bar.BackgroundColor3 = UI_COLORS.TAB_ACTIVE
    bar.ZIndex = 2
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 5)

    local dragging = false
    bg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local mousePos = input.Position
            local relativeX = math.clamp(mousePos.X - bg.AbsolutePosition.X, 0, bg.AbsoluteSize.X)
            local percent = relativeX / bg.AbsoluteSize.X
            local rawVal = min + (max - min) * percent
            if settingKey == "Smoothing" then
                Settings[settingKey] = tonumber(string.format("%.2f", rawVal))
            else
                Settings[settingKey] = math.floor(rawVal)
            end
            bar.Size = UDim2.new(percent, 0, 1, 0)
            label.Text = name .. ": " .. (settingKey == "Smoothing" and string.format("%.2f", Settings[settingKey]) or Settings[settingKey])
            if settingKey == "AimbotFOV" then
                fovCircle.Size = UDim2.new(0, Settings.AimbotFOV * 2, 0, Settings.AimbotFOV * 2)
            end
        end
    end)
end

local function createDropdown(name, parent, options, settingKey, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -20, 0, 30)
    btn.Text = name .. ": " .. Settings[settingKey]
    btn.BackgroundColor3 = UI_COLORS.TAB_INACTIVE
    btn.TextColor3 = UI_COLORS.TEXT
    btn.Font = Enum.Font.FredokaOne
    btn.ZIndex = 2
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local index = 1
    for i, opt in ipairs(options) do
        if opt == Settings[settingKey] then index = i break end
    end
    btn.MouseButton1Click:Connect(function()
        index = (index % #options) + 1
        Settings[settingKey] = options[index]
        btn.Text = name .. ": " .. Settings[settingKey]
        if callback then callback(Settings[settingKey]) end
    end)
end

local combatContent = tabContents["Combat"]
createCheckbox("Aimbot", combatContent, "Aimbot")

createDropdown("Aim Trigger", combatContent, {"Automatically", "Button"}, "AimTriggerMode", function(selectedMode)
    if selectedMode == "Automatically" then
        screenAimBtn.Visible = false
        aimButtonActive = false
        screenAimBtn.TextColor3 = Color3.fromRGB(150, 60, 220)
        screenAimBtn.Text = "AIM: OFF"
        screenAimStroke.Color = Color3.fromRGB(150, 60, 220)
    else
        screenAimBtn.Visible = true
    end
end)

createSlider("Smoothing", combatContent, 0.01, 1, "Smoothing")
createCheckbox("Prediction", combatContent, "Prediction")
createDropdown("Aim Part", combatContent, {"Head", "HumanoidRootPart", "Torso"}, "AimPart")
createActivationButton(combatContent, "WallCheck Active", "WallCheckActive")
createCheckbox("Show FOV", combatContent, "ShowFOV")
createSlider("FOV Radius", combatContent, 10, 500, "AimbotFOV")
createSlider("Aimbot Range", combatContent, 50, 2000, "AimbotRange")
createCheckbox("Bullet Tracers", combatContent, "BulletTracers")

local playerContent = tabContents["Player Visuals"]
createCheckbox("Box", playerContent, "Box")
createCheckbox("Chams", playerContent, "Chams")
createCheckbox("Name", playerContent, "Name")
createCheckbox("Health Bar", playerContent, "HealthBar")
createCheckbox("Offscreen Arrows", playerContent, "OffscreenArrows")
createCheckbox("Ignore Transp", playerContent, "IgnoreTransparent")
createCheckbox("Wall Check", playerContent, "WallCheck")
createSlider("Max Distance", playerContent, 100, 5000, "MaxDist")
createSlider("Arrow Distance", playerContent, 100, 5000, "ArrowDist")
createSlider("Text Size", playerContent, 8, 30, "TextSize")

local worldContent = tabContents["World Visuals"]

local enableAllBtn = Instance.new("TextButton", worldContent)
enableAllBtn.Size = UDim2.new(1, -20, 0, 30)
enableAllBtn.BackgroundColor3 = UI_COLORS.TAB_INACTIVE
enableAllBtn.TextColor3 = UI_COLORS.TEXT
enableAllBtn.Text = "Enable All"
enableAllBtn.Font = Enum.Font.FredokaOne
enableAllBtn.ZIndex = 2
Instance.new("UICorner", enableAllBtn).CornerRadius = UDim.new(0, 6)

enableAllBtn.MouseButton1Click:Connect(function()
    for _, item in ipairs(checkboxList) do
        Settings.Enabled[item.Key] = true
        item.Box.BackgroundColor3 = UI_COLORS.CHECKBOX_ON
    end
end)

createCheckbox("Ores", worldContent, "Ores")
createCheckbox("Stone", worldContent, "Stone")
createCheckbox("Sulfur", worldContent, "Sulfur")
createCheckbox("Iron", worldContent, "Iron")
createCheckbox("NPCs", worldContent, "NPCs")
createCheckbox("Hemp", worldContent, "Hemp")
createCheckbox("Visible Crate", worldContent, "VisibleCrate")
createCheckbox("Crate", worldContent, "Crate")
createCheckbox("FoodBox", worldContent, "FoodBox")
createCheckbox("MilitaryCrate", worldContent, "MilitaryCrate")
createCheckbox("ToolBox", worldContent, "ToolBox")
createCheckbox("EliteCrate", worldContent, "EliteCrate")
createCheckbox("Airdrop", worldContent, "Airdrop")
createSlider("Distance", worldContent, 50, 2000, "Distance")

local miscContent = tabContents["Misc"]
createCheckbox("Full Bright", miscContent, "FullBright")
createCheckbox("Enable FOV", miscContent, "EnableFOV")
createSlider("Camera FOV", miscContent, 10, 120, "CameraFOV")
createCheckbox("Spider", miscContent, "Spider")
createActivationButton(miscContent, "Spider Active", "SpiderActive")
createCheckbox("SpeedHack", miscContent, "SpeedHack")
createSlider("Speed Multiplier", miscContent, 1, 10, "SpeedMultiplier")
createActivationButton(miscContent, "SpeedHack Active", "SpeedHackActive")
createCheckbox("infJump", miscContent, "infJump")
createActivationButton(miscContent, "InfJump Active", "infJump")
createCheckbox("FreeCam", miscContent, "FreeCam")
createActivationButton(miscContent, "FreeCam Active", "FreeCamActive")
createCheckbox("Fly", miscContent, "Fly")
createSlider("Fly Speed", miscContent, 10, 200, "FlySpeed")
createActivationButton(miscContent, "Fly Active", "FlyActive")

task.spawn(function()
    local introInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    
    TweenService:Create(welcomeFrame, introInfo, {BackgroundTransparency = 0.05}):Play()
    TweenService:Create(welcomeStroke, introInfo, {Transparency = 0.3}):Play()
    TweenService:Create(welcomeText, introInfo, {TextTransparency = 0}):Play()
    
    task.wait(1.8)
    
    local outroInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(welcomeFrame, outroInfo, {BackgroundTransparency = 1}):Play()
    TweenService:Create(welcomeStroke, outroInfo, {Transparency = 1}):Play()
    TweenService:Create(welcomeText, outroInfo, {TextTransparency = 1}):Play()
    
    task.wait(0.5)
    welcomeFrame:Destroy()
    
    mainFrame.Visible = true
    startParticles()
    
    local mainTweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(mainFrame, mainTweenInfo, {BackgroundTransparency = 0.05}):Play()
    TweenService:Create(mainStroke, mainTweenInfo, {Transparency = 0.3}):Play()
end)

local lastShootTime = 0
local mouse = player:GetMouse()

local espData = {}
local offscreenIndicators = {}

local function createESP(p, isNPC)
    local box = Instance.new("Frame", screenGui); box.Visible = false; box.BackgroundTransparency = 1; box.BorderSizePixel = 1; box.BorderColor3 = Color3.new(1,1,1)
    local hpBg = Instance.new("Frame", box); hpBg.Name = "HPBg"; hpBg.Size = UDim2.new(0, 4, 1, 0); hpBg.Position = UDim2.new(0, -6, 0, 0); hpBg.BackgroundColor3 = Color3.new(0,0,0)
    local hp = Instance.new("Frame", hpBg); hp.Name = "HP"; hp.Size = UDim2.new(1, 0, 0, 0); hp.BackgroundColor3 = Color3.new(0,1,0); hp.AnchorPoint = Vector2.new(0,1); hp.Position = UDim2.new(0,0,1,0)
    local name = Instance.new("TextLabel", box); name.Size = UDim2.new(0, 100, 0, 20); name.Position = UDim2.new(0.5, -50, 0, -25); name.BackgroundTransparency = 1; name.TextColor3 = Color3.new(1,1,1); name.TextStrokeTransparency = 0
    name.TextScaled = true
    local h = Instance.new("Highlight"); h.Enabled = false; h.Adornee = p; h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    espData[p] = {box=box, hpBg=hpBg, hp=hp, name=name, h=h, isNPC=isNPC}

    local indicator = Instance.new("TextLabel", screenGui)
    indicator.Size = UDim2.new(0, 30, 0, 30); indicator.BackgroundTransparency = 1; indicator.Text = "▲"; indicator.TextSize = 25; indicator.Visible = false
    offscreenIndicators[p] = indicator
end

Players.PlayerAdded:Connect(function(p) createESP(p, false) end)
for _, p in pairs(Players:GetPlayers()) do if p ~= player then createESP(p, false) end end

RunService.RenderStepped:Connect(function(dt)
    if Settings.Enabled.FullBright then
        Lighting.Ambient = Color3.new(1, 1, 1); Lighting.Brightness = 2; Lighting.ClockTime = 14
    end

    if Settings.Enabled.EnableFOV then
        camera.FieldOfView = Settings.CameraFOV
    end

    if Settings.Enabled.BulletTracers and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        if tick() - lastShootTime > 0.1 then
            drawTracer(mouse.Hit.Position)
            lastShootTime = tick()
        end
    end

    for target, data in pairs(espData) do
        local char = data.isNPC and target or (target and target.Character)
        local indicator = offscreenIndicators[target]
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            data.box.Visible = false; data.h.Enabled = false; indicator.Visible = false; continue 
        end
        local root = char.HumanoidRootPart
        local hum = char:FindFirstChild("Humanoid")
        local pos, onScreen = camera:WorldToViewportPoint(root.Position)
        local dist = (root.Position - camera.CFrame.Position).Magnitude

        local maxCheckDist = data.isNPC and Settings.Distance or Settings.MaxDist

        if dist <= maxCheckDist and hum then
            if onScreen and pos.Z > 0 then
                data.box.Visible = (data.isNPC and Settings.Enabled.NPCs) or (not data.isNPC and Settings.Enabled.Box)
                local headPos = camera:WorldToViewportPoint((char:FindFirstChild("Head") and char.Head.Position) or (root.Position + Vector3.new(0,2,0)))
                local footPos = camera:WorldToViewportPoint(root.Position - Vector3.new(0,3,0))
                local boxHeight = math.abs(headPos.Y - footPos.Y)
                local boxWidth = boxHeight / 2
                data.box.Size = UDim2.new(0, boxWidth, 0, boxHeight)
                data.box.Position = UDim2.new(0, pos.X - boxWidth/2, 0, pos.Y - boxHeight/2)
                if not data.h.Parent or data.h.Parent ~= char then data.h.Parent = char; data.h.Adornee = char end
                data.h.Enabled = (data.isNPC and Settings.Enabled.NPCs) or (not data.isNPC and Settings.Enabled.Chams)
                if data.isNPC then
                    data.h.FillColor = UI_COLORS.NPC_COLOR
                else
                    data.h.FillColor = isVisible(root) and UI_COLORS.VISIBLE or UI_COLORS.HIDDEN
                end
                data.name.Visible = Settings.Enabled.Name
                data.name.Text = data.isNPC and "NPC" or target.Name
                data.hpBg.Visible = Settings.Enabled.HealthBar
                data.hp.Size = UDim2.new(1, 0, math.clamp(hum.Health / hum.MaxHealth, 0, 1), 0)
                indicator.Visible = false
            else
                data.box.Visible = false
                data.h.Enabled = false
                if not data.isNPC and Settings.Enabled.OffscreenArrows and dist <= Settings.ArrowDist and hum.Health > 0 then
                    updateOffscreenIndicator(indicator, root)
                else
                    indicator.Visible = false
                end
            end
        else
            data.box.Visible = false; data.h.Enabled = false; indicator.Visible = false
        end
    end

    local targetCheckActive = Settings.Enabled.Aimbot
    local triggerAllowed = false

    if targetCheckActive then
        if Settings.AimTriggerMode == "Automatically" then
            triggerAllowed = true
        elseif Settings.AimTriggerMode == "Button" then
            triggerAllowed = aimButtonActive
        end
    end

    if targetCheckActive and triggerAllowed then
        if lockedTarget and lockedTarget.Character then
            local hum = lockedTarget.Character:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 or not lockedTarget.Character:FindFirstChild("HumanoidRootPart") then
                lockedTarget = nil
            end
        else
            lockedTarget = nil
        end

        if not lockedTarget then
            local closest = nil
            local minScore = math.huge
            local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character and getTargetPart(p.Character) and p.Character:FindFirstChildOfClass("Humanoid") and p.Character.Humanoid.Health > 0 then
                    local targetPartRef = getTargetPart(p.Character)
                    local targetPos = getPrediction(p.Character)
                    local pos, onScreen = camera:WorldToViewportPoint(targetPos)
                    local fovDist = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                    local worldDist = (targetPos - camera.CFrame.Position).Magnitude
                    
                    if onScreen and pos.Z > 0 and fovDist < Settings.AimbotFOV and fovDist <= Settings.AimbotRange and isVisible(targetPartRef) then
                        local score = fovDist * 0.4 + worldDist * 0.6
                        if score < minScore then minScore = score; closest = p end
                    end
                end
            end
            lockedTarget = closest
        end

        if lockedTarget and lockedTarget.Character then
            local targetPos = getPrediction(lockedTarget.Character)
            local targetCF = CFrame.new(camera.CFrame.Position, targetPos)
            camera.CFrame = camera.CFrame:Lerp(targetCF, Settings.Smoothing)
        end
    else
        if Settings.AimTriggerMode == "Automatically" then
            lockedTarget = nil
        end
    end
end)

local freeCamAngles = Vector2.new()
local lastMousePos = UserInputService:GetMouseLocation()
RunService.RenderStepped:Connect(function()
    if Settings.Enabled.FreeCam and Settings.FreeCamActive then
        camera.CameraType = Enum.CameraType.Scriptable
        local speed = 1
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then speed = 3 end
        local moveDir = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camera.CFrame.RightVector end
        camera.CFrame = camera.CFrame + (moveDir * speed)

        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local currentMousePos = UserInputService:GetMouseLocation()
            local delta = currentMousePos - lastMousePos
            lastMousePos = currentMousePos
            freeCamAngles = freeCamAngles - Vector2.new(delta.X * 0.003, delta.Y * 0.003)
            freeCamAngles = Vector2.new(freeCamAngles.X, math.clamp(freeCamAngles.Y, -math.rad(89), math.rad(89)))
            camera.CFrame = CFrame.new(camera.CFrame.Position) * CFrame.Angles(0, freeCamAngles.X, 0) * CFrame.Angles(freeCamAngles.Y, 0, 0)
        else
            lastMousePos = UserInputService:GetMouseLocation()
        end

        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
            char.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            char.HumanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            char.Humanoid:Move(Vector3.new(0,0,0), true)
        end
    else
        if camera.CameraType == Enum.CameraType.Scriptable then
            camera.CameraType = Enum.CameraType.Custom
            local rx, ry, rz = camera.CFrame:ToOrientation()
            freeCamAngles = Vector2.new(ry, 0)
        end
        lastMousePos = UserInputService:GetMouseLocation()
    end
end)

task.spawn(function()
    while task.wait(1) do
        local npcFolder = workspace:FindFirstChild("Npc")
        if npcFolder then
            for _, obj in pairs(npcFolder:GetDescendants()) do
                if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
                    if not espData[obj] then
                        createESP(obj, true)
                    end
                end
            end
        end
    end
end)

RunService.Heartbeat:Connect(function(dt)
    if Settings.infJump and (UserInputService:IsKeyDown(Enum.KeyCode.Space)) then
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end

    if Settings.Fly and Settings.FlyActive then
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
            local hrp = char.HumanoidRootPart
            local hum = char.Humanoid
            hum:ChangeState(Enum.HumanoidStateType.Physics)
            local moveDir = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end

            if moveDir.Magnitude > 0 then
                moveDir = moveDir.Unit * Settings.FlySpeed
            end
            hrp.AssemblyLinearVelocity = moveDir
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
    else
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            local hum = player.Character.Humanoid
            if hum:GetState() == Enum.HumanoidStateType.Physics then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end

    if not Settings.FreeCamActive and not (Settings.Fly and Settings.FlyActive) then
        if Settings.Enabled.SpeedHack and Settings.SpeedHackActive and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local hum = player.Character.Humanoid
            local move = hum.MoveDirection
            if move.Magnitude > 0 then
                local velocity = move * (Settings.SpeedMultiplier * 15)
                hrp.AssemblyLinearVelocity = Vector3.new(velocity.X, hrp.AssemblyLinearVelocity.Y, velocity.Z)
            end
        end

        if Settings.Enabled.Spider and Settings.SpiderActive and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local ray = workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 3)
                if ray then hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 30, hrp.AssemblyLinearVelocity.Z) end
            end
        end
    end
end)

local function applyHighlight(obj, color, enabled)
    if not obj then return end
    if obj:IsA("BasePart") or obj:IsA("Model") then
        local targetForHighlight = obj
        if obj:IsA("Model") then
            targetForHighlight = obj:FindFirstChild("tree.002", true) or obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart") or obj
        end

        local h = targetForHighlight:FindFirstChild("ESP_Highlight") or obj:FindFirstChild("ESP_Highlight")
        if enabled then
            if not h then
                h = Instance.new("Highlight")
                h.Name = "ESP_Highlight"
                h.Adornee = targetForHighlight
                h.Parent = targetForHighlight
            end
            h.Enabled = true
            h.FillColor = color
            h.OutlineTransparency = 0.5
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        else
            if h then
                h:Destroy()
            end
        end
    end
end

local function applyBillboard(obj, textName, color, enabled)
    if not obj then return end
    local targetPart = nil

    if obj:IsA("Model") then
        targetPart = obj:FindFirstChild("tree.002", true) or obj:FindFirstChild("ESP_TopAttachment")
        if not targetPart and enabled then
            targetPart = Instance.new("Attachment")
            targetPart.Name = "ESP_TopAttachment"
            local cf, size = obj:GetBoundingBox()
            targetPart.Position = Vector3.new(0, size.Y / 2 + 0.5, 0)
            targetPart.Parent = obj:FindFirstChild("tree.002", true) or obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart") or obj
        end
    elseif obj:IsA("BasePart") then
        targetPart = obj
    end

    if not targetPart then
        if obj:IsA("Model") then
            local existingAtt = obj:FindFirstChild("ESP_TopAttachment", true)
            if existingAtt then existingAtt:Destroy() end
        end
        return
    end

    local bill = targetPart:FindFirstChild("ESP_Billboard")
    if enabled then
        if not bill then
            bill = Instance.new("BillboardGui", targetPart)
            bill.Name = "ESP_Billboard"
            bill.Size = UDim2.new(0, 100, 0, 30)
            bill.StudsOffset = Vector3.new(0, 1, 0)
            bill.AlwaysOnTop = true
            local label = Instance.new("TextLabel", bill)
            label.Name = "Text"
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.FredokaOne
            label.TextStrokeTransparency = 0
            label.TextScaled = true
        end
        local label = bill:FindFirstChild("Text")
        if label then
            label.Text = textName
            label.TextColor3 = color
            label.TextSize = Settings.TextSize
        end
        bill.Enabled = true
    else
        if bill then
            bill:Destroy()
        end
        local existingAtt = obj:IsA("Model") and obj:FindFirstChild("ESP_TopAttachment", true)
        if existingAtt then
            existingAtt:Destroy()
        end
    end
end

local cachedCrates = {}

local function setupCrate(obj)
    if obj:IsA("Model") or obj:IsA("BasePart") then
        cachedCrates[obj] = true
    end
end

local function scanContainerRecursive(parent)
    for _, obj in pairs(parent:GetChildren()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            setupCrate(obj)
        end
        scanContainerRecursive(obj)
    end
end

local cratesContainer = workspace:FindFirstChild("Crates")
if cratesContainer then
    scanContainerRecursive(cratesContainer)
    cratesContainer.DescendantAdded:Connect(function(obj)
        if obj:IsA("Model") or obj:IsA("BasePart") then
            setupCrate(obj)
        end
    end)
    cratesContainer.DescendantRemoving:Connect(function(obj)
        if cachedCrates[obj] then
            local espPart = obj:FindFirstChild("FoodBox_ESP_Part")
            if espPart then espPart:Destroy() end
            applyHighlight(obj, Color3.new(), false)
            applyBillboard(obj, "", Color3.new(), false)
            cachedCrates[obj] = nil
        end
    end)
end

local cachedAirdrops = {}

local function setupAirdrop(obj)
    if obj:IsA("Model") or obj:IsA("BasePart") then
        cachedAirdrops[obj] = true
    end
end

local airdropObj = workspace:FindFirstChild("Airdrop")
if airdropObj then
    setupAirdrop(airdropObj)
end
workspace.ChildAdded:Connect(function(obj)
    if obj.Name == "Airdrop" then
        setupAirdrop(obj)
    end
end)
workspace.ChildRemoved:Connect(function(obj)
    if cachedAirdrops[obj] then
        local espPart = obj:FindFirstChild("Airdrop_ESP_Part")
        if espPart then
            espPart:Destroy()
        end
        cachedAirdrops[obj] = nil
    end
end)

local updateTimer = 0
local frameSkipCounter = 0

local function updateWorldESP(dt)
    updateTimer = updateTimer + dt
    if updateTimer < 0.25 then return end
    updateTimer = 0

    local playerChar = player.Character
    if not playerChar or not playerChar:FindFirstChild("HumanoidRootPart") then return end
    local myPos = playerChar.HumanoidRootPart.Position

    frameSkipCounter = (frameSkipCounter + 1) % 2
    if frameSkipCounter == 0 then
        local oresContainer = workspace:FindFirstChild("ores")
        if oresContainer then
            for _, obj in pairs(oresContainer:GetChildren()) do
                if (obj:IsA("BasePart") or obj:IsA("Model")) then
                    local cf = obj:IsA("Model") and select(1, obj:GetBoundingBox()) or obj.CFrame
                    local objPos = cf.Position
                    if (objPos - myPos).Magnitude <= Settings.Distance then
                        local typeName = string.lower(obj.Name)
                        local enabled = (string.find(typeName, "stone") and Settings.Enabled.Stone) or (string.find(typeName, "sulfur") and Settings.Enabled.Sulfur) or (string.find(typeName, "iron") and Settings.Enabled.Iron)
                        applyHighlight(obj, ORE_COLORS[typeName] or Color3.new(1,1,1), enabled)
                    else
                        applyHighlight(obj, Color3.new(), false)
                    end
                else
                    applyHighlight(obj, Color3.new(), false)
                end
            end
        end

        local hempFolder = workspace:FindFirstChild("Hemp")
        if hempFolder then
            for _, obj in pairs(hempFolder:GetChildren()) do
                if obj.Name == "Hemp" and obj:IsA("Model") then
                    local treePart = obj:FindFirstChild("tree.002", true)
                    if treePart then
                        local objPos = treePart.Position
                        if (objPos - myPos).Magnitude <= Settings.Distance then
                            local enabled = Settings.Enabled.Hemp
                            applyHighlight(obj, UI_COLORS.HEMP_COLOR, enabled)
                            applyBillboard(obj, "cloth", UI_COLORS.HEMP_COLOR, enabled)
                        else
                            applyHighlight(obj, Color3.new(), false)
                            applyBillboard(obj, "", Color3.new(), false)
                        end
                    else
                        applyHighlight(obj, Color3.new(), false)
                        applyBillboard(obj, "", Color3.new(), false)
                    end
                end
            end
        end
    end

    for obj, _ in pairs(cachedAirdrops) do
        if obj and obj.Parent then
            local cf, size = obj:IsA("Model") and obj:GetBoundingBox() or (function() return obj.CFrame, obj.Size end)()
            local objPos = cf.Position

            if (objPos - myPos).Magnitude <= Settings.Distance then
                local enabled = Settings.Enabled.VisibleCrate and Settings.Enabled.Airdrop
                local color = CRATE_COLORS.airdrop

                local espPart = obj:FindFirstChild("Airdrop_ESP_Part")
                if enabled then
                    if not espPart then
                        espPart = Instance.new("Part")
                        espPart.Name = "Airdrop_ESP_Part"
                        espPart.Shape = Enum.PartType.Block
                        espPart.Anchored = true
                        espPart.CanCollide = false
                        espPart.CanQuery = false
                        espPart.CanTouch = false
                        espPart.Transparency = 0
                        espPart.Parent = obj

                        local h = Instance.new("Highlight")
                        h.Name = "ESP_Highlight"
                        h.Adornee = espPart
                        h.Parent = espPart
                        h.FillColor = color
                        h.OutlineTransparency = 0.5
                        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

                        local bill = Instance.new("BillboardGui", espPart)
                        bill.Name = "ESP_Billboard"
                        bill.Size = UDim2.new(0, 100, 0, 30)
                        bill.StudsOffset = Vector3.new(0, 0, 0)
                        bill.AlwaysOnTop = true

                        local label = Instance.new("TextLabel", bill)
                        label.Name = "Text"
                        label.Size = UDim2.new(1, 0, 1, 0)
                        label.BackgroundTransparency = 1
                        label.Font = Enum.Font.FredokaOne
                        label.TextStrokeTransparency = 0
                        label.TextScaled = true
                        label.Text = obj.Name
                        label.TextColor3 = color
                        label.TextSize = Settings.TextSize
                    end

                    espPart.CFrame = cf
                    espPart.Size = Vector3.new(4.5, 3, 4)

                    local bill = espPart:FindFirstChild("ESP_Billboard")
                    if bill then
                        local label = bill:FindFirstChild("Text")
                        if label then
                            label.TextSize = Settings.TextSize
                            label.TextColor3 = color
                            label.Text = obj.Name
                        end
                        bill.Enabled = true
                    end

                    local h = espPart:FindFirstChild("ESP_Highlight")
                    if h then
                        h.Enabled = true
                        h.FillColor = color
                    end
                else
                    if espPart then
                        espPart:Destroy()
                    end
                end
            else
                local espPart = obj:FindFirstChild("Airdrop_ESP_Part")
                if espPart then
                    espPart:Destroy()
                end
                cachedAirdrops[obj] = nil
            end
        end
    end

    for obj, _ in pairs(cachedCrates) do
        if obj and obj.Parent then
            local typeName = string.lower(obj.Name)
            local subEnabled = false
            local color = nil

            if typeName == "foodbox" then
                subEnabled = Settings.Enabled.FoodBox
                color = CRATE_COLORS.foodbox
            elseif typeName == "militarycrate" then
                subEnabled = Settings.Enabled.MilitaryCrate
                color = CRATE_COLORS.militarycrate
            elseif typeName == "toolbox" then
                subEnabled = Settings.Enabled.ToolBox
                color = CRATE_COLORS.toolbox
            elseif typeName == "elitecrate" then
                subEnabled = Settings.Enabled.EliteCrate
                color = CRATE_COLORS.elitecrate
            elseif typeName == "crate" then
                subEnabled = Settings.Enabled.Crate
                color = CRATE_COLORS.crate
            end

            if color then
                local cf, size = obj:IsA("Model") and obj:GetBoundingBox() or (function() return obj.CFrame, obj.Size end)()
                local objPos = cf.Position

                if (objPos - myPos).Magnitude <= Settings.Distance then
                    local enabled = (typeName == "foodbox" and subEnabled) or (Settings.Enabled.VisibleCrate and subEnabled)

                    if typeName == "foodbox" then
                        local espPart = obj:FindFirstChild("FoodBox_ESP_Part")
                        if enabled then
                            if not espPart then
                                espPart = Instance.new("Part")
                                espPart.Name = "FoodBox_ESP_Part"
                                espPart.Shape = Enum.PartType.Block
                                espPart.Anchored = true
                                espPart.CanCollide = false
                                espPart.CanQuery = false
                                espPart.CanTouch = false
                                espPart.Transparency = 0
                                espPart.Parent = obj

                                local h = Instance.new("Highlight")
                                h.Name = "ESP_Highlight"
                                h.Adornee = espPart
                                h.Parent = espPart
                                h.FillColor = color
                                h.OutlineTransparency = 0.5
                                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

                                local bill = Instance.new("BillboardGui", espPart)
                                bill.Name = "ESP_Billboard"
                                bill.Size = UDim2.new(0, 100, 0, 30)
                                bill.StudsOffset = Vector3.new(0, 0, 0)
                                bill.AlwaysOnTop = true

                                local label = Instance.new("TextLabel", bill)
                                label.Name = "Text"
                                label.Size = UDim2.new(1, 0, 1, 0)
                                label.BackgroundTransparency = 1
                                label.Font = Enum.Font.FredokaOne
                                label.TextStrokeTransparency = 0
                                label.TextScaled = true
                                label.Text = obj.Name
                                label.TextColor3 = color
                                label.TextSize = Settings.TextSize
                            end

                            espPart.CFrame = cf
                            espPart.Size = Vector3.new(2.5, 0.5, 2.5)

                            local bill = espPart:FindFirstChild("ESP_Billboard")
                            if bill then
                                local label = bill:FindFirstChild("Text")
                                if label then
                                    label.TextSize = Settings.TextSize
                                    label.TextColor3 = color
                                    label.Text = obj.Name
                                end
                                bill.Enabled = true
                            end

                            local h = espPart:FindFirstChild("ESP_Highlight")
                            if h then
                                h.Enabled = true
                                h.FillColor = color
                            end
                        else
                            if espPart then
                                espPart:Destroy()
                            end
                        end
                    else
                        applyHighlight(obj, color, enabled)
                        applyBillboard(obj, obj.Name, color, enabled)
                    end
                else
                    if typeName == "foodbox" then
                        local espPart = obj:FindFirstChild("FoodBox_ESP_Part")
                        if espPart then espPart:Destroy() end
                    else
                        applyHighlight(obj, Color3.new(), false)
                        applyBillboard(obj, "", Color3.new(), false)
                    end
                end
            end
        end
    end
end

RunService.RenderStepped:Connect(updateWorldESP)
