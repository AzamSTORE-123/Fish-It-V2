--[[
    ██████╗     ██╗
    ██╔══██╗    ██║
    ██║  ██║    ██║
    ██║  ██║██   ██║
    ╚██████╔╝╚█████╔╝
     ╚═════╝  ╚════╝
    FISH IT! | FAST + ANTI-DETECT
    Author : CJ
    Build  : v2.0
--]]

--============================================================
-- SERVICES
--============================================================
local VirtualUser       = game:GetService("VirtualUser")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local Stats             = game:GetService("Stats")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

--============================================================
-- CONFIG
--============================================================
local Config = {
    -- Fishing
    AutoCast        = false,
    AutoReel        = false,
    FastMode        = false,        -- mode cepet
    ClickDelay      = 0.15,
    FastDelay       = 0.05,         -- delay mode cepet
    HoldDuration    = 0.04,
    TapX            = 0.5,
    TapY            = 0.5,

    -- Anti-Detect
    AntiDetect      = true,
    RandomizeDelay  = true,
    HumanizeMove    = true,
    SessionLimit    = 45,           -- menit, auto stop
    CooldownEvery   = 15,           -- menit, cooldown
    CooldownTime    = 30,           -- detik, durasi cooldown

    -- Anti AFK
    AntiAFK         = true,

    -- Stats
    StartTime       = os.time(),
    LastBreak       = os.time(),
    TotalCasts      = 0,
}

--============================================================
-- STATE
--============================================================
local State = {
    Running         = true,
    InCooldown      = false,
    SessionMinutes  = 0,
}

--============================================================
-- HELPER
--============================================================
local function notify(title, text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title, Text = text, Duration = duration or 3,
        })
    end)
end

local function randFloat(a, b)
    return a + math.random() * (b - a)
end

local function randInt(a, b)
    return math.random(a, b)
end

--============================================================
-- TAP FUNCTION
--============================================================
local function tap()
    local viewport = Camera.ViewportSize

    -- Humanize tap position — geser dikit biar gak exact center
    local offsetX = Config.HumanizeMove and randFloat(-0.02, 0.02) or 0
    local offsetY = Config.HumanizeMove and randFloat(-0.02, 0.02) or 0

    local pos = Vector2.new(
        viewport.X * (Config.TapX + offsetX),
        viewport.Y * (Config.TapY + offsetY)
    )

    pcall(function()
        VirtualUser:Button1Down(pos)
        task.wait(Config.HoldDuration + randFloat(0, 0.02))
        VirtualUser:Button1Up(pos)
    end)

    Config.TotalCasts = Config.TotalCasts + 1
end

--============================================================
-- HUMANIZED DELAY
--============================================================
local function getDelay()
    local base = Config.FastMode and Config.FastDelay or Config.ClickDelay

    if Config.AntiDetect and Config.RandomizeDelay then
        -- randomize ±40% dari base
        base = base * randFloat(0.6, 1.4)
    end

    return base
end

--============================================================
-- ANTI-DETECT CORE
--============================================================
local function checkSession()
    local elapsed = (os.time() - Config.StartTime) / 60  -- menit
    State.SessionMinutes = elapsed

    -- Session limit — auto stop
    if Config.AntiDetect and elapsed >= Config.SessionLimit then
        Config.AutoCast = false
        Config.AutoReel = false
        notify("Anti-Detect", "⏰ Session limit. Istirahat dulu.", 5)
        return false
    end

    -- Cooldown periodik
    if Config.AntiDetect then
        local sinceBreak = (os.time() - Config.LastBreak) / 60
        if sinceBreak >= Config.CooldownEvery and not State.InCooldown then
            State.InCooldown = true
            notify("Anti-Detect", "☕ Cooldown " .. Config.CooldownTime .. "s...", 3)

            task.spawn(function()
                task.wait(Config.CooldownTime)
                State.InCooldown = false
                Config.LastBreak = os.time()
                notify("Anti-Detect", "✅ Cooldown selesai.", 2)
            end)
        end
    end

    return true
end

--============================================================
-- AUTO CAST LOOP
--============================================================
task.spawn(function()
    while State.Running do
        if Config.AutoCast and not State.InCooldown then
            if checkSession() then
                tap()
                task.wait(getDelay())
            else
                task.wait(1)
            end
        else
            task.wait(0.1)
        end
    end
end)

--============================================================
-- AUTO REEL LOOP
--============================================================
task.spawn(function()
    while State.Running do
        if Config.AutoReel and not State.InCooldown then
            -- auto tap cepet pas minigame
            tap()
            task.wait(getDelay() * 0.5)
        else
            task.wait(0.1)
        end
    end
end)

--============================================================
-- ANTI AFK
--============================================================
if Config.AntiAFK then
    LocalPlayer.Idled:Connect(function()
        pcall(function()
            VirtualUser:Button2Down(Vector2.new(0, 0))
            task.wait(randFloat(0.8, 1.5))
            VirtualUser:Button2Up(Vector2.new(0, 0))
        end)
    end)
end

--============================================================
-- INPUT BLOCKER (bikin user input gak ganggu auto)
--============================================================
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(2)
    Config.StartTime = os.time()
    Config.LastBreak = os.time()
    Config.TotalCasts = 0
end)

--============================================================
-- UI
--============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CJ_FishIt_v2"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 260, 0, 480)
Main.Position = UDim2.new(0, 20, 0, 80)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local MC = Instance.new("UICorner")
MC.CornerRadius = UDim.new(0, 10)
MC.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Title.BorderSizePixel = 0
Title.Text = "🎣 FISH IT | CJ v2.0"
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.Parent = Main

local TC = Instance.new("UICorner")
TC.CornerRadius = UDim.new(0, 10)
TC.Parent = Title

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -60)
Scroll.Position = UDim2.new(0, 10, 0, 50)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 4
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 5)
Layout.Parent = Scroll

local function makeSection(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = "── " .. text .. " ──"
    lbl.TextColor3 = Color3.fromRGB(255, 215, 0)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = Scroll
end

local function makeToggle(text, key)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 32)
    btn.BackgroundColor3 = Config[key] and Color3.fromRGB(40, 90, 60) or Color3.fromRGB(30, 30, 40)
    btn.BorderSizePixel = 0
    btn.Text = "  " .. text .. " : " .. tostring(Config[key])
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = Scroll

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    btn.MouseButton1Click:Connect(function()
        Config[key] = not Config[key]
        btn.Text = "  " .. text .. " : " .. tostring(Config[key])
        btn.BackgroundColor3 = Config[key]
            and Color3.fromRGB(40, 90, 60)
            or Color3.fromRGB(30, 30, 40)

        if key == "FastMode" and Config.FastMode then
            notify("Fish It!", "⚡ Fast Mode aktif", 2)
        end
    end)
end

local function makeSlider(text, key, min, max)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -10, 0, 46)
    holder.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    holder.BorderSizePixel = 0
    holder.Parent = Scroll

    local hc = Instance.new("UICorner")
    hc.CornerRadius = UDim.new(0, 6)
    hc.Parent = holder

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 18)
    label.Position = UDim2.new(0, 5, 0, 2)
    label.BackgroundTransparency = 1
    label.Text = text .. " : " .. tostring(Config[key])
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = holder

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 8)
    bar.Position = UDim2.new(0, 10, 0, 30)
    bar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    bar.BorderSizePixel = 0
    bar.Parent = holder

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 4)
    bc.Parent = bar

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((Config[key] - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 4)
    fc.Parent = fill

    local dragging = false
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            local val = math.floor(min + (max - min) * rel)
            Config[key] = val
            label.Text = text .. " : " .. tostring(val)
        end
    end)
end

local function makeInfo(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 22)
    lbl.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    lbl.BorderSizePixel = 0
    lbl.Text = "  " .. text
    lbl.TextColor3 = Color3.fromRGB(150, 220, 255)
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = Scroll

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = lbl

    return lbl
end

-- BUILD UI
makeSection("⚡ FISHING")
makeToggle("Auto Cast", "AutoCast")
makeToggle("Auto Reel", "AutoReel")
makeToggle("⚡ Fast Mode", "FastMode")
makeSlider("Click Delay (ms x100)", "ClickDelay", 5, 50)
makeSlider("Fast Delay (ms x100)", "FastDelay", 2, 20)

makeSection("🛡️ ANTI-DETECT")
makeToggle("Anti Detect", "AntiDetect")
makeToggle("Randomize Delay", "RandomizeDelay")
makeToggle("Humanize Tap", "HumanizeMove")
makeToggle("Anti AFK", "AntiAFK")
makeSlider("Session Limit (mnt)", "SessionLimit", 5, 120)
makeSlider("Cooldown Every (mnt)", "CooldownEvery", 5, 60)

makeSection("📊 STATS")
local statLbl = makeInfo("Casts : 0")
local timeLbl = makeInfo("Session : 0m")

-- stats updater
task.spawn(function()
    while State.Running do
        pcall(function()
            statLbl.Text = "  Casts : " .. Config.TotalCasts
            timeLbl.Text = "  Session : " .. math.floor(State.SessionMinutes) .. "m"
        end)
        task.wait(2)
    end
end)

--============================================================
-- START
--============================================================
notify("Fish It! CJ v2.0", "Fast + Anti-Detect loaded. Gas. ☠️", 4)
