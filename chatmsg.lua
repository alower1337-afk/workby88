local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local enabled = true

local channel
pcall(function()
    channel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
end)

local gui = Instance.new("ScreenGui")
gui.Name = "DotaNoobChatUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local targetWidthScale = 0.14
local targetHeightScale = 0.12

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
title.Text = "DotaNoob!88!"
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextColor3 = Color3.fromRGB(255,80,80)
title.TextTransparency = 0
title.Parent = frame

local msgBox = Instance.new("TextBox")
msgBox.Size = UDim2.new(1, -14, 0, 28)
msgBox.Position = UDim2.new(0, 7, 0, 30)
msgBox.BackgroundColor3 = Color3.fromRGB(28,28,28)
msgBox.TextColor3 = Color3.new(1,1,1)
msgBox.PlaceholderText = "workby!88!"
msgBox.Text = ""
msgBox.Font = Enum.Font.Gotham
msgBox.TextSize = 12
msgBox.ClearTextOnFocus = true
msgBox.Parent = frame
Instance.new("UICorner", msgBox).CornerRadius = UDim.new(0,6)

local nameBox = Instance.new("TextBox")
nameBox.Size = UDim2.new(1, -14, 0, 24)
nameBox.Position = UDim2.new(0, 7, 0, 64)
nameBox.BackgroundColor3 = Color3.fromRGB(28,28,28)
nameBox.TextColor3 = Color3.fromRGB(200,200,200)
nameBox.Text = player.DisplayName ~= "" and player.DisplayName or player.Name
nameBox.Font = Enum.Font.Gotham
nameBox.TextSize = 11
nameBox.ClearTextOnFocus = true
nameBox.Parent = frame
Instance.new("UICorner", nameBox).CornerRadius = UDim.new(0,6)

local function makeButton(text, pos)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.48, 0, 0, 24)
    b.Position = pos
    b.Text = text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.TextColor3 = Color3.new(1,1,1)
    b.Parent = frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    return b
end

local toggleBtn = makeButton("ON", UDim2.new(0.02, 0, 0, 94))
local testBtn = makeButton("TEST", UDim2.new(0.50, 0, 0, 94))

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

toggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    updateToggle()
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
