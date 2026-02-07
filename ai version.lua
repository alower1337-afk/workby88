local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local enabled = true
local autoApply = false
local savedUsername = ""
local savedDisplayName = ""
local savedGameUsername = ""

-- Переменные для полета
local flying = false
local flySpeed = 7
local sprintSpeed = 15
local isSprinting = false
local flyConnection
local bodyVelocity
local bodyGyro
local flyBind = Enum.KeyCode.F
local isSettingBind = false

local channel
pcall(function()
    channel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
end)

-- Объявляем stopFly заранее
local stopFly
local updateFlyBtn

local function clearVisuals(char)
    for _, inst in ipairs(char:GetChildren()) do
        if inst:IsA("Accessory") or inst:IsA("Hat") or inst:IsA("Shirt") 
        or inst:IsA("Pants") or inst:IsA("ShirtGraphic") or inst:IsA("CharacterMesh") then
            inst:Destroy()
        end
    end
    local head = char:FindFirstChild("Head")
    if head then
        for _, d in ipairs(head:GetChildren()) do
            if d:IsA("Decal") and d.Name:lower() == "face" then 
                d:Destroy() 
            end
        end
    end
    local bc = char:FindFirstChildOfClass("BodyColors")
    if bc then bc:Destroy() end
end

local function attachAccessory(char, accessory)
    local handle = accessory:FindFirstChild("Handle")
    if not handle then return end

    local targetAttachment, accAttachment

    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            for _, att in ipairs(part:GetChildren()) do
                if att:IsA("Attachment") then
                    local match = handle:FindFirstChild(att.Name)
                    if match and match:IsA("Attachment") then
                        targetAttachment = att
                        accAttachment = match
                        break
                    end
                end
            end
        end
        if targetAttachment then break end
    end

    if targetAttachment and accAttachment then
        handle.CFrame = targetAttachment.WorldCFrame * accAttachment.CFrame:Inverse()
    else
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then handle.CFrame = root.CFrame end
    end

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = handle
    weld.Part1 = (targetAttachment and targetAttachment.Parent) or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    weld.Parent = handle
    accessory.Parent = char
end

local function applyAppearance(username)
    local char = player.Character
    if not char then return end
    
    local userId
    local ok, result = pcall(function()
        return Players:GetUserIdFromNameAsync(username)
    end)
    
    if not ok or not result then return end
    userId = result
    
    local ok2, model = pcall(function()
        return Players:GetCharacterAppearanceAsync(userId)
    end)
    if not ok2 or not model then return end

    clearVisuals(char)

    local bc = model:FindFirstChildOfClass("BodyColors")
    if bc then bc:Clone().Parent = char end

    for _, item in ipairs(model:GetChildren()) do
        if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
            item:Clone().Parent = char
        end
    end

    for _, acc in ipairs(model:GetChildren()) do
        if acc:IsA("Accessory") or acc:IsA("Hat") then
            attachAccessory(char, acc:Clone())
        end
    end

    local head = char:FindFirstChild("Head")
    if head then
        local face = model:FindFirstChild("face", true)
        if face and face:IsA("Decal") then
            face:Clone().Parent = head
        end
    end
end

local function changeNameTag(displayName, username)
    local char = player.Character
    if not char then return end
    
    local head = char:FindFirstChild("Head")
    if not head then return end
    
    local nameTag = head:FindFirstChild("NameTag")
    if not nameTag then return end
    
    local usernameLabel = nameTag:FindFirstChild("Username")
    local displayLabel = nameTag:FindFirstChild("DisplayName")
    
    if usernameLabel and usernameLabel:IsA("TextLabel") and displayName ~= "" then
        usernameLabel.Text = displayName
    end
    
    if displayLabel and displayLabel:IsA("TextLabel") and username ~= "" then
        local formattedUsername = username
        if not formattedUsername:match("^@") then
            formattedUsername = "@" .. formattedUsername
        end
        displayLabel.Text = formattedUsername
    end
end

-- Функция остановки полета
stopFly = function()
    flying = false
    isSprinting = false
    
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    
    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end
    
    if updateFlyBtn then
        updateFlyBtn()
    end
end

-- Функция начала полета
local function startFly()
    local char = player.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return end
    
    flying = true
    
    -- Создаем BodyVelocity и BodyGyro
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = root
    
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.P = 9e4
    bodyGyro.CFrame = root.CFrame
    bodyGyro.Parent = root
    
    -- Основной цикл полета
    flyConnection = RunService.RenderStepped:Connect(function()
        if not flying or not char or not char.Parent then
            stopFly()
            return
        end
        
        local camera = workspace.CurrentCamera
        local speed = isSprinting and sprintSpeed or flySpeed
        
        -- Получаем направление движения
        local direction = Vector3.new()
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            direction = direction + camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            direction = direction - camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            direction = direction - camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            direction = direction + camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            direction = direction + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            direction = direction - Vector3.new(0, 1, 0)
        end
        
        -- Нормализуем направление
        if direction.Magnitude > 0 then
            direction = direction.Unit
        end
        
        -- Применяем скорость
        bodyVelocity.Velocity = direction * speed * 50
        bodyGyro.CFrame = camera.CFrame
    end)
    
    if updateFlyBtn then
        updateFlyBtn()
    end
end

local function toggleFly()
    if flying then
        stopFly()
    else
        startFly()
    end
end

local gui = Instance.new("ScreenGui")
gui.Name = "DotaNoobChatUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local targetW = 0.22
local targetH = 0.40

local frame = Instance.new("Frame")
frame.Size = UDim2.new(targetW, 0, 0, 0)
frame.Position = UDim2.fromScale(0.5, 0.4)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(18,18,18)
frame.Visible = true
frame.ClipsDescendants = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -10, 0, 22)
title.Position = UDim2.new(0, 5, 0, 4)
title.BackgroundTransparency = 1
title.Text = "рабодай родненькiй чат гпт"
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextColor3 = Color3.fromRGB(255,80,80)
title.TextTransparency = 0
title.Parent = frame

local function label(text, y)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0, 120, 0, 16)
    l.Position = UDim2.new(0, 7, 0, y)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(180, 180, 180)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = frame
    return l
end

local function textbox(placeholder, y, fullWidth)
    local b = Instance.new("TextBox")
    b.Size = fullWidth and UDim2.new(1, -14, 0, 24) or UDim2.new(1, -90, 0, 24)
    b.Position = UDim2.new(0, 7, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(28,28,28)
    b.TextColor3 = Color3.fromRGB(200,200,200)
    b.PlaceholderText = placeholder
    b.Text = ""
    b.Font = Enum.Font.Gotham
    b.TextSize = 11
    b.ClearTextOnFocus = false
    b.Parent = frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    return b
end

local function btn(text, y, w)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w or 75, 0, 24)
    b.Position = UDim2.new(1, -(w or 75) - 7, 0, y)
    b.Text = text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.TextColor3 = Color3.new(1,1,1)
    b.BackgroundColor3 = Color3.fromRGB(60,60,60)
    b.Parent = frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    return b
end

label("Сообщение в чат:", 32)
local msgBox = textbox("workby!88!", 50)

label("Родной DisplayName:", 78)
local nameBox = textbox(player.DisplayName ~= "" and player.DisplayName or player.Name, 96)
nameBox.Text = player.DisplayName ~= "" and player.DisplayName or player.Name

label("Скин (Username):", 124)
local skinUsernameBox = textbox("Username для скина...", 142)

label("DisplayName в игре:", 170)
local displayNameBox = textbox("Новый DisplayName...", 188, true)

label("Username в игре:", 216)
local usernameBox = textbox("Без @...", 234, true)

local testBtn = btn("TEST", 50)
local toggleBtn = btn("ON", 96)
local applySkinBtn = btn("SKIN", 142)

local applyNameBtn = Instance.new("TextButton")
applyNameBtn.Size = UDim2.new(1, -14, 0, 28)
applyNameBtn.Position = UDim2.new(0, 7, 0, 264)
applyNameBtn.Text = "NAME"
applyNameBtn.Font = Enum.Font.GothamBold
applyNameBtn.TextSize = 11
applyNameBtn.TextColor3 = Color3.new(1,1,1)
applyNameBtn.BackgroundColor3 = Color3.fromRGB(60,150,160)
applyNameBtn.Parent = frame
Instance.new("UICorner", applyNameBtn).CornerRadius = UDim.new(0,6)

local autoSkinBtn = Instance.new("TextButton")
autoSkinBtn.Size = UDim2.new(1, -14, 0, 28)
autoSkinBtn.Position = UDim2.new(0, 7, 0, 298)
autoSkinBtn.Text = "AUTO SKIN: OFF"
autoSkinBtn.Font = Enum.Font.GothamBold
autoSkinBtn.TextSize = 11
autoSkinBtn.TextColor3 = Color3.new(1,1,1)
autoSkinBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
autoSkinBtn.Parent = frame
Instance.new("UICorner", autoSkinBtn).CornerRadius = UDim.new(0,6)

-- Кнопка полета (уже)
local flyBtn = Instance.new("TextButton")
flyBtn.Size = UDim2.new(0.48, -7, 0, 32)
flyBtn.Position = UDim2.new(0, 7, 0, 332)
flyBtn.Text = "FLY: OFF"
flyBtn.Font = Enum.Font.GothamBold
flyBtn.TextSize = 11
flyBtn.TextColor3 = Color3.new(1,1,1)
flyBtn.BackgroundColor3 = Color3.fromRGB(80,60,160)
flyBtn.Parent = frame
Instance.new("UICorner", flyBtn).CornerRadius = UDim.new(0,6)

-- Кнопка установки бинда
local bindBtn = Instance.new("TextButton")
bindBtn.Size = UDim2.new(0.48, -7, 0, 32)
bindBtn.Position = UDim2.new(0.52, 0, 0, 332)
bindBtn.Text = "BIND: F"
bindBtn.Font = Enum.Font.GothamBold
bindBtn.TextSize = 11
bindBtn.TextColor3 = Color3.new(1,1,1)
bindBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
bindBtn.Parent = frame
Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0,6)

local function getKeyName(keyCode)
    local keyString = tostring(keyCode):gsub("Enum.KeyCode.", "")
    return keyString
end

local function updateToggle()
    if enabled then
        toggleBtn.BackgroundColor3 = Color3.fromRGB(60,160,80)
        toggleBtn.Text = "ON"
    else
        toggleBtn.BackgroundColor3 = Color3.fromRGB(160,60,60)
        toggleBtn.Text = "OFF"
    end
end
updateToggle()

local function updateAutoSkin()
    if autoApply then
        autoSkinBtn.BackgroundColor3 = Color3.fromRGB(60,160,80)
        autoSkinBtn.Text = "AUTO SKIN: ON"
    else
        autoSkinBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
        autoSkinBtn.Text = "AUTO SKIN: OFF"
    end
end
updateAutoSkin()

updateFlyBtn = function()
    if flying then
        flyBtn.BackgroundColor3 = Color3.fromRGB(60,200,120)
        flyBtn.Text = isSprinting and "SPRINT" or "FLY: ON"
    else
        flyBtn.BackgroundColor3 = Color3.fromRGB(80,60,160)
        flyBtn.Text = "FLY: OFF"
    end
end

local function updateBindBtn()
    if isSettingBind then
        bindBtn.BackgroundColor3 = Color3.fromRGB(200,160,60)
        bindBtn.Text = "PRESS KEY..."
    else
        bindBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
        bindBtn.Text = "BIND: " .. getKeyName(flyBind)
    end
end

toggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    updateToggle()
end)

applySkinBtn.MouseButton1Click:Connect(function()
    local username = skinUsernameBox.Text
    if username ~= "" then
        savedUsername = username
        applyAppearance(username)
    end
end)

autoSkinBtn.MouseButton1Click:Connect(function()
    autoApply = not autoApply
    updateAutoSkin()
end)

applyNameBtn.MouseButton1Click:Connect(function()
    local displayName = displayNameBox.Text
    local username = usernameBox.Text
    
    if displayName ~= "" then 
        savedDisplayName = displayName
    end
    if username ~= "" then 
        savedGameUsername = username
    end
    
    changeNameTag(displayName, username)
end)

flyBtn.MouseButton1Click:Connect(function()
    toggleFly()
end)

bindBtn.MouseButton1Click:Connect(function()
    isSettingBind = true
    updateBindBtn()
end)

local lastSend = 0
local function safeSend(msg)
    if not channel then return end
    local now = tick()
    if now - lastSend < 1 then return end
    lastSend = now
    pcall(function() channel:SendAsync(msg) end)
end

testBtn.MouseButton1Click:Connect(function()
    local m = (msgBox.Text ~= "" and msgBox.Text) or msgBox.PlaceholderText
    safeSend(m)
end)

local dragging, dragStart, startPos
title.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = i.Position
        startPos = frame.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end
end)

local openInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local closeInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local isOpen = false

local function openMenu()
    if isOpen then return end
    isOpen = true
    frame.Visible = true
    TweenService:Create(frame, openInfo, {Size = UDim2.new(targetW, 0, targetH, 0)}):Play()
end

local function closeMenu()
    if not isOpen then return end
    isOpen = false
    TweenService:Create(frame, closeInfo, {Size = UDim2.new(targetW, 0, 0, 0)}):Play()
end

-- Обработка клавиш
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    
    -- Установка бинда
    if isSettingBind then
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            flyBind = input.KeyCode
            isSettingBind = false
            updateBindBtn()
        end
        return
    end
    
    -- Обычные клавиши
    if input.KeyCode == flyBind then
        toggleFly()
    elseif input.KeyCode == Enum.KeyCode.LeftShift and flying then
        isSprinting = true
        updateFlyBtn()
    elseif input.KeyCode == Enum.KeyCode.Insert then
        if isOpen then closeMenu() else openMenu() end
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if gp then return end
    
    if input.KeyCode == Enum.KeyCode.LeftShift and flying then
        isSprinting = false
        updateFlyBtn()
    end
end)

local function trim(s)
    return s:match("^%s*(.-)%s*$") or s
end

local function equalsName(text, target)
    if not text or not target then return false end
    text = trim(tostring(text))
    target = trim(tostring(target))
    if text == "" or target == "" then return false end
    return string.lower(text) == string.lower(target) or 
           string.find(string.lower(text), string.lower(target), 1, true)
end

local function hookKillfeed()
    local success, feed = pcall(function()
        return player:WaitForChild("PlayerGui"):WaitForChild("UI", 5):WaitForChild("Container", 2):WaitForChild("HUD", 2):WaitForChild("Killfeed", 2):WaitForChild("Feed", 2)
    end)
    if not success or not feed then return end
    
    feed.ChildAdded:Connect(function(element)
        if not enabled then return end
        local conns = {}
        
        local function cleanup()
            for _, c in ipairs(conns) do
                if c and c.Disconnect then pcall(function() c:Disconnect() end) end
            end
            conns = {}
        end
        
        for _, desc in ipairs(element:GetDescendants()) do
            if desc:IsA("TextLabel") then
                local targetName = nameBox.Text
                if targetName == "" then
                    targetName = player.DisplayName ~= "" and player.DisplayName or player.Name
                end
                if equalsName(desc.Text, targetName) then
                    local msg = (msgBox.Text ~= "" and msgBox.Text) or msgBox.PlaceholderText
                    safeSend(msg)
                    break
                end
            end
        end
        
        local function onDescAdded(desc)
            if desc:IsA("TextLabel") then
                local conn = desc:GetPropertyChangedSignal("Text"):Connect(function()
                    if not enabled then
                        pcall(function() conn:Disconnect() end)
                        return
                    end
                    local targetName = nameBox.Text
                    if targetName == "" then
                        targetName = player.DisplayName ~= "" and player.DisplayName or player.Name
                    end
                    if equalsName(desc.Text, targetName) then
                        local msg = (msgBox.Text ~= "" and msgBox.Text) or msgBox.PlaceholderText
                        safeSend(msg)
                    end
                end)
                table.insert(conns, conn)
            end
        end
        
        table.insert(conns, element.DescendantAdded:Connect(onDescAdded))
        
        local ancestryConn
        ancestryConn = element.AncestryChanged:Connect(function(_, parent)
            if not parent then
                cleanup()
                if ancestryConn then pcall(function() ancestryConn:Disconnect() end) end
            end
        end)
        table.insert(conns, ancestryConn)
    end)
end

task.spawn(hookKillfeed)

player.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart")
    char:WaitForChild("Head")
    
    -- Останавливаем полет при респауне
    if flying then
        stopFly()
    end
    
    task.wait(0.5)
    
    if autoApply and savedUsername ~= "" then
        applyAppearance(savedUsername)
        if savedDisplayName ~= "" or savedGameUsername ~= "" then
            changeNameTag(savedDisplayName, savedGameUsername)
        end
    end
end)

task.spawn(function()
    while title and title.Parent do
        TweenService:Create(title, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {TextTransparency = 0.85}):Play()
        task.wait(0.6)
        TweenService:Create(title, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {TextTransparency = 0}):Play()
        task.wait(0.6)
    end
end)