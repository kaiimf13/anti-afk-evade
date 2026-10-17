-- Anti-AFK Evade + GUI (Loncat / Gerak) untuk Delta
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer

local INTERVAL = 30 -- detik antar aksi

-- Bersihkan instance lama
local env = (getgenv and getgenv()) or _G
if env.EvadeAFK_Cleanup then pcall(env.EvadeAFK_Cleanup) end

local alive = true
local afkEnabled = false
local mode = "Loncat" -- "Loncat" atau "Gerak"
local connections = {}
local function track(c) table.insert(connections, c) return c end

local parentGui
pcall(function() parentGui = gethui() end)
parentGui = parentGui or game:GetService("CoreGui")

local gui = Instance.new("ScreenGui")
gui.Name = "EvadeAFK_GUI"
gui.ResetOnSpawn = false
gui.Parent = parentGui

env.EvadeAFK_Cleanup = function()
    alive = false
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    pcall(function() gui:Destroy() end)
end

-- ========== LOGIKA ANTI-AFK ==========
track(player.Idled:Connect(function()
    if afkEnabled then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end))

local function tapKey(key, hold)
    local ok = pcall(function()
        VIM:SendKeyEvent(true, key, false, game)
        task.wait(hold or 0.1)
        VIM:SendKeyEvent(false, key, false, game)
    end)
    return ok
end

local function doAction()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    if mode == "Loncat" then
        if not tapKey(Enum.KeyCode.Space, 0.15) then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    else
        -- gerak kecil kiri-kanan lalu loncat
        local ok1 = tapKey(Enum.KeyCode.A, 0.25)
        local ok2 = tapKey(Enum.KeyCode.D, 0.25)
        if not (ok1 and ok2) then
            hum:Move(Vector3.new(-1, 0, 0), true)
            task.wait(0.25)
            hum:Move(Vector3.new(1, 0, 0), true)
        end
        tapKey(Enum.KeyCode.Space, 0.15)
    end
end

task.spawn(function()
    while alive do
        task.wait(INTERVAL)
        if alive and afkEnabled then pcall(doAction) end
    end
end)

-- ========== DRAG ==========
local function makeDraggable(obj, handle)
    handle = handle or obj
    local dragging, dragStart, startPos
    track(handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, obj.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                     startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))
end

-- ========== GUI ==========
local function make(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end
local function round(o, r) Instance.new("UICorner", o).CornerRadius = UDim.new(0, r) end

local main = make("Frame", {
    Size = UDim2.new(0, 210, 0, 150),
    Position = UDim2.new(0.5, -105, 0.3, 0),
    BackgroundColor3 = Color3.fromRGB(30, 30, 35), BorderSizePixel = 0,
}, gui)
round(main, 10)

local title = make("TextLabel", {
    Size = UDim2.new(1, -40, 0, 30), Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1, Text = "Evade Anti-AFK",
    TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left,
}, main)

local minBtn = make("TextButton", {
    Size = UDim2.new(0, 28, 0, 22), Position = UDim2.new(1, -34, 0, 4),
    BackgroundColor3 = Color3.fromRGB(60, 60, 70), Text = "-",
    TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 18,
}, main)
round(minBtn, 6)

local toggleBtn = make("TextButton", {
    Size = UDim2.new(1, -20, 0, 40), Position = UDim2.new(0, 10, 0, 36),
    BackgroundColor3 = Color3.fromRGB(200, 60, 60), Text = "OFF",
    TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 18,
}, main)
round(toggleBtn, 8)

local modeBtn = make("TextButton", {
    Size = UDim2.new(1, -20, 0, 28), Position = UDim2.new(0, 10, 0, 82),
    BackgroundColor3 = Color3.fromRGB(55, 55, 65), Text = "Mode: Loncat",
    TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 13,
}, main)
round(modeBtn, 8)

local status = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 0, 120),
    BackgroundTransparency = 1, Text = "Status: Nonaktif",
    TextColor3 = Color3.fromRGB(180, 180, 180), Font = Enum.Font.Gotham, TextSize = 13,
}, main)

local floatBtn = make("TextButton", {
    Size = UDim2.new(0, 44, 0, 44), Position = UDim2.new(0, 15, 0.5, 0),
    BackgroundColor3 = Color3.fromRGB(200, 60, 60), Text = "AFK",
    TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 13,
}, gui)
round(floatBtn, 22)

local function updateVisual()
    local color = afkEnabled and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(200, 60, 60)
    toggleBtn.Text = afkEnabled and "ON" or "OFF"
    status.Text = afkEnabled and ("Aktif | " .. mode .. " / " .. INTERVAL .. "s") or "Status: Nonaktif"
    toggleBtn.BackgroundColor3 = color
    floatBtn.BackgroundColor3 = color
end

track(toggleBtn.MouseButton1Click:Connect(function()
    afkEnabled = not afkEnabled
    updateVisual()
end))
track(modeBtn.MouseButton1Click:Connect(function()
    mode = (mode == "Loncat") and "Gerak" or "Loncat"
    modeBtn.Text = "Mode: " .. mode
    updateVisual()
end))
track(minBtn.MouseButton1Click:Connect(function() main.Visible = false end))
track(floatBtn.MouseButton1Click:Connect(function() main.Visible = not main.Visible end))

makeDraggable(main, title)
makeDraggable(floatBtn)