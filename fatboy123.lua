local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local enabled = true
local autoApply = false
local savedUsername = ""
local savedDisplayName = ""
local savedGameUsername = ""

local channel
pcall(function()
    channel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
end)

-- Функции смены скина
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
            if d:IsA("Decal") and d.Name:lower() == "face" then d:Destroy() end
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
        if root then
            handle.CFrame = root.CFrame
        end
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
    
    if not ok or not result then 
        return 
    end
    
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

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "DotaNoobChatUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local targetWidthScale = 0.22
local targetHeightScale = 0.32

local frame = Instance.new("Frame")
frame.Size = UDim2.new(targetWidthScale, 0, 0, 0)
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
title.Text = "DotaNoob!88! v1 (Тело не ставится)"
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextColor3 = Color3.fromRGB(255,80,80)
title.TextTransparency = 0
title.Parent = frame

local function makeLabel(text, yPos)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 120, 0, 16)
    lbl.Position = UDim2.new(0, 7, 0, yPos)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame
    return lbl
end

local function makeTextBox(placeholder, yPos)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -90, 0, 24)
    box.Position = UDim2.new(0, 7, 0, yPos)
    box.BackgroundColor3 = Color3.fromRGB(28,28,28)
    box.TextColor3 = Color3.fromRGB(200,200,200)
    box.PlaceholderText = placeholder
    box.Text = ""
    box.Font = Enum.Font.Gotham
    box.TextSize = 11
    box.ClearTextOnFocus = true
    box.Parent = frame
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,6)
    return box
end

local function makeButton(text, yPos, width)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, width or 75, 0, 24)
    b.Position = UDim2.new(1, -(width or 75) - 7, 0, yPos)
    b.Text = text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.TextColor3 = Color3.new(1,1,1)
    b.BackgroundColor3 = Color3.fromRGB(60,60,60)
    b.Parent = frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    return b
end

-- Поле 1: Сообщение в чат
makeLabel("Сообщение в чат:", 32)
local msgBox = makeTextBox("workby!88!", 50)

-- Поле 2: DisplayName
makeLabel("Родной DisplayName:", 78)
local nameBox = makeTextBox(player.DisplayName ~= "" and player.DisplayName or player.Name, 96)

-- Поле 3: Скин
makeLabel("Скин (Username):", 124)
local skinUsernameBox = makeTextBox("Username для скина...", 142)

-- Поле 4: DisplayName в игре (БЕЗ @)
makeLabel("DisplayName в игре:", 170)
local displayNameBox = Instance.new("TextBox")
displayNameBox.Size = UDim2.new(1, -14, 0, 24)
displayNameBox.Position = UDim2.new(0, 7, 0, 188)
displayNameBox.BackgroundColor3 = Color3.fromRGB(28,28,28)
displayNameBox.TextColor3 = Color3.fromRGB(200,200,200)
displayNameBox.PlaceholderText = "Новый DisplayName..."
displayNameBox.Text = ""
displayNameBox.Font = Enum.Font.Gotham
displayNameBox.TextSize = 11
displayNameBox.ClearTextOnFocus = true
displayNameBox.Parent = frame
Instance.new("UICorner", displayNameBox).CornerRadius = UDim.new(0,6)

-- Поле 5: Username в игре (С @)
makeLabel("Username в игре:", 216)
local usernameBox = Instance.new("TextBox")
usernameBox.Size = UDim2.new(1, -14, 0, 24)
usernameBox.Position = UDim2.new(0, 7, 0, 234)
usernameBox.BackgroundColor3 = Color3.fromRGB(28,28,28)
usernameBox.TextColor3 = Color3.fromRGB(200,200,200)
usernameBox.PlaceholderText = "Без @..."
usernameBox.Text = ""
usernameBox.Font = Enum.Font.Gotham
usernameBox.TextSize = 11
usernameBox.ClearTextOnFocus = true
usernameBox.Parent = frame
Instance.new("UICorner", usernameBox).CornerRadius = UDim.new(0,6)

-- Кнопки справа
local testBtn = makeButton("TEST", 50)
local toggleBtn = makeButton("ON", 96)
local applySkinBtn = makeButton("SKIN", 142)

-- Кнопка NAME на всю ширину под полями
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

-- Кнопка AUTO внизу на всю ширину
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

-- Обновление цвета кнопок
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

-- Обработчики кнопок
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

local lastSend = 0
local SEND_COOLDOWN = 1
local function safeSend(message)
    if not channel then return end
    local now = tick()
    if now - lastSend < SEND_COOLDOWN then return end
    lastSend = now
    pcall(function()
        channel:SendAsync(message)
    end)
end

testBtn.MouseButton1Click:Connect(function()
    local m = (msgBox.Text ~= "" and msgBox.Text) or msgBox.PlaceholderText
    safeSend(m)
end)

-- Перетаскивание
local dragging, dragStart, startPos
title.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = i.Position
        startPos = frame.Position
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

UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Открытие/закрытие меню
local openTweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local closeTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local isOpen = false

local function openMenu()
    if isOpen then return end
    isOpen = true
    frame.Visible = true
    TweenService:Create(frame, openTweenInfo, {Size = UDim2.new(targetWidthScale, 0, targetHeightScale, 0)}):Play()
end

local function closeMenu()
    if not isOpen then return end
    isOpen = false
    TweenService:Create(frame, closeTweenInfo, {Size = UDim2.new(targetWidthScale, 0, 0, 0)}):Play()
end

UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.Insert then
        if isOpen then
            closeMenu()
        else
            openMenu()
        end
    end
end)

-- Функции для killfeed
local function trim(s)
    return s:match("^%s*(.-)%s*$") or s
end

local function equalsName(text, target)
    if not text or not target then return false end
    text = trim(tostring(text))
    target = trim(tostring(target))
    if text == "" or target == "" then return false end
    if string.lower(text) == string.lower(target) then
        return true
    end
    if string.find(string.lower(text), string.lower(target), 1, true) then
        return true
    end
    return false
end

local function hookKillfeed()
    local success, feed = pcall(function()
        return player:WaitForChild("PlayerGui"):WaitForChild("UI", 5):WaitForChild("Container", 2):WaitForChild("HUD", 2):WaitForChild("Killfeed", 2):WaitForChild("Feed", 2)
    end)
    if not success or not feed then
        return
    end
    feed.ChildAdded:Connect(function(element)
        if not enabled then return end
        local trackedConns = {}
        local function cleanup()
            for _, c in ipairs(trackedConns) do
                if c and c.Disconnect then
                    pcall(function() c:Disconnect() end)
                end
            end
            trackedConns = {}
        end
        for _, desc in ipairs(element:GetDescendants()) do
            if desc:IsA("TextLabel") then
                local txt = desc.Text
                local targetName = nameBox.Text or player.DisplayName or player.Name
                if equalsName(txt, targetName) then
                    local msg = (msgBox.Text ~= "" and msgBox.Text) or msgBox.PlaceholderText
                    safeSend(msg)
                    break
                end
            end
        end
        local function onDescendantAdded(desc)
            if desc:IsA("TextLabel") then
                local conn = desc:GetPropertyChangedSignal("Text"):Connect(function()
                    if not enabled then
                        pcall(function() conn:Disconnect() end)
                        return
                    end
                    local targetName = nameBox.Text or player.DisplayName or player.Name
                    if equalsName(desc.Text, targetName) then
                        local msg = (msgBox.Text ~= "" and msgBox.Text) or msgBox.PlaceholderText
                        safeSend(msg)
                    end
                end)
                table.insert(trackedConns, conn)
            end
        end
        local descAddedConn = element.DescendantAdded:Connect(onDescendantAdded)
        table.insert(trackedConns, descAddedConn)
        local ancestryConn
        ancestryConn = element.AncestryChanged:Connect(function(_, parent)
            if not parent then
                cleanup()
                if ancestryConn then
                    pcall(function() ancestryConn:Disconnect() end)
                end
            end
        end)
        table.insert(trackedConns, ancestryConn)
    end)
end

task.spawn(hookKillfeed)

-- Автоприменение скина и имени после респавна
player.CharacterAdded:Connect(function(char)
    -- Ждем пока персонаж полностью загрузится
    char:WaitForChild("HumanoidRootPart")
    char:WaitForChild("Head")
    
    task.wait(2) -- 3 секунды после респавна
    
    -- Применить скин если включено
    if autoApply and savedUsername ~= "" then
        applyAppearance(savedUsername)
    end
    
    -- Применить DisplayName/Username через 1 секунду после респавна
    if savedDisplayName ~= "" or savedGameUsername ~= "" then
        task.wait(2)
        changeNameTag(savedDisplayName, savedGameUsername)
    end
end)

-- Анимация заголовка
task.spawn(function()
    while title and title.Parent do
        local t1 = TweenService:Create(title, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {TextTransparency = 0.85})
        t1:Play()
        t1.Completed:Wait()
        local t2 = TweenService:Create(title, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {TextTransparency = 0})
        t2:Play()
        t2.Completed:Wait()
    end
end)
