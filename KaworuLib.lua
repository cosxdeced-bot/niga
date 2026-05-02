-- ╔══════════════════════════════════════════════════════════╗
-- ║           KaworuLib  v1.0  ·  by Cosx                   ║
-- ║           Dark theme · #5b5ef4 accent                   ║
-- ╚══════════════════════════════════════════════════════════╝

local KaworuLib = {}
KaworuLib.__index = KaworuLib

-- ─── Services ────────────────────────────────────────────────
local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")
local UserInput     = game:GetService("UserInputService")
local RunService    = game:GetService("RunService")
local CoreGui       = game:GetService("CoreGui")

local lp = Players.LocalPlayer
local mouse = lp:GetMouse()

-- ─── Palette ──────────────────────────────────────────────────
local C = {
    bg0      = Color3.fromRGB(10,  10,  14),   -- window bg
    bg1      = Color3.fromRGB(13,  13,  18),   -- tab body
    bg2      = Color3.fromRGB(18,  18,  26),   -- row hover / input
    bg3      = Color3.fromRGB(22,  22,  34),   -- toggle off / track
    border   = Color3.fromRGB(28,  28,  40),   -- general border
    accent   = Color3.fromRGB(91,  94,  244),  -- #5b5ef4
    accentDk = Color3.fromRGB(74,  77,  212),  -- darker accent
    accentLt = Color3.fromRGB(122, 125, 244),  -- lighter accent
    text1    = Color3.fromRGB(232, 232, 245),  -- primary text
    text2    = Color3.fromRGB(192, 192, 216),  -- secondary text
    text3    = Color3.fromRGB(90,  90,  120),  -- muted text
    text4    = Color3.fromRGB(46,  46,  72),   -- very muted / section label
    white    = Color3.fromRGB(255, 255, 255),
    -- badge colors
    badgePurpleBg   = Color3.fromRGB(22, 20, 58),
    badgePurpleTx   = Color3.fromRGB(128, 128, 232),
    badgeGreenBg    = Color3.fromRGB(12, 30, 18),
    badgeGreenTx    = Color3.fromRGB(74, 168, 112),
    badgeRedBg      = Color3.fromRGB(30, 14, 14),
    badgeRedTx      = Color3.fromRGB(192, 80, 80),
    badgeGrayBg     = Color3.fromRGB(18, 18, 22),
    badgeGrayTx     = Color3.fromRGB(80, 80, 104),
    badgeYellowBg   = Color3.fromRGB(30, 26, 8),
    badgeYellowTx   = Color3.fromRGB(176, 128, 32),
}

local BADGE_COLORS = {
    Purple = { bg = C.badgePurpleBg, tx = C.badgePurpleTx },
    Green  = { bg = C.badgeGreenBg,  tx = C.badgeGreenTx  },
    Red    = { bg = C.badgeRedBg,    tx = C.badgeRedTx    },
    Gray   = { bg = C.badgeGrayBg,   tx = C.badgeGrayTx   },
    Yellow = { bg = C.badgeYellowBg, tx = C.badgeYellowTx },
}

-- ─── Tween helper ─────────────────────────────────────────────
local function tween(obj, props, t, style, dir)
    local info = TweenInfo.new(t or 0.15, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    TweenService:Create(obj, info, props):Play()
end

-- ─── Create helper ────────────────────────────────────────────
local function new(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function frame(props, parent)
    props.BackgroundColor3 = props.BackgroundColor3 or Color3.new(0,0,0)
    props.BackgroundTransparency = props.BackgroundTransparency or (props.BackgroundColor3 == Color3.new(0,0,0) and 1 or 0)
    props.BorderSizePixel = props.BorderSizePixel or 0
    return new("Frame", props, parent)
end

local function label(props, parent)
    props.BackgroundTransparency = 1
    props.BorderSizePixel = 0
    props.Font = props.Font or Enum.Font.GothamMedium
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    return new("TextLabel", props, parent)
end

local function uiCorner(r, parent)
    return new("UICorner", { CornerRadius = UDim.new(0, r or 6) }, parent)
end

local function uiStroke(color, thickness, parent)
    return new("UIStroke", {
        Color = color or C.border,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, parent)
end

local function uiPadding(t, r, b, l, parent)
    return new("UIPadding", {
        PaddingTop    = UDim.new(0, t or 0),
        PaddingRight  = UDim.new(0, r or 0),
        PaddingBottom = UDim.new(0, b or 0),
        PaddingLeft   = UDim.new(0, l or 0),
    }, parent)
end

local function uiList(spacing, parent, dir, fill)
    return new("UIListLayout", {
        Padding           = UDim.new(0, spacing or 0),
        FillDirection     = dir or Enum.FillDirection.Vertical,
        HorizontalAlignment = fill or Enum.HorizontalAlignment.Left,
        SortOrder         = Enum.SortOrder.LayoutOrder,
    }, parent)
end

-- ─── Dragging ─────────────────────────────────────────────────
local function makeDraggable(topBar, window)
    local dragging, dragStart, startPos = false, nil, nil
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = window.Position
        end
    end)
    topBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInput.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            window.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
--  KaworuLib.new(config)
--    config.Title      string
--    config.SubTitle   string
--    config.Size       Vector2  (default 500, 400)
--    config.MinimizeKey Enum.KeyCode  (default LeftControl)
--    config.Position   UDim2
-- ═══════════════════════════════════════════════════════════════
function KaworuLib.new(config)
    local self = setmetatable({}, KaworuLib)
    config = config or {}

    local W  = config.Size and config.Size.X or 500
    local H  = config.Size and config.Size.Y or 400
    local minimizeKey = config.MinimizeKey or Enum.KeyCode.LeftControl

    -- ── ScreenGui
    local sg = new("ScreenGui", {
        Name            = "KaworuLib",
        ResetOnSpawn    = false,
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
    })
    pcall(function() sg.Parent = CoreGui end)
    if not sg.Parent then sg.Parent = lp.PlayerGui end
    self._gui = sg

    -- ── Main window frame
    local win = frame({
        Name = "Window",
        Size = UDim2.fromOffset(W, H),
        Position = config.Position or UDim2.new(0.5, -W/2, 0.5, -H/2),
        BackgroundColor3 = C.bg0,
        BackgroundTransparency = 0,
        ClipsDescendants = true,
    }, sg)
    uiCorner(10, win)
    uiStroke(C.border, 1, win)
    self._win = win

    -- ── Top bar
    local bar = frame({
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = C.bg0,
        BackgroundTransparency = 0,
    }, win)
    uiStroke(C.border, 1, bar)

    label({
        Text = config.Title or "KaworuLib",
        TextColor3 = C.text1,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        Size = UDim2.new(1, -90, 0, 18),
        Position = UDim2.new(0, 12, 0, 5),
    }, bar)

    label({
        Text = config.SubTitle or "",
        TextColor3 = C.text4,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        Size = UDim2.new(1, -90, 0, 14),
        Position = UDim2.new(0, 12, 0, 21),
    }, bar)

    -- Dots
    local dotColors = {Color3.fromRGB(255,95,86), Color3.fromRGB(255,189,46), Color3.fromRGB(39,201,63)}
    for i, col in ipairs(dotColors) do
        local d = frame({
            Size = UDim2.fromOffset(8,8),
            Position = UDim2.new(1, -16 - (3-i)*14, 0.5, -4),
            BackgroundColor3 = col,
            BackgroundTransparency = 0,
        }, bar)
        uiCorner(99, d)
    end

    makeDraggable(bar, win)

    -- ── Tab bar
    local tabBar = frame({
        Name = "TabBar",
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 36),
        BackgroundColor3 = Color3.fromRGB(8,8,12),
        BackgroundTransparency = 0,
    }, win)
    uiStroke(C.border, 1, tabBar)
    uiList(0, tabBar, Enum.FillDirection.Horizontal)
    uiPadding(0, 0, 0, 4, tabBar)
    self._tabBar = tabBar

    -- ── Tab content area
    local contentArea = frame({
        Name = "Content",
        Size = UDim2.new(1, 0, 1, -66),
        Position = UDim2.new(0, 0, 0, 66),
        BackgroundColor3 = C.bg1,
        BackgroundTransparency = 0,
        ClipsDescendants = true,
    }, win)
    self._content = contentArea

    -- ── Minimize key
    self._visible = true
    UserInput.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == minimizeKey then
            self._visible = not self._visible
            win.Visible = self._visible
        end
    end)

    self._tabs    = {}
    self._tabBtns = {}
    self._activeTab = nil

    return self
end

-- ── Notify (floating toast) ────────────────────────────────────
function KaworuLib:Notify(config)
    config = config or {}
    local toastH = 52

    local host = frame({
        Size = UDim2.fromOffset(220, toastH),
        Position = UDim2.new(1, -230, 1, -toastH - 10),
        BackgroundColor3 = Color3.fromRGB(14, 14, 22),
        BackgroundTransparency = 0,
        ZIndex = 50,
    }, self._gui)
    uiCorner(8, host)
    uiStroke(C.border, 1, host)

    -- accent left bar
    frame({
        Size = UDim2.new(0, 2, 1, 0),
        BackgroundColor3 = C.accent,
        BackgroundTransparency = 0,
        ZIndex = 51,
    }, host)

    label({
        Text = config.Title or "KaworuLib",
        TextColor3 = C.text1,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Size = UDim2.new(1, -20, 0, 16),
        Position = UDim2.new(0, 10, 0, 8),
        ZIndex = 52,
    }, host)

    label({
        Text = config.Content or "",
        TextColor3 = C.text3,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        Size = UDim2.new(1, -20, 0, 14),
        Position = UDim2.new(0, 10, 0, 26),
        ZIndex = 52,
    }, host)

    -- slide in
    host.Position = UDim2.new(1, 10, 1, -toastH - 10)
    tween(host, { Position = UDim2.new(1, -230, 1, -toastH - 10) }, 0.3, Enum.EasingStyle.Back)

    task.delay(config.Duration or 4, function()
        tween(host, { Position = UDim2.new(1, 10, 1, -toastH - 10) }, 0.25)
        task.wait(0.3)
        host:Destroy()
    end)
end

-- ── AddTab ────────────────────────────────────────────────────
function KaworuLib:AddTab(config)
    config = config or {}
    local tabName = config.Title or "Tab"

    -- Tab button
    local btn = new("TextButton", {
        Text = tabName,
        TextColor3 = C.text4,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, self._tabBar)
    uiPadding(0, 10, 0, 10, btn)

    -- Active underline
    local underline = frame({
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = C.accent,
        BackgroundTransparency = 1,
    }, btn)

    -- Tab scroll frame
    local sf = new("ScrollingFrame", {
        Name = tabName,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = C.accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, self._content)
    uiList(0, sf)
    uiPadding(8, 0, 8, 0, sf)

    local tab = {
        _frame = sf,
        _btn   = btn,
        _under = underline,
        _lib   = self,
    }
    setmetatable(tab, { __index = Tab })

    table.insert(self._tabs, tab)
    table.insert(self._tabBtns, btn)

    btn.MouseButton1Click:Connect(function()
        self:_selectTab(tab)
    end)

    if #self._tabs == 1 then
        self:_selectTab(tab)
    end

    return tab
end

function KaworuLib:_selectTab(targetTab)
    for _, t in ipairs(self._tabs) do
        t._frame.Visible = (t == targetTab)
        local active = (t == targetTab)
        tween(t._btn, { TextColor3 = active and C.text1 or C.text4 }, 0.12)
        tween(t._under, { BackgroundTransparency = active and 0 or 1 }, 0.12)
    end
    self._activeTab = targetTab
end

-- ═══════════════════════════════════════════════════════════════
--  Tab prototype  (all AddXxx methods live here)
-- ═══════════════════════════════════════════════════════════════
Tab = {}
Tab.__index = Tab

-- ── Internal: container for a control row ────────────────────
local function makeRow(parent)
    local r = frame({
        Size = UDim2.new(1, 0, 0, 34),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.bg1,
        BackgroundTransparency = 0,
    }, parent)
    uiPadding(5, 8, 5, 8, r)
    return r
end

local function rowHover(row)
    row.MouseEnter:Connect(function()
        tween(row, { BackgroundColor3 = C.bg2 }, 0.1)
    end)
    row.MouseLeave:Connect(function()
        tween(row, { BackgroundColor3 = C.bg1 }, 0.1)
    end)
end

-- ── AddSection ────────────────────────────────────────────────
function Tab:AddSection(title)
    local sec = frame({
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundColor3 = C.bg1,
        BackgroundTransparency = 0,
    }, self._frame)
    uiPadding(0, 8, 0, 10, sec)

    label({
        Text = string.upper(title or "Section"),
        TextColor3 = C.text4,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        Size = UDim2.new(1, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, sec)

    -- thin separator below label
    frame({
        Size = UDim2.new(1, -18, 0, 1),
        Position = UDim2.new(0, 10, 1, -1),
        BackgroundColor3 = C.border,
        BackgroundTransparency = 0,
    }, sec)
end

-- ── AddToggle ─────────────────────────────────────────────────
function Tab:AddToggle(id, config)
    config = config or {}
    local state = config.Default or false

    local row = makeRow(self._frame)
    row.Size = UDim2.new(1, 0, 0, 36)
    rowHover(row)

    label({
        Text = config.Title or "Toggle",
        TextColor3 = C.text2,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        Size = UDim2.new(1, -44, 0, 16),
        Position = UDim2.new(0, 0, 0, state and 4 or 10),
    }, row)

    if config.Description then
        label({
            Text = config.Description,
            TextColor3 = C.text3,
            Font = Enum.Font.Gotham,
            TextSize = 10,
            Size = UDim2.new(1, -44, 0, 14),
            Position = UDim2.new(0, 0, 0, 20),
        }, row)
        row.Size = UDim2.new(1, 0, 0, 44)
    end

    -- Toggle pill
    local pill = frame({
        Size = UDim2.fromOffset(32, 18),
        Position = UDim2.new(1, -32, 0.5, -9),
        BackgroundColor3 = state and C.accent or C.bg3,
        BackgroundTransparency = 0,
    }, row)
    uiCorner(9, pill)
    uiStroke(state and C.accentDk or C.border, 1, pill)

    local knob = frame({
        Size = UDim2.fromOffset(14, 14),
        Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
        BackgroundColor3 = C.white,
        BackgroundTransparency = 0,
    }, pill)
    uiCorner(99, knob)

    local function setState(v)
        state = v
        tween(pill, { BackgroundColor3 = v and C.accent or C.bg3 }, 0.15)
        tween(knob, { Position = v and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7) }, 0.15)
        if config.Callback then config.Callback(v) end
    end

    row.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            setState(not state)
        end
    end)

    -- Return controller
    local ctrl = { Value = state }
    function ctrl:Set(v) setState(v) end
    if id then getgenv()[id] = ctrl end
    return ctrl
end

-- ── AddSlider ─────────────────────────────────────────────────
function Tab:AddSlider(id, config)
    config = config or {}
    local min  = config.Min     or 0
    local max  = config.Max     or 100
    local val  = config.Default or min
    local rnd  = config.Rounding or 0
    local suffix = config.Suffix or ""

    local container = frame({
        Size = UDim2.new(1, 0, 0, 54),
        BackgroundColor3 = C.bg1,
        BackgroundTransparency = 0,
    }, self._frame)
    uiPadding(6, 8, 6, 8, container)
    rowHover(container)

    -- Header row
    label({
        Text = config.Title or "Slider",
        TextColor3 = C.text2,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        Size = UDim2.new(0.7, 0, 0, 16),
        Position = UDim2.new(0, 0, 0, 0),
    }, container)

    local valLabel = label({
        Text = tostring(rnd == 0 and math.floor(val) or math.floor(val*10^rnd)/10^rnd) .. suffix,
        TextColor3 = C.accentLt,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Size = UDim2.new(0.3, 0, 0, 16),
        Position = UDim2.new(0.7, 0, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Right,
    }, container)

    -- Track
    local track = frame({
        Size = UDim2.new(1, 0, 0, 4),
        Position = UDim2.new(0, 0, 0, 26),
        BackgroundColor3 = C.bg3,
        BackgroundTransparency = 0,
    }, container)
    uiCorner(2, track)

    local fill = frame({
        Size = UDim2.new((val-min)/(max-min), 0, 1, 0),
        BackgroundColor3 = C.accent,
        BackgroundTransparency = 0,
    }, track)
    uiCorner(2, fill)

    local thumb = frame({
        Size = UDim2.fromOffset(12, 12),
        Position = UDim2.new((val-min)/(max-min), -6, 0.5, -6),
        BackgroundColor3 = Color3.fromRGB(230, 230, 255),
        BackgroundTransparency = 0,
    }, track)
    uiCorner(99, thumb)
    uiStroke(C.accent, 2, thumb)

    local function setVal(px)
        local rel = math.clamp((px - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        val = min + (max - min) * rel
        local display = rnd == 0 and math.floor(val) or math.floor(val*10^rnd)/10^rnd
        val = display
        valLabel.Text = tostring(display) .. suffix
        tween(fill,  { Size = UDim2.new(rel, 0, 1, 0) }, 0.06)
        tween(thumb, { Position = UDim2.new(rel, -6, 0.5, -6) }, 0.06)
        if config.Callback then config.Callback(val) end
    end

    local dragging = false
    thumb.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    UserInput.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInput.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            setVal(inp.Position.X)
        end
    end)
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            setVal(inp.Position.X)
        end
    end)

    local ctrl = { Value = val }
    function ctrl:Set(v)
        val = math.clamp(v, min, max)
        local rel = (val-min)/(max-min)
        fill.Size  = UDim2.new(rel, 0, 1, 0)
        thumb.Position = UDim2.new(rel, -6, 0.5, -6)
        valLabel.Text = tostring(val) .. suffix
    end
    if id then getgenv()[id] = ctrl end
    return ctrl
end

-- ── AddDropdown ───────────────────────────────────────────────
function Tab:AddDropdown(id, config)
    config = config or {}
    local values  = config.Values  or {}
    local selected = config.Default or values[1]
    local open = false

    local container = frame({
        Size = UDim2.new(1, 0, 0, 54),
        BackgroundColor3 = C.bg1,
        BackgroundTransparency = 0,
        ClipsDescendants = false,
        ZIndex = 10,
    }, self._frame)
    uiPadding(6, 8, 6, 8, container)

    label({
        Text = config.Title or "Dropdown",
        TextColor3 = C.text2,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.new(0, 0, 0, 0),
        ZIndex = 11,
    }, container)

    -- Box
    local box = new("TextButton", {
        Text = "",
        Size = UDim2.new(1, 0, 0, 26),
        Position = UDim2.new(0, 0, 0, 20),
        BackgroundColor3 = C.bg2,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = 12,
    }, container)
    uiCorner(6, box)
    uiStroke(C.border, 1, box)

    label({
        Text = tostring(selected),
        TextColor3 = C.text1,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        Size = UDim2.new(1, -24, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        ZIndex = 13,
    }, box)

    label({
        Text = "▾",
        TextColor3 = C.text4,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        Size = UDim2.new(0, 16, 1, 0),
        Position = UDim2.new(1, -20, 0, 0),
        ZIndex = 13,
        TextXAlignment = Enum.TextXAlignment.Center,
    }, box)

    -- Dropdown menu
    local menu = frame({
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 1, 3),
        BackgroundColor3 = C.bg2,
        BackgroundTransparency = 0,
        ZIndex = 20,
        Visible = false,
        ClipsDescendants = true,
    }, box)
    uiCorner(6, menu)
    uiStroke(C.border, 1, menu)
    uiList(0, menu)

    for _, v in ipairs(values) do
        local item = new("TextButton", {
            Text = tostring(v),
            TextColor3 = v == selected and C.accentLt or C.text3,
            Font = Enum.Font.GothamMedium,
            TextSize = 11,
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 21,
        }, menu)
        uiPadding(0, 0, 0, 8, item)

        item.MouseEnter:Connect(function()
            tween(item, { BackgroundTransparency = 0, BackgroundColor3 = C.bg3 }, 0.1)
        end)
        item.MouseLeave:Connect(function()
            tween(item, { BackgroundTransparency = 1 }, 0.1)
        end)
        item.MouseButton1Click:Connect(function()
            selected = v
            box:FindFirstChildWhichIsA("TextLabel").Text = tostring(v)
            for _, ch in ipairs(menu:GetChildren()) do
                if ch:IsA("TextButton") then
                    tween(ch, { TextColor3 = ch.Text == tostring(v) and C.accentLt or C.text3 }, 0.1)
                end
            end
            if config.Callback then config.Callback(v) end
            -- close
            open = false
            tween(menu, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
            task.delay(0.15, function() menu.Visible = false end)
        end)
    end

    local itemH = 26
    box.MouseButton1Click:Connect(function()
        open = not open
        menu.Visible = true
        tween(menu, { Size = UDim2.new(1, 0, 0, open and itemH * #values or 0) }, 0.2, Enum.EasingStyle.Back)
        if not open then
            task.delay(0.2, function() menu.Visible = false end)
        end
    end)

    local ctrl = { Value = selected }
    function ctrl:Set(v)
        selected = v
        box:FindFirstChildWhichIsA("TextLabel").Text = tostring(v)
        if config.Callback then config.Callback(v) end
    end
    if id then getgenv()[id] = ctrl end
    return ctrl
end

-- ── AddTextbox ────────────────────────────────────────────────
function Tab:AddTextbox(id, config)
    config = config or {}

    local container = frame({
        Size = UDim2.new(1, 0, 0, 54),
        BackgroundColor3 = C.bg1,
        BackgroundTransparency = 0,
    }, self._frame)
    uiPadding(6, 8, 6, 8, container)

    label({
        Text = config.Title or "Input",
        TextColor3 = C.text2,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        Size = UDim2.new(1, 0, 0, 16),
    }, container)

    local inp = new("TextBox", {
        Text = config.Default or "",
        PlaceholderText = config.Placeholder or "",
        TextColor3 = C.text1,
        PlaceholderColor3 = C.text4,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        Size = UDim2.new(1, 0, 0, 26),
        Position = UDim2.new(0, 0, 0, 20),
        BackgroundColor3 = C.bg2,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, container)
    uiCorner(6, inp)
    uiStroke(C.border, 1, inp)
    uiPadding(0, 0, 0, 8, inp)

    inp.Focused:Connect(function()   tween(inp:FindFirstChildOfClass("UIStroke"), { Color = C.accent }, 0.15) end)
    inp.FocusLost:Connect(function(enter)
        tween(inp:FindFirstChildOfClass("UIStroke"), { Color = C.border }, 0.15)
        if config.Callback then config.Callback(inp.Text, enter) end
    end)

    local ctrl = { Value = inp.Text }
    function ctrl:Set(v) inp.Text = tostring(v) end
    if id then getgenv()[id] = ctrl end
    return ctrl
end

-- ── AddButton ─────────────────────────────────────────────────
function Tab:AddButton(config)
    config = config or {}
    local primary = config.Primary or false

    local row = frame({
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = C.bg1,
        BackgroundTransparency = 0,
    }, self._frame)
    uiPadding(5, 8, 5, 8, row)

    local btn = new("TextButton", {
        Text = config.Title or "Button",
        TextColor3 = primary and C.accentLt or C.text3,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = primary and Color3.fromRGB(26,26,64) or C.bg2,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
    }, row)
    uiCorner(6, btn)
    uiStroke(primary and C.accentDk or C.border, 1, btn)

    btn.MouseEnter:Connect(function()
        tween(btn, { BackgroundColor3 = primary and Color3.fromRGB(34,34,74) or C.bg3, TextColor3 = C.text1 }, 0.12)
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, { BackgroundColor3 = primary and Color3.fromRGB(26,26,64) or C.bg2, TextColor3 = primary and C.accentLt or C.text3 }, 0.12)
    end)
    btn.MouseButton1Down:Connect(function()
        tween(btn, { Size = UDim2.new(0.98, 0, 0.92, 0), Position = UDim2.new(0.01, 0, 0.04, 0) }, 0.08)
    end)
    btn.MouseButton1Up:Connect(function()
        tween(btn, { Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0) }, 0.08)
        if config.Callback then config.Callback() end
    end)
end

-- ── AddBadge ──────────────────────────────────────────────────
function Tab:AddBadge(config)
    config = config or {}
    local scheme = BADGE_COLORS[config.Color or "Purple"] or BADGE_COLORS["Purple"]

    local container = frame({
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = C.bg1,
        BackgroundTransparency = 0,
    }, self._frame)
    uiPadding(4, 8, 4, 8, container)
    uiList(6, container, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left)

    local badge = frame({
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = scheme.bg,
        BackgroundTransparency = 0,
    }, container)
    uiCorner(4, badge)
    uiStroke(Color3.fromRGB(
        math.floor(scheme.bg.R*255 + 20),
        math.floor(scheme.bg.G*255 + 20),
        math.floor(scheme.bg.B*255 + 20)
    ), 1, badge)
    uiPadding(0, 10, 0, 10, badge)

    label({
        Text = config.Title or "Badge",
        TextColor3 = scheme.tx,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        Size = UDim2.new(0, 60, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
    }, badge)

    if config.Label then
        label({
            Text = config.Label,
            TextColor3 = C.text2,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            Size = UDim2.new(1, -80, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
        }, container)
    end
end

-- ── AddProgressBar ────────────────────────────────────────────
function Tab:AddProgressBar(id, config)
    config = config or {}
    local val = math.clamp(config.Default or 0, 0, 100)

    local container = frame({
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = C.bg1,
        BackgroundTransparency = 0,
    }, self._frame)
    uiPadding(6, 8, 6, 8, container)

    label({
        Text = config.Title or "Progress",
        TextColor3 = C.text2,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        Size = UDim2.new(0.7, 0, 0, 16),
    }, container)

    local pctLbl = label({
        Text = tostring(math.floor(val)) .. "%",
        TextColor3 = C.accentLt,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Size = UDim2.new(0.3, 0, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Right,
    }, container)

    local track = frame({
        Size = UDim2.new(1, 0, 0, 4),
        Position = UDim2.new(0, 0, 0, 24),
        BackgroundColor3 = C.bg3,
        BackgroundTransparency = 0,
    }, container)
    uiCorner(2, track)

    local fill = frame({
        Size = UDim2.new(val/100, 0, 1, 0),
        BackgroundColor3 = C.accent,
        BackgroundTransparency = 0,
    }, track)
    uiCorner(2, fill)

    local ctrl = { Value = val }
    function ctrl:Set(v)
        v = math.clamp(v, 0, 100)
        self.Value = v
        pctLbl.Text = tostring(math.floor(v)) .. "%"
        tween(fill, { Size = UDim2.new(v/100, 0, 1, 0) }, 0.3)
    end
    if id then getgenv()[id] = ctrl end
    return ctrl
end

-- ── AddSeparator ──────────────────────────────────────────────
function Tab:AddSeparator()
    frame({
        Size = UDim2.new(1, -16, 0, 1),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundColor3 = C.border,
        BackgroundTransparency = 0,
    }, frame({
        Size = UDim2.new(1, 0, 0, 9),
        BackgroundColor3 = C.bg1,
        BackgroundTransparency = 0,
    }, self._frame))
end

-- ── AddLabel ──────────────────────────────────────────────────
function Tab:AddLabel(text, color)
    local container = frame({
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundColor3 = C.bg1,
        BackgroundTransparency = 0,
    }, self._frame)
    uiPadding(5, 8, 5, 8, container)

    local lbl = label({
        Text = text or "",
        TextColor3 = color or C.text3,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        Size = UDim2.new(1, 0, 1, 0),
    }, container)

    local ctrl = {}
    function ctrl:Set(t, c)
        lbl.Text = t or lbl.Text
        if c then lbl.TextColor3 = c end
    end
    return ctrl
end

-- ─────────────────────────────────────────────────────────────
return KaworuLib
