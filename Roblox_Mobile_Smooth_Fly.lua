-- Smooth Fly GUI | Roblox Luau
-- For a Roblox experience you control.
-- Place this LocalScript in StarterPlayer > StarterPlayerScripts in Roblox Studio.
-- Uses the mobile joystick for horizontal movement and the camera for steering.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local speed = 60
local flying = false
local vertical = 0

local attachment, linearVelocity, alignOrientation, updateConnection

local function getCharacter()
    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if humanoid and root then
        return character, humanoid, root
    end
end

local gui = Instance.new("ScreenGui")
gui.Name = "MobileFlyGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(220, 235)
panel.Position = UDim2.new(1, -235, 0.35, 0)
panel.BackgroundColor3 = Color3.fromRGB(18, 24, 42)
panel.BorderSizePixel = 0
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 16)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(0, 190, 255)
panelStroke.Thickness = 2
panelStroke.Parent = panel

local function makeButton(text, position, size)
    local button = Instance.new("TextButton")
    button.Size = size
    button.Position = position
    button.Text = text
    button.TextScaled = true
    button.Font = Enum.Font.GothamBold
    button.TextColor3 = Color3.new(1, 1, 1)
    button.BackgroundColor3 = Color3.fromRGB(0, 130, 210)
    button.BorderSizePixel = 0
    button.Parent = panel

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button
    return button
end

local title = makeButton(
    "SMOOTH FLY",
    UDim2.fromOffset(10, 10),
    UDim2.new(1, -20, 0, 35)
)
title.Active = false

local toggleButton = makeButton(
    "ENABLE FLY",
    UDim2.fromOffset(10, 55),
    UDim2.new(1, -20, 0, 40)
)

local slowerButton = makeButton(
    "SPEED -",
    UDim2.fromOffset(10, 105),
    UDim2.fromOffset(95, 35)
)

local fasterButton = makeButton(
    "SPEED +",
    UDim2.fromOffset(115, 105),
    UDim2.fromOffset(95, 35)
)

local upButton = makeButton(
    "HOLD UP",
    UDim2.fromOffset(10, 150),
    UDim2.fromOffset(95, 65)
)

local downButton = makeButton(
    "HOLD DOWN",
    UDim2.fromOffset(115, 150),
    UDim2.fromOffset(95, 65)
)

local function stopFly()
    flying = false
    vertical = 0

    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end

    if linearVelocity then linearVelocity:Destroy(); linearVelocity = nil end
    if alignOrientation then alignOrientation:Destroy(); alignOrientation = nil end
    if attachment then attachment:Destroy(); attachment = nil end

    local _, humanoid = getCharacter()
    if humanoid then
        humanoid.PlatformStand = false
        humanoid.AutoRotate = true
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end

    toggleButton.Text = "ENABLE FLY"
end

local function startFly()
    local _, humanoid, root = getCharacter()
    if not humanoid or not root or humanoid.Health <= 0 then return end

    stopFly()

    _, humanoid, root = getCharacter()
    if not humanoid or not root then return end

    flying = true
    humanoid.AutoRotate = false
    humanoid.PlatformStand = true

    attachment = Instance.new("Attachment")
    attachment.Name = "FlyAttachment"
    attachment.Parent = root

    linearVelocity = Instance.new("LinearVelocity")
    linearVelocity.Name = "FlyLinearVelocity"
    linearVelocity.Attachment0 = attachment
    linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    linearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    linearVelocity.VectorVelocity = Vector3.zero
    linearVelocity.MaxForce = 1000000
    linearVelocity.Parent = root

    alignOrientation = Instance.new("AlignOrientation")
    alignOrientation.Name = "FlyAlignOrientation"
    alignOrientation.Attachment0 = attachment
    alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    alignOrientation.Responsiveness = 12
    alignOrientation.MaxTorque = 1000000
    alignOrientation.Parent = root

    toggleButton.Text = "DISABLE FLY"
    local currentVelocity = Vector3.zero

    updateConnection = RunService.RenderStepped:Connect(function(dt)
        if not flying or not root.Parent or humanoid.Health <= 0 then
            stopFly()
            return
        end

        local camera = workspace.CurrentCamera
        if not camera then return end

        -- Humanoid.MoveDirection is already world-space, so do not rotate it again.
        local move = humanoid.MoveDirection
        local horizontal = Vector3.new(move.X, 0, move.Z)

        -- Camera pitch controls vertical flight while the joystick is moving.
        local look = camera.CFrame.LookVector
        local cameraVertical = look.Y * move.Magnitude
        local target = (horizontal + Vector3.new(0, cameraVertical + vertical, 0)) * speed

        local alpha = 1 - math.exp(-5 * dt)
        currentVelocity = currentVelocity:Lerp(target, alpha)
        linearVelocity.VectorVelocity = currentVelocity

        local flatLook = Vector3.new(look.X, 0, look.Z)
        if flatLook.Magnitude > 0.01 then
            alignOrientation.CFrame = CFrame.lookAt(Vector3.zero, flatLook.Unit)
        end
    end)
end

toggleButton.Activated:Connect(function()
    if flying then
        stopFly()
    else
        startFly()
    end
end)

slowerButton.Activated:Connect(function()
    speed = math.max(20, speed - 10)
    slowerButton.Text = "SPEED - (" .. speed .. ")"
    fasterButton.Text = "SPEED + (" .. speed .. ")"
end)

fasterButton.Activated:Connect(function()
    speed = math.min(150, speed + 10)
    slowerButton.Text = "SPEED - (" .. speed .. ")"
    fasterButton.Text = "SPEED + (" .. speed .. ")"
end)

local function connectHold(button, value)
    local activeInput

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            activeInput = input
            vertical = value
        end
    end)

    button.InputEnded:Connect(function(input)
        if activeInput == input then
            activeInput = nil
            vertical = 0
        end
    end)
end

connectHold(upButton, 1)
connectHold(downButton, -1)

player.CharacterAdded:Connect(function()
    stopFly()
end)

if player.Character then
    player.Character:WaitForChild("Humanoid")
end
