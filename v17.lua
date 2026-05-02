-- kaw0ru lite | Luna Interface Suite -- v3.1 (memory fix by Claude)
local Luna = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/luna", true))()

local RS           = game:GetService("ReplicatedStorage")
local RunService   = game:GetService("RunService")
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Stats        = game:GetService("Stats")
local VirtualUser  = game:GetService("VirtualUser")
local p            = Players.LocalPlayer

-- =========================================
-- CACHE REMOTES
-- =========================================
local store         = RS.Remotes.Server.Software.Store
local sellSoftware  = RS.Remotes.Server.Software.Sell
local complete      = RS.Remotes.Server.CompletePlayerCodingProgram
local bubble        = RS.Remotes.Server.PopProgrammingBubble
local ore           = RS.Remotes.Server.Mining.UpdateOreHealth
local boulder       = RS.Remotes.Server.Mining.UpdateBoulderHealth
local fish          = RS.Remotes.Server.Fishing.ResolveFishingAttempt
local startCode     = RS.Remotes.Server.StartComputerCodingSession
local keyHit        = RS.Remotes.Server.ComputerKeyHit
local stopCode      = RS.Remotes.Server.StopComputerCodingSession
local collectIngots = RS.Remotes.Server.Ores.CollectIngots
local collectAlloys = RS.Remotes.Server.Ores.CollectAlloys
local jobCompleted  = RS.Remotes.Server.Job.Completed
local jobGiveNew    = RS.Remotes.Server.Job.GiveNew
local preventAfk    = RS.Remotes.Server.PreventKickAfk
local meteorMerge   = RS.Remotes.Server.MeteorMerge
local buyMerchant   = RS.Remotes.Server.Vendor.BuyMerchantItem
local mines         = workspace.Interiors.Mines
local fishing       = workspace.Map.World1:WaitForChild("FishingSpots")
local meteors       = workspace.RunTime:WaitForChild("Meteors")

-- =========================================
-- CACHE OFFICE PCs
-- =========================================
local myHardware = nil
local cachedPCs  = {}

pcall(function()
    myHardware = workspace.Interiors.Offices[tostring(p.UserId)].Items.Hardware
end)

local function refreshPCCache()
    table.clear(cachedPCs)
    if not myHardware then return end
    for _, v in ipairs(myHardware:GetDescendants()) do
        if v.Name == "Pc" and v:IsA("Model") then
            local id = v:GetAttribute("Id")
            if id then table.insert(cachedPCs, id) end
        end
    end
end
refreshPCCache()

if myHardware then
    myHardware.DescendantAdded:Connect(function(v)
        if v.Name == "Pc" and v:IsA("Model") then
            task.wait(0.5)
            refreshPCCache()
        end
    end)
    myHardware.DescendantRemoving:Connect(function(v)
        if v.Name == "Pc" and v:IsA("Model") then
            task.defer(refreshPCCache)
        end
    end)
end

-- =========================================
-- CACHE MINES
-- FIX #3: count обновляется живо через ChildAdded/ChildRemoved
-- =========================================
local AREAS_PER_MINE = 3
local cachedAreas = {}
for m = 1, 2 do
    cachedAreas[m] = {}
    local mine = mines:FindFirstChild("Mine" .. m)
    if mine then
        for a = 1, AREAS_PER_MINE do
            local area = mine.OreSpawns:FindFirstChild("Area" .. a)
            cachedAreas[m][a] = area
            if area then
                cachedAreas[m][a .. "_count"] = #area:GetChildren()
                area.ChildAdded:Connect(function()
                    cachedAreas[m][a .. "_count"] = #area:GetChildren()
                end)
                area.ChildRemoved:Connect(function()
                    cachedAreas[m][a .. "_count"] = #area:GetChildren()
                end)
            end
        end
    end
end

local fishingCount = #fishing:GetChildren()

-- =========================================
-- SELL TABLE
-- =========================================
local SOFTWARE_TIERS = {}
for i = 1, 10 do SOFTWARE_TIERS[tostring(i)] = 999999 end

local SELL_TABLES = {
    All       = { Programs = {}, Apps = {}, Platforms = {} },
    Programs  = { Programs = {} },
    Apps      = { Apps = {} },
    Platforms = { Platforms = {} },
}
for _, tbl in pairs(SELL_TABLES) do
    for _, typeData in pairs(tbl) do
        for k, v in pairs(SOFTWARE_TIERS) do
            typeData[k] = v
        end
    end
end

-- =========================================
-- REUSABLE METEOR PARTS TABLE
-- =========================================
local meteorPartsCache = {}

-- =========================================
-- FLAT NAMED FUNCTIONS
-- =========================================
local function _doCode()
    startCode:FireServer()
    for i = 1, 30 do
        keyHit:FireServer(" ")
        task.wait(0)
    end
    stopCode:FireServer()
    complete:InvokeServer()
end

local function _doStore(id)   store:InvokeServer(id) end
local function _doBubble()    bubble:FireServer("33") end
local function _doIngots()    collectIngots:FireServer() end
local function _doAlloys()    collectAlloys:FireServer() end
local function _doMeteorMerge() meteorMerge:FireServer() end

local function _doSell()
    local key = getgenv().SellKey or "All"
    sellSoftware:FireServer(SELL_TABLES[key])
end

local function _doJobCycle()
    jobCompleted:FireServer()
    task.wait(0.1)
    jobGiveNew:FireServer()
end

local function _doOre(m, a, s)    ore:InvokeServer(m, a, s) end
local function _doBoulder(m, a)   boulder:InvokeServer(m, a, 1) end
local function _doFish(i)         fish:InvokeServer(i, true) end

local function _doBuyMerchant(mid, slot)
    buyMerchant:FireServer(mid, slot)
end

-- =========================================
-- NOCLIP
-- =========================================
local noclipParts = {}
local function rebuildNoclipParts()
    table.clear(noclipParts)
    local char = p.Character
    if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            table.insert(noclipParts, v)
        end
    end
end
p.CharacterAdded:Connect(function()
    task.wait(1)
    rebuildNoclipParts()
end)
rebuildNoclipParts()

RunService.Heartbeat:Connect(function()
    if not getgenv().Noclip then return end
    for i = 1, #noclipParts do
        local v = noclipParts[i]
        if v and v.Parent then v.CanCollide = false end
    end
end)

-- =========================================
-- ANTI-AFK GUI
-- =========================================
local afkGui = nil
-- FIX #2: список connections для полного отключения при destroy
local afkConnections = {}

local C_BG      = Color3.fromRGB(20,  20,  20)
local C_ACCENT  = Color3.fromRGB(100, 100, 255)
local C_TEXT    = Color3.fromRGB(240, 240, 240)
local C_SUBTEXT = Color3.fromRGB(150, 150, 150)
local C_GREEN   = Color3.fromRGB(100, 220, 100)
local C_DIVIDER = Color3.fromRGB(50,  50,  50)

local function makeCorner(parent, radius)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, radius or 8)
end

local function makeLabel(parent, text, size, color, pos, sz, font, align)
    local l = Instance.new("TextLabel", parent)
    l.BackgroundTransparency = 1
    l.Text       = text
    l.TextSize   = size or 13
    l.TextColor3 = color or C_TEXT
    l.Font       = font or Enum.Font.GothamSemibold
    l.Position   = pos  or UDim2.new(0,0,0,0)
    l.Size       = sz   or UDim2.new(1,0,0,20)
    l.TextXAlignment = align or Enum.TextXAlignment.Left
    l.TextTruncate   = Enum.TextTruncate.AtEnd
    return l
end

local function makeDivider(parent, posY)
    local d = Instance.new("Frame", parent)
    d.BackgroundColor3 = C_DIVIDER
    d.BorderSizePixel  = 0
    d.Position = UDim2.new(0, 10, 0, posY)
    d.Size     = UDim2.new(1, -20, 0, 1)
end

local function destroyAfkGui()
    -- FIX #2: отключаем ВСЕ connections — раньше они висели вечно
    for _, conn in ipairs(afkConnections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(afkConnections)
    if afkGui and afkGui.Parent then
        afkGui:Destroy()
    end
    afkGui = nil
end

local function createAfkGui()
    destroyAfkGui()

    afkGui = Instance.new("ScreenGui")
    afkGui.Name           = "kaw0ruAfkWidget"
    afkGui.ResetOnSpawn   = false
    afkGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    afkGui.Parent         = game.CoreGui

    local shadow = Instance.new("Frame", afkGui)
    shadow.Name                   = "Shadow"
    shadow.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.6
    shadow.BorderSizePixel        = 0
    shadow.Position               = UDim2.new(0, 18, 0, 68)
    shadow.Size                   = UDim2.new(0, 224, 0, 134)
    makeCorner(shadow, 12)

    local frame = Instance.new("Frame", afkGui)
    frame.Name             = "MainFrame"
    frame.BackgroundColor3 = C_BG
    frame.BorderSizePixel  = 0
    frame.Position         = UDim2.new(0, 14, 0, 64)
    frame.Size             = UDim2.new(0, 224, 0, 134)
    makeCorner(frame, 10)

    local topBar = Instance.new("Frame", frame)
    topBar.BackgroundColor3 = C_ACCENT
    topBar.BorderSizePixel  = 0
    topBar.Position         = UDim2.new(0, 0, 0, 0)
    topBar.Size             = UDim2.new(1, 0, 0, 3)
    makeCorner(topBar, 10)

    makeLabel(frame, "kaw0ru lite", 13, C_TEXT,
        UDim2.new(0, 12, 0, 8), UDim2.new(0, 140, 0, 18), Enum.Font.GothamBold)
    makeLabel(frame, "Anti-AFK", 11, C_SUBTEXT,
        UDim2.new(0, 12, 0, 24), UDim2.new(0, 140, 0, 16), Enum.Font.Gotham)

    local dotFrame = Instance.new("Frame", frame)
    dotFrame.BackgroundTransparency = 1
    dotFrame.Position = UDim2.new(0, 12, 0, 44)
    dotFrame.Size     = UDim2.new(0, 100, 0, 16)

    local dot = Instance.new("Frame", dotFrame)
    dot.BackgroundColor3 = C_GREEN
    dot.BorderSizePixel  = 0
    dot.Position         = UDim2.new(0, 0, 0.5, -4)
    dot.Size             = UDim2.new(0, 8, 0, 8)
    makeCorner(dot, 50)

    -- FIX #4: создаём Tween ОДИН РАЗ, переиспользуем — не создаём новый каждые 0.8 сек
    local tweenIn  = TweenService:Create(dot,
        TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        { BackgroundTransparency = 0.6 })
    local tweenOut = TweenService:Create(dot,
        TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        { BackgroundTransparency = 0 })

    task.spawn(function()
        while afkGui and afkGui.Parent do
            tweenIn:Play()
            task.wait(0.8)
            tweenOut:Play()
            task.wait(0.8)
        end
        tweenIn:Destroy()
        tweenOut:Destroy()
    end)

    local activeLabel = makeLabel(dotFrame, "Active", 11, C_GREEN,
        UDim2.new(0, 14, 0, 0), UDim2.new(0, 80, 1, 0), Enum.Font.GothamSemibold)
    activeLabel.TextYAlignment = Enum.TextYAlignment.Center

    local closeBtn = Instance.new("TextButton", frame)
    closeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    closeBtn.BorderSizePixel  = 0
    closeBtn.Position         = UDim2.new(1, -26, 0, 8)
    closeBtn.Size             = UDim2.new(0, 18, 0, 18)
    closeBtn.Font             = Enum.Font.GothamBold
    closeBtn.Text             = "×"
    closeBtn.TextColor3       = C_SUBTEXT
    closeBtn.TextSize         = 14
    makeCorner(closeBtn, 6)
    closeBtn.MouseButton1Click:Connect(destroyAfkGui)

    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(90, 60, 60),
            TextColor3       = Color3.fromRGB(255, 100, 100)
        }):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(60, 60, 60),
            TextColor3       = C_SUBTEXT
        }):Play()
    end)

    makeDivider(frame, 66)

    makeLabel(frame, "Ping", 11, C_SUBTEXT,
        UDim2.new(0, 12, 0, 74), UDim2.new(0, 40, 0, 16), Enum.Font.Gotham)
    local pingVal = makeLabel(frame, "—", 12, C_TEXT,
        UDim2.new(0, 56, 0, 73), UDim2.new(0, 60, 0, 17), Enum.Font.GothamSemibold)

    makeLabel(frame, "FPS", 11, C_SUBTEXT,
        UDim2.new(0, 120, 0, 74), UDim2.new(0, 35, 0, 16), Enum.Font.Gotham)
    local fpsVal = makeLabel(frame, "—", 12, C_TEXT,
        UDim2.new(0, 158, 0, 73), UDim2.new(0, 54, 0, 17), Enum.Font.GothamSemibold)

    makeDivider(frame, 96)

    makeLabel(frame, "Uptime", 11, C_SUBTEXT,
        UDim2.new(0, 12, 0, 104), UDim2.new(0, 50, 0, 16), Enum.Font.Gotham)
    local timerVal = makeLabel(frame, "0:00:00", 12, C_ACCENT,
        UDim2.new(0, 66, 0, 103), UDim2.new(0, 110, 0, 17), Enum.Font.GothamSemibold)

    -- Drag
    local dragging, dragInput, dragStart, startPos
    table.insert(afkConnections, frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end))
    table.insert(afkConnections, frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end))
    -- FIX #2: сохраняем — раньше каждое включение AFK добавляло новый висячий listener
    table.insert(afkConnections, UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging and frame and frame.Parent then
            local delta  = input.Position - dragStart
            local newPos = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
            TweenService:Create(frame, TweenInfo.new(0.04, Enum.EasingStyle.Sine), {
                Position = newPos
            }):Play()
            TweenService:Create(shadow, TweenInfo.new(0.04, Enum.EasingStyle.Sine), {
                Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X + 4,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y + 4
                )
            }):Play()
        end
    end))

    -- FIX #1: FPS без растущей таблицы
    -- Оригинал: fpsTable росла до 36000+ записей за 10 минут @ 60fps
    local fpsFrames = 0
    local fpsAccum  = 0
    local fpsTimer  = 0
    table.insert(afkConnections, RunService.RenderStepped:Connect(function(dt)
        if not afkGui or not afkGui.Parent then return end
        fpsFrames = fpsFrames + 1
        fpsAccum  = fpsAccum  + dt
        fpsTimer  = fpsTimer  + dt
        if fpsTimer >= 1 then
            fpsVal.Text = tostring(math.floor(fpsFrames / fpsAccum))
            fpsFrames = 0
            fpsAccum  = 0
            fpsTimer  = 0
        end
    end))

    -- Ping
    task.spawn(function()
        while afkGui and afkGui.Parent do
            pcall(function()
                local ping = math.floor(Stats.PerformanceStats.Ping:GetValue())
                pingVal.Text = tostring(ping) .. " ms"
            end)
            task.wait(1)
        end
    end)

    -- Uptime таймер
    task.spawn(function()
        local s, m, h = 0, 0, 0
        while afkGui and afkGui.Parent do
            task.wait(1)
            s = s + 1
            if s >= 60 then s = 0; m = m + 1 end
            if m >= 60 then m = 0; h = h + 1 end
            if timerVal and timerVal.Parent then
                timerVal.Text = string.format("%d:%02d:%02d", h, m, s)
            end
        end
    end)

    -- Fade-in
    frame.BackgroundTransparency = 1
    TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
        BackgroundTransparency = 0
    }):Play()
end

-- Idled коннект
p.Idled:Connect(function()
    if getgenv().AntiAfk then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- =========================================
-- GENERATION COUNTER
-- =========================================
local generations = {}
local function newGen(key)
    generations[key] = (generations[key] or 0) + 1
    return generations[key]
end
local function isAlive(key, gen)
    return generations[key] == gen
end

-- =========================================
-- ПЕРИОДИЧЕСКИЙ GC — каждые 3 минуты
-- =========================================
task.spawn(function()
    while true do
        task.wait(180)
        collectgarbage("collect")
        table.clear(meteorPartsCache)
    end
end)

-- =========================================
-- WINDOW
-- =========================================
local Window = Luna:CreateWindow({
    Name            = "kaw0ru lite",
    Subtitle        = "by Cosx",
    LogoID          = nil,
    LoadingEnabled  = true,
    LoadingTitle    = "kaw0ru lite",
    LoadingSubtitle = "Initializing modules...",
    ConfigSettings  = { ConfigFolder = "kaw0ruLite" },
    KeySystem       = false,
})

-- =========================================
-- TABS
-- =========================================
local TabHome     = Window:CreateTab({ Name = "Home",            Icon = nil, ShowTitle = true })
local TabCoding   = Window:CreateTab({ Name = "Auto Coding",     Icon = nil, ShowTitle = true })
local TabFurnace  = Window:CreateTab({ Name = "Furnace",         Icon = nil, ShowTitle = true })
local TabMines    = Window:CreateTab({ Name = "Mines & Fishing", Icon = nil, ShowTitle = true })
local TabMeteors  = Window:CreateTab({ Name = "Meteors",         Icon = nil, ShowTitle = true })
local TabMerchant = Window:CreateTab({ Name = "Merchant",        Icon = nil, ShowTitle = true })
local TabExtra    = Window:CreateTab({ Name = "Extra",           Icon = nil, ShowTitle = true })
local TabSettings = Window:CreateTab({ Name = "Settings",        Icon = nil, ShowTitle = true })

-- =========================================
-- HOME
-- =========================================
Window:CreateHomeTab({
    SupportedExecutors = {"Synapse X", "KRNL", "Fluxus", "Solara", "Delta"},
    DiscordInvite      = nil,
    Icon               = 2,
})

TabHome:CreateSection("About")
TabHome:CreateParagraph({
    Title = "kaw0ru lite",
    Text  = "Powerful script for Software Tycoon. Auto-coding, store, mines, fishing, furnace, meteors and extras. Made by <b>Cosx</b>."
})
TabHome:CreateDivider()
TabHome:CreateSection("Module Status")
TabHome:CreateLabel({ Text = "Auto Coding        -- ready", Style = 2 })
TabHome:CreateLabel({ Text = "Auto Store         -- ready", Style = 2 })
TabHome:CreateLabel({ Text = "Auto Bubble        -- ready", Style = 2 })
TabHome:CreateLabel({ Text = "Auto Sell Software -- ready", Style = 2 })
TabHome:CreateLabel({ Text = "Auto Job           -- ready", Style = 2 })
TabHome:CreateLabel({ Text = "Auto Ingots        -- ready", Style = 2 })
TabHome:CreateLabel({ Text = "Auto Alloys        -- ready", Style = 2 })
TabHome:CreateLabel({ Text = "Auto Mines         -- ready", Style = 2 })
TabHome:CreateLabel({ Text = "Auto Fishing       -- ready", Style = 2 })
TabHome:CreateLabel({ Text = "Auto Meteors       -- ready", Style = 2 })
TabHome:CreateLabel({ Text = "Anti-AFK           -- ready", Style = 2 })
TabHome:CreateDivider()
TabHome:CreateLabel({ Text = "Version: v3.1 (memory fix)  |  by Cosx", Style = 1 })

-- =========================================
-- AUTO CODING
-- =========================================
TabCoding:CreateSection("Auto Coding")
TabCoding:CreateLabel({ Text = "Auto coding from anywhere on the map.", Style = 2 })

getgenv().CodingDelay = 0.05

TabCoding:CreateSlider({
    Name         = "Auto Coding Delay (sec)",
    Description  = "Pause between coding iterations",
    Range        = { 0, 10 },
    Increment    = 0.05,
    Suffix       = "s",
    CurrentValue = 0.05,
    Callback = function(value)
        getgenv().CodingDelay = value
    end
}, "CodingDelay")

TabCoding:CreateToggle({
    Name         = "Auto Coding",
    Description  = "Auto code writing",
    CurrentValue = false,
    Callback = function(state)
        getgenv().AutoCoding = state
        if not state then return end
        local gen = newGen("AutoCoding")
        task.spawn(function()
            while getgenv().AutoCoding and isAlive("AutoCoding", gen) do
                pcall(_doCode)
                task.wait(math.max(0.05, getgenv().CodingDelay))
            end
        end)
    end
}, "AutoCoding")

TabCoding:CreateDivider()

-- AUTO STORE
TabCoding:CreateSection("Auto Store")
TabCoding:CreateLabel({ Text = "Collects finished code from all PCs in your office.", Style = 2 })

getgenv().StoreDelay = 1

TabCoding:CreateSlider({
    Name         = "Auto Store Delay (sec)",
    Description  = "How often to collect code from PCs",
    Range        = { 1, 60 },
    Increment    = 1,
    Suffix       = "s",
    CurrentValue = 1,
    Callback = function(value)
        getgenv().StoreDelay = value
    end
}, "StoreDelay")

TabCoding:CreateToggle({
    Name         = "Auto Store",
    Description  = "Collect finished code from office PCs",
    CurrentValue = false,
    Callback = function(state)
        getgenv().AutoStore = state
        if not state then return end
        local gen = newGen("AutoStore")
        task.spawn(function()
            while getgenv().AutoStore and isAlive("AutoStore", gen) do
                for _, id in ipairs(cachedPCs) do
                    pcall(_doStore, id)
                    task.wait(0.05)
                end
                task.wait(getgenv().StoreDelay)
            end
        end)
    end
}, "AutoStore")

TabCoding:CreateDivider()

-- AUTO BUBBLE
TabCoding:CreateSection("Auto Bubble")
TabCoding:CreateLabel({ Text = "Auto pop programming bubbles.", Style = 2 })

TabCoding:CreateToggle({
    Name         = "Auto Bubble",
    Description  = "Pops programming bubbles",
    CurrentValue = false,
    Callback = function(state)
        getgenv().AutoBubble = state
        if not state then return end
        local gen = newGen("AutoBubble")
        task.spawn(function()
            while getgenv().AutoBubble and isAlive("AutoBubble", gen) do
                pcall(_doBubble)
                task.wait(0.3)
            end
        end)
    end
}, "AutoBubble")

TabCoding:CreateDivider()

-- AUTO SELL SOFTWARE
TabCoding:CreateSection("Auto Sell Software")
TabCoding:CreateLabel({ Text = "Choose type, delay and enable selling.", Style = 2 })

getgenv().SellKey   = "All"
getgenv().SellDelay = 60

TabCoding:CreateDropdown({
    Name            = "Software type to sell",
    Description     = "What to sell",
    Options         = { "All", "Programs", "Apps", "Platforms" },
    CurrentOption   = { "All" },
    MultipleOptions = false,
    SpecialType     = nil,
    Callback = function(value)
        getgenv().SellKey = value
    end
}, "SellType")

TabCoding:CreateSlider({
    Name         = "Sell Delay (sec)",
    Description  = "How often to sell software",
    Range        = { 1, 120 },
    Increment    = 1,
    Suffix       = "s",
    CurrentValue = 60,
    Callback = function(value)
        getgenv().SellDelay = value
    end
}, "SellDelay")

TabCoding:CreateToggle({
    Name         = "Auto Sell Software",
    Description  = "Auto sell selected software type",
    CurrentValue = false,
    Callback = function(state)
        getgenv().AutoSell = state
        if not state then return end
        local gen = newGen("AutoSell")
        task.spawn(function()
            while getgenv().AutoSell and isAlive("AutoSell", gen) do
                pcall(_doSell)
                task.wait(getgenv().SellDelay)
            end
        end)
    end
}, "AutoSell")

TabCoding:CreateDivider()

-- AUTO JOB
TabCoding:CreateSection("Auto Job")
TabCoding:CreateLabel({ Text = "Auto complete and receive new jobs.", Style = 2 })

TabCoding:CreateToggle({
    Name         = "Auto Job",
    Description  = "Auto complete and get new jobs",
    CurrentValue = false,
    Callback = function(state)
        getgenv().AutoJob = state
        if not state then return end
        local gen = newGen("AutoJob")
        task.spawn(function()
            while getgenv().AutoJob and isAlive("AutoJob", gen) do
                pcall(_doJobCycle)
                task.wait(0.5)
            end
        end)
    end
}, "AutoJob")

-- =========================================
-- FURNACE
-- =========================================
TabFurnace:CreateSection("Collect")
TabFurnace:CreateLabel({ Text = "Collect ingots and alloys from the furnace.", Style = 2 })

TabFurnace:CreateToggle({
    Name         = "Auto Collect Ingots",
    Description  = "Collects ingots from the furnace",
    CurrentValue = false,
    Callback = function(state)
        getgenv().AutoIngots = state
        if not state then return end
        local gen = newGen("AutoIngots")
        task.spawn(function()
            while getgenv().AutoIngots and isAlive("AutoIngots", gen) do
                pcall(_doIngots)
                task.wait(1)
            end
        end)
    end
}, "AutoIngots")

TabFurnace:CreateToggle({
    Name         = "Auto Collect Alloys",
    Description  = "Collects alloys from the furnace",
    CurrentValue = false,
    Callback = function(state)
        getgenv().AutoAlloys = state
        if not state then return end
        local gen = newGen("AutoAlloys")
        task.spawn(function()
            while getgenv().AutoAlloys and isAlive("AutoAlloys", gen) do
                pcall(_doAlloys)
                task.wait(1)
            end
        end)
    end
}, "AutoAlloys")

-- =========================================
-- MINES & FISHING
-- =========================================
TabMines:CreateSection("Select Mine")
TabMines:CreateLabel({ Text = "Select a mine before starting the farm!", Style = 3 })

getgenv().SelectedMineZone = "1"

TabMines:CreateDropdown({
    Name            = "Select Mine",
    Description     = "Which mine to farm",
    Options         = { "Mine 1 (zone 3)", "Mine 2 (zone 7)", "Both mines" },
    CurrentOption   = { "Mine 1 (zone 3)" },
    MultipleOptions = false,
    SpecialType     = nil,
    Callback = function(value)
        if value == "Mine 1 (zone 3)" then
            getgenv().SelectedMineZone = "1"
        elseif value == "Mine 2 (zone 7)" then
            getgenv().SelectedMineZone = "2"
        else
            getgenv().SelectedMineZone = "both"
        end
    end
}, "MineZone")

TabMines:CreateDivider()
TabMines:CreateSection("Auto Mine Farm")
TabMines:CreateLabel({ Text = "Farms all ore slots. Areas cached + live updated.", Style = 2 })

TabMines:CreateToggle({
    Name         = "Auto Mines",
    Description  = "Auto farm the selected mine",
    CurrentValue = false,
    Callback = function(state)
        getgenv().AutoMines = state
        if not state then return end
        local gen = newGen("AutoMines")
        task.spawn(function()
            while getgenv().AutoMines and isAlive("AutoMines", gen) do
                local zone   = getgenv().SelectedMineZone
                local mStart = (zone == "2") and 2 or 1
                local mEnd   = (zone == "1") and 1 or 2
                for m = mStart, mEnd do
                    for a = 1, AREAS_PER_MINE do
                        local count = cachedAreas[m][a .. "_count"] or 0
                        for s = 1, count do
                            pcall(_doOre, m, a, s)
                            task.wait(0.05)
                        end
                    end
                end
                task.wait(0.5)
            end
        end)
    end
}, "AutoMines")

TabMines:CreateDivider()
TabMines:CreateSection("Auto Boulder")
TabMines:CreateLabel({ Text = "Farms boulders in the mine.", Style = 2 })

TabMines:CreateToggle({
    Name         = "Auto Boulder",
    Description  = "Auto break boulders",
    CurrentValue = false,
    Callback = function(state)
        getgenv().AutoBoulder = state
        if not state then return end
        local gen = newGen("AutoBoulder")
        task.spawn(function()
            while getgenv().AutoBoulder and isAlive("AutoBoulder", gen) do
                local zone   = getgenv().SelectedMineZone
                local mStart = (zone == "2") and 2 or 1
                local mEnd   = (zone == "1") and 1 or 2
                for m = mStart, mEnd do
                    for a = 1, AREAS_PER_MINE do
                        pcall(_doBoulder, m, a)
                        task.wait(0.05)
                    end
                end
                task.wait(0.3)
            end
        end)
    end
}, "AutoBoulder")

TabMines:CreateDivider()
TabMines:CreateSection("Fishing")
TabMines:CreateLabel({ Text = "Auto-fishing at all FishingSpots on the map.", Style = 2 })

TabMines:CreateToggle({
    Name         = "Auto Fishing",
    Description  = "Auto fishing at all spots",
    CurrentValue = false,
    Callback = function(state)
        getgenv().AutoFishing = state
        if not state then return end
        local gen = newGen("AutoFishing")
        task.spawn(function()
            while getgenv().AutoFishing and isAlive("AutoFishing", gen) do
                for i = 1, fishingCount do
                    pcall(_doFish, i)
                    task.wait(0.05)
                end
                task.wait(0.5)
            end
        end)
    end
}, "AutoFishing")

-- =========================================
-- METEORS
-- =========================================
TabMeteors:CreateSection("Auto Meteors")
TabMeteors:CreateLabel({ Text = "Teleports meteors to you and auto-clicks them.", Style = 2 })
TabMeteors:CreateDivider()

local function _processMeteor(mtr, cf)
    table.clear(meteorPartsCache)
    local parts = mtr:GetDescendants()
    for i = 1, #parts do
        local v = parts[i]
        if v:IsA("BasePart") then
            table.insert(meteorPartsCache, v)
        end
    end
    for i = 1, #meteorPartsCache do
        local v = meteorPartsCache[i]
        v.Anchored = true
        v.AssemblyLinearVelocity  = Vector3.zero
        v.AssemblyAngularVelocity = Vector3.zero
    end
    if mtr:IsA("Model") then
        mtr:PivotTo(cf)
    else
        local bp = mtr:FindFirstChildWhichIsA("BasePart", true)
        if bp then bp.CFrame = cf end
    end
    local prompt = mtr:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        prompt.HoldDuration = 0
        fireproximityprompt(prompt)
    end
    table.clear(meteorPartsCache)
end

local meteorList = {}
TabMeteors:CreateToggle({
    Name         = "Auto Meteors",
    Description  = "Teleport meteors to player and auto click",
    CurrentValue = false,
    Callback = function(state)
        getgenv().AutoMeteors = state
        if not state then return end
        local gen = newGen("AutoMeteors")
        task.spawn(function()
            while getgenv().AutoMeteors and isAlive("AutoMeteors", gen) do
                task.wait(0.5)
                table.clear(meteorList)
                for _, v in ipairs(meteors:GetChildren()) do
                    table.insert(meteorList, v)
                end
                if #meteorList == 0 then continue end
                local c = p.Character
                if not c then continue end
                local root = c:FindFirstChild("HumanoidRootPart")
                if not root then continue end
                local cf = root.CFrame * CFrame.new(0, 0, -6)
                for i = 1, #meteorList do
                    pcall(_processMeteor, meteorList[i], cf)
                    task.wait(0.05)
                end
            end
        end)
    end
}, "AutoMeteors")

TabMeteors:CreateDivider()
TabMeteors:CreateSection("Meteor Merge")
TabMeteors:CreateLabel({ Text = "Auto merge meteors.", Style = 2 })

TabMeteors:CreateToggle({
    Name         = "Auto Meteor Merge",
    Description  = "Auto merge meteors",
    CurrentValue = false,
    Callback = function(state)
        getgenv().AutoMeteorMerge = state
        if not state then return end
        local gen = newGen("AutoMeteorMerge")
        task.spawn(function()
            while getgenv().AutoMeteorMerge and isAlive("AutoMeteorMerge", gen) do
                pcall(_doMeteorMerge)
                task.wait(1)
            end
        end)
    end
}, "AutoMeteorMerge")

-- =========================================
-- MERCHANT
-- =========================================
getgenv().MerchantIds   = { "1", "2" }
getgenv().MerchantDelay = 300

local function buyFromMerchant(mid)
    for s = 1, 3 do
        pcall(_doBuyMerchant, mid, tostring(s))
        task.wait(0.15)
    end
end

TabMerchant:CreateSection("Merchant Selection")
TabMerchant:CreateLabel({ Text = "Merchant 1 -- zone 6  |  Merchant 2 -- zone 8", Style = 2 })

TabMerchant:CreateDropdown({
    Name            = "Select merchants",
    Description     = "Which merchants to farm",
    Options         = { "Merchant 1 (zone 6)", "Merchant 2 (zone 8)", "Both" },
    CurrentOption   = { "Both" },
    MultipleOptions = false,
    SpecialType     = nil,
    Callback = function(value)
        if value == "Merchant 1 (zone 6)" then
            getgenv().MerchantIds = { "1" }
        elseif value == "Merchant 2 (zone 8)" then
            getgenv().MerchantIds = { "2" }
        else
            getgenv().MerchantIds = { "1", "2" }
        end
    end
}, "MerchantSelect")

TabMerchant:CreateDivider()
TabMerchant:CreateSection("Auto Merchant")
TabMerchant:CreateLabel({ Text = "Buys all 3 slots from selected merchants.", Style = 2 })

TabMerchant:CreateSlider({
    Name         = "Delay (sec)",
    Description  = "How often to repeat purchase",
    Range        = { 30, 360 },
    Increment    = 10,
    Suffix       = "s",
    CurrentValue = 300,
    Callback = function(value)
        getgenv().MerchantDelay = value
    end
}, "MerchantDelay")

TabMerchant:CreateToggle({
    Name         = "Auto Merchant",
    Description  = "Auto buy all slots from merchants",
    CurrentValue = false,
    Callback = function(state)
        getgenv().AutoMerchant = state
        if not state then return end
        local gen = newGen("AutoMerchant")
        task.spawn(function()
            while getgenv().AutoMerchant and isAlive("AutoMerchant", gen) do
                for _, mid in ipairs(getgenv().MerchantIds) do
                    buyFromMerchant(mid)
                    task.wait(0.3)
                end
                task.wait(getgenv().MerchantDelay)
            end
        end)
    end
}, "AutoMerchant")

TabMerchant:CreateDivider()
TabMerchant:CreateSection("Buy Manually")
TabMerchant:CreateLabel({ Text = "One-time purchase right now.", Style = 2 })

TabMerchant:CreateButton({
    Name        = "Buy Now",
    Description = "Buy all slots from selected merchants",
    Callback = function()
        for _, mid in ipairs(getgenv().MerchantIds) do
            buyFromMerchant(mid)
            task.wait(0.3)
        end
        Luna:Notification({ Title = "kaw0ru lite", Content = "Purchase sent!" })
    end
})

-- =========================================
-- EXTRA
-- =========================================
TabExtra:CreateSection("Anti-AFK")
TabExtra:CreateLabel({ Text = "Prevents AFK kick. Shows a status widget when active.", Style = 2 })

TabExtra:CreateToggle({
    Name         = "Anti-AFK",
    Description  = "Prevents AFK kick + shows status widget",
    CurrentValue = false,
    Callback = function(state)
        getgenv().AntiAfk = state
        if state then
            createAfkGui()
        else
            destroyAfkGui()
        end
    end
}, "AntiAfk")

-- =========================================
-- SETTINGS
-- =========================================
TabSettings:CreateSection("Configurations")
TabSettings:CreateLabel({ Text = "Save and load your settings.", Style = 2 })
TabSettings:BuildConfigSection()

-- =========================================
-- INIT
-- =========================================
Luna:Notification({ Title = "kaw0ru lite", Content = "Loaded! v3.1 by Cosx  |  PCs: " .. #cachedPCs })
Luna:LoadAutoloadConfig()