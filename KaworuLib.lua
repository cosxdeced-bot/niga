-- ╔══════════════════════════════════════════════╗
-- ║           KaworuUI  ·  v1.0                  ║
-- ║   Monochrome · Rounded · Lightweight         ║
-- ╚══════════════════════════════════════════════╝

local KaworuUI = {}
KaworuUI.__index = KaworuUI

-- ════════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════════
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")
local Players        = game:GetService("Players")
local LocalPlayer    = Players.LocalPlayer

-- ════════════════════════════════════════════
--  THEME
-- ════════════════════════════════════════════
local Theme = {
    -- Window
    Background      = Color3.fromRGB(12,  12,  12),
    Surface         = Color3.fromRGB(20,  20,  20),
    SurfaceHover    = Color3.fromRGB(28,  28,  28),
    Border          = Color3.fromRGB(40,  40,  40),
    -- Accent
    Accent          = Color3.fromRGB(255, 255, 255),
    AccentDim       = Color3.fromRGB(160, 160, 160),
    -- Text
    TextPrimary     = Color3.fromRGB(255, 255, 255),
    TextSecondary   = Color3.fromRGB(140, 140, 140),
    TextDisabled    = Color3.fromRGB(70,  70,  70),
    -- Toggle
    ToggleOn        = Color3.fromRGB(255, 255, 255),
    ToggleOff       = Color3.fromRGB(50,  50,  50),
    ToggleKnob      = Color3.fromRGB(12,  12,  12),
    -- Slider
    SliderFill      = Color3.fromRGB(255, 255, 255),
    SliderTrack     = Color3.fromRGB(40,  40,  40),
    -- Tab
    TabActive       = Color3.fromRGB(255, 255, 255),
    TabInactive     = Color3.fromRGB(30,  30,  30),
    TabTextActive   = Color3.fromRGB(12,  12,  12),
    TabTextInactive = Color3.fromRGB(140, 140, 140),
    -- Notify
    NotifyBg        = Color3.fromRGB(22,  22,  22),
    NotifyBorder    = Color3.fromRGB(60,  60,  60),
    -- Corner radius
    CornerWindow    = 14,
    CornerElement   = 8,
    CornerSmall     = 5,
}

-- ════════════════════════════════════════════
--  TWEEN HELPERS
-- ════════════════════════════════════════════
local function tween(obj, props, duration, style, direction)
    local info = TweenInfo.new(
        duration or 0.18,
        style     or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function tweenColor(obj, prop, color, duration)
    tween(obj, { [prop] = color }, duration or 0.15)
end

-- ════════════════════════════════════════════
--  GUI UTILITY
-- ════════════════════════════════════════════
local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    if parent then obj.Parent = parent end
    return obj
end

local function corner(radius, parent)
    return make("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function stroke(thickness, color, parent)
    return make("UIStroke", {
        Thickness    = thickness or 1,
        Color        = color or Theme.Border,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function padding(top, right, bottom, left, parent)
    return make("UIPadding", {
        PaddingTop    = UDim.new(0, top    or 0),
        PaddingRight  = UDim.new(0, right  or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft   = UDim.new(0, left   or 0),
    }, parent)
end

local function listLayout(parent, gap, dir, ha, va)
    return make("UIListLayout", {
        Padding          = UDim.new(0, gap or 6),
        FillDirection    = dir or Enum.FillDirection.Vertical,
        HorizontalAlignment = ha or Enum.HorizontalAlignment.Left,
        VerticalAlignment   = va or Enum.VerticalAlignment.Top,
        SortOrder        = Enum.SortOrder.LayoutOrder,
    }, parent)
end

-- ════════════════════════════════════════════
--  DRAGGING
-- ════════════════════════════════════════════
local function makeDraggable(frame, handle)
    local dragging, dragStart, startPos = false, nil, nil
    handle = handle or frame

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end)

    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ════════════════════════════════════════════
--  NOTIFICATION SYSTEM
-- ════════════════════════════════════════════
local NotifyHolder

local function ensureNotifyHolder(screenGui)
    if NotifyHolder and NotifyHolder.Parent then return end
    NotifyHolder = make("Frame", {
        Name            = "NotifyHolder",
        Size            = UDim2.new(0, 300, 1, 0),
        Position        = UDim2.new(1, -310, 0, 0),
        BackgroundTransparency = 1,
        ZIndex          = 100,
    }, screenGui)
    local ll = listLayout(NotifyHolder, 8, Enum.FillDirection.Vertical,
        Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom)
    ll.VerticalAlignment = Enum.VerticalAlignment.Bottom
    padding(0, 0, 16, 0, NotifyHolder)
end

local function notify(screenGui, opts)
    opts = opts or {}
    ensureNotifyHolder(screenGui)

    local card = make("Frame", {
        Name                   = "Notify",
        Size                   = UDim2.new(1, 0, 0, 64),
        BackgroundColor3       = Theme.NotifyBg,
        BackgroundTransparency = 1,
        ClipsDescendants       = true,
        ZIndex                 = 100,
        LayoutOrder            = -os.clock(),
    }, NotifyHolder)
    corner(Theme.CornerElement, card)
    stroke(1, Theme.NotifyBorder, card)
    padding(10, 14, 10, 14, card)

    -- left accent bar
    make("Frame", {
        Size             = UDim2.new(0, 3, 1, -20),
        Position         = UDim2.new(0, 0, 0, 10),
        BackgroundColor3 = Theme.Accent,
        ZIndex           = 101,
    }, card)

    local vstack = make("Frame", {
        Size             = UDim2.new(1, -14, 1, 0),
        Position         = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        ZIndex           = 101,
    }, card)
    listLayout(vstack, 2)

    make("TextLabel", {
        Text      = opts.Title or "KaworuUI",
        TextColor3 = Theme.TextPrimary,
        Font      = Enum.Font.GothamBold,
        TextSize  = 13,
        Size      = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex    = 101,
    }, vstack)

    make("TextLabel", {
        Text      = opts.Content or "",
        TextColor3 = Theme.TextSecondary,
        Font      = Enum.Font.Gotham,
        TextSize  = 11,
        Size      = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex    = 101,
        TextWrapped = true,
    }, vstack)

    -- animate in
    tween(card, { BackgroundTransparency = 0 }, 0.25)
    task.delay(opts.Duration or 4, function()
        tween(card, { BackgroundTransparency = 1 }, 0.3)
        task.wait(0.32)
        card:Destroy()
    end)
end

-- ════════════════════════════════════════════
--  WINDOW
-- ════════════════════════════════════════════
function KaworuUI.new(opts)
    opts = opts or {}
    local self = setmetatable({}, KaworuUI)

    self._tabs        = {}
    self._activeTab   = nil
    self._minimized   = false
    self._minimizeKey = opts.MinimizeKey or Enum.KeyCode.RightControl

    -- ScreenGui
    local sg = make("ScreenGui", {
        Name            = "KaworuUI",
        ResetOnSpawn    = false,
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset  = true,
    })
    if syn and syn.protect_gui then
        syn.protect_gui(sg)
        sg.Parent = game:GetService("CoreGui")
    elseif gethui then
        sg.Parent = gethui()
    else
        sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    self._sg = sg

    -- Main window frame
    local vp = sg.AbsoluteSize
    local win = make("Frame", {
        Name             = "Window",
        Size             = UDim2.new(0, opts.Size and opts.Size.X or 500,
                                     0, opts.Size and opts.Size.Y or 460),
        Position         = UDim2.new(0.5, -(opts.Size and opts.Size.X or 500)/2,
                                     0.5, -(opts.Size and opts.Size.Y or 460)/2),
        BackgroundColor3 = Theme.Background,
        ClipsDescendants = true,
    }, sg)
    corner(Theme.CornerWindow, win)
    stroke(1, Theme.Border, win)
    self._win = win

    -- ── TITLEBAR ────────────────────────────
    local titlebar = make("Frame", {
        Name             = "Titlebar",
        Size             = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = Theme.Surface,
    }, win)
    corner(Theme.CornerWindow, titlebar)
    -- Patch bottom corners flat
    make("Frame", {
        Size             = UDim2.new(1, 0, 0, Theme.CornerWindow),
        Position         = UDim2.new(0, 0, 1, -Theme.CornerWindow),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel  = 0,
    }, titlebar)

    make("TextLabel", {
        Text       = opts.Title or "KaworuUI",
        TextColor3 = Theme.TextPrimary,
        Font       = Enum.Font.GothamBold,
        TextSize   = 14,
        Size       = UDim2.new(1, -90, 1, 0),
        Position   = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, titlebar)

    if opts.SubTitle then
        make("TextLabel", {
            Text       = opts.SubTitle,
            TextColor3 = Theme.TextSecondary,
            Font       = Enum.Font.Gotham,
            TextSize   = 11,
            Size       = UDim2.new(1, -90, 1, 0),
            Position   = UDim2.new(0, 16, 0, 16),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, titlebar)
    end

    -- close button
    local closeBtn = make("TextButton", {
        Text       = "✕",
        TextColor3 = Theme.TextSecondary,
        Font       = Enum.Font.GothamBold,
        TextSize   = 13,
        Size       = UDim2.new(0, 28, 0, 28),
        Position   = UDim2.new(1, -38, 0.5, -14),
        BackgroundColor3 = Theme.SurfaceHover,
        AutoButtonColor = false,
    }, titlebar)
    corner(7, closeBtn)

    closeBtn.MouseEnter:Connect(function()
        tweenColor(closeBtn, "TextColor3", Color3.fromRGB(255,80,80))
    end)
    closeBtn.MouseLeave:Connect(function()
        tweenColor(closeBtn, "TextColor3", Theme.TextSecondary)
    end)
    closeBtn.MouseButton1Click:Connect(function()
        tween(win, { Size = UDim2.new(0, win.AbsoluteSize.X, 0, 0),
                     Position = UDim2.new(
                         win.Position.X.Scale,
                         win.Position.X.Offset,
                         win.Position.Y.Scale,
                         win.Position.Y.Offset + win.AbsoluteSize.Y/2
                     ) }, 0.3)
        task.delay(0.35, function() sg:Destroy() end)
    end)

    makeDraggable(win, titlebar)

    -- separator under titlebar
    make("Frame", {
        Size             = UDim2.new(1, -32, 0, 1),
        Position         = UDim2.new(0, 16, 0, 44),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel  = 0,
    }, win)

    -- ── TAB BAR ─────────────────────────────
    local tabBar = make("ScrollingFrame", {
        Name                   = "TabBar",
        Size                   = UDim2.new(1, -32, 0, 34),
        Position               = UDim2.new(0, 16, 0, 52),
        BackgroundTransparency = 1,
        ScrollBarThickness     = 0,
        CanvasSize             = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize    = Enum.AutomaticSize.X,
        ScrollingDirection     = Enum.ScrollingDirection.X,
    }, win)
    listLayout(tabBar, 4, Enum.FillDirection.Horizontal,
        Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
    self._tabBar = tabBar

    -- second separator under tab bar
    make("Frame", {
        Size             = UDim2.new(1, -32, 0, 1),
        Position         = UDim2.new(0, 16, 0, 93),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel  = 0,
    }, win)

    -- ── CONTENT AREA ────────────────────────
    local content = make("ScrollingFrame", {
        Name                   = "Content",
        Size                   = UDim2.new(1, -32, 1, -106),
        Position               = UDim2.new(0, 16, 0, 101),
        BackgroundTransparency = 1,
        ScrollBarThickness     = 3,
        ScrollBarImageColor3   = Theme.Border,
        CanvasSize             = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize    = Enum.AutomaticSize.Y,
        ClipsDescendants       = true,
    }, win)
    self._content = content

    -- minimize keybind
    UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == self._minimizeKey then
            self:_toggleMinimize()
        end
    end)

    -- notify helper on self
    self._notify = function(o) notify(sg, o) end

    return self
end

function KaworuUI:_toggleMinimize()
    self._minimized = not self._minimized
    if self._minimized then
        tween(self._win, { Size = UDim2.new(0, self._win.AbsoluteSize.X, 0, 44) }, 0.3)
    else
        tween(self._win, { Size = UDim2.new(0, self._win.AbsoluteSize.X, 0,
            self._winFullHeight or 460) }, 0.3)
    end
end

function KaworuUI:Notify(opts)
    self._notify(opts)
end

-- ════════════════════════════════════════════
--  TAB
-- ════════════════════════════════════════════
function KaworuUI:AddTab(opts)
    opts = opts or {}
    local Tab = {}
    Tab._elements = {}

    local tabBtn = make("TextButton", {
        Text             = opts.Title or "Tab",
        TextColor3       = Theme.TabTextInactive,
        Font             = Enum.Font.GothamSemibold,
        TextSize         = 12,
        Size             = UDim2.new(0, 0, 1, 0),
        AutomaticSize    = Enum.AutomaticSize.X,
        BackgroundColor3 = Theme.TabInactive,
        AutoButtonColor  = false,
    }, self._tabBar)
    corner(Theme.CornerSmall, tabBtn)
    padding(0, 12, 0, 12, tabBtn)

    -- tab content frame
    local tabFrame = make("Frame", {
        Name             = "Tab_" .. (opts.Title or ""),
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible          = false,
    }, self._content)
    listLayout(tabFrame, 6)
    Tab._frame = tabFrame

    local function activate()
        -- deactivate others
        for _, t in ipairs(self._tabs) do
            tween(t._btn, { BackgroundColor3 = Theme.TabInactive }, 0.15)
            tweenColor(t._btn, "TextColor3", Theme.TabTextInactive)
            t._frame.Visible = false
        end
        tween(tabBtn, { BackgroundColor3 = Theme.TabActive }, 0.15)
        tweenColor(tabBtn, "TextColor3", Theme.TabTextActive)
        tabFrame.Visible = true
        self._activeTab  = Tab
    end

    tabBtn.MouseButton1Click:Connect(activate)
    Tab._btn = tabBtn

    table.insert(self._tabs, Tab)
    if #self._tabs == 1 then
        activate()
    end

    -- ════ ELEMENT BUILDERS ════

    -- ── SECTION ─────────────────────────────
    function Tab:AddSection(title)
        local sec = make("Frame", {
            Size             = UDim2.new(1, 0, 0, 0),
            AutomaticSize    = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
        }, tabFrame)
        listLayout(sec, 4)

        local label = make("TextLabel", {
            Text       = (title or ""):upper(),
            TextColor3 = Theme.TextDisabled,
            Font       = Enum.Font.GothamBold,
            TextSize   = 10,
            Size       = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, sec)

        local divider = make("Frame", {
            Size             = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = Theme.Border,
            BorderSizePixel  = 0,
        }, sec)
    end

    -- ── LABEL ────────────────────────────────
    function Tab:AddLabel(text)
        make("TextLabel", {
            Text       = text or "",
            TextColor3 = Theme.TextSecondary,
            Font       = Enum.Font.Gotham,
            TextSize   = 12,
            Size       = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, tabFrame)
    end

    -- ── SEPARATOR ────────────────────────────
    function Tab:AddSeparator()
        make("Frame", {
            Size             = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = Theme.Border,
            BorderSizePixel  = 0,
        }, tabFrame)
    end

    -- ── BUTTON ───────────────────────────────
    function Tab:AddButton(opts)
        opts = opts or {}
        local btn = make("TextButton", {
            Text             = opts.Title or "Button",
            TextColor3       = Theme.TextPrimary,
            Font             = Enum.Font.GothamSemibold,
            TextSize         = 13,
            Size             = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = Theme.Surface,
            AutoButtonColor  = false,
        }, tabFrame)
        corner(Theme.CornerElement, btn)
        stroke(1, Theme.Border, btn)

        btn.MouseEnter:Connect(function()
            tween(btn, { BackgroundColor3 = Theme.SurfaceHover }, 0.12)
        end)
        btn.MouseLeave:Connect(function()
            tween(btn, { BackgroundColor3 = Theme.Surface }, 0.12)
        end)
        btn.MouseButton1Down:Connect(function()
            tween(btn, { BackgroundColor3 = Theme.Border }, 0.06)
        end)
        btn.MouseButton1Up:Connect(function()
            tween(btn, { BackgroundColor3 = Theme.SurfaceHover }, 0.1)
            if opts.Callback then pcall(opts.Callback) end
        end)
        btn.MouseButton1Click:Connect(function()
            if opts.Callback then pcall(opts.Callback) end
        end)
    end

    -- ── TOGGLE ───────────────────────────────
    function Tab:AddToggle(id, opts)
        opts = opts or {}
        local state = opts.Default or false

        local row = make("Frame", {
            Size             = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = Theme.Surface,
        }, tabFrame)
        corner(Theme.CornerElement, row)
        stroke(1, Theme.Border, row)
        padding(0, 12, 0, 12, row)

        make("TextLabel", {
            Text       = opts.Title or id or "Toggle",
            TextColor3 = Theme.TextPrimary,
            Font       = Enum.Font.Gotham,
            TextSize   = 13,
            Size       = UDim2.new(1, -56, 1, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, row)

        local track = make("Frame", {
            Size             = UDim2.new(0, 40, 0, 22),
            Position         = UDim2.new(1, -40, 0.5, -11),
            BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff,
        }, row)
        corner(11, track)

        local knob = make("Frame", {
            Size             = UDim2.new(0, 16, 0, 16),
            Position         = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
            BackgroundColor3 = Theme.ToggleKnob,
        }, track)
        corner(8, knob)

        local function setToggle(val, silent)
            state = val
            tween(track, { BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff }, 0.2)
            tween(knob,  { Position = state
                and UDim2.new(1, -19, 0.5, -8)
                or  UDim2.new(0, 3, 0.5, -8) }, 0.2)
            if not silent and opts.Callback then
                pcall(opts.Callback, state)
            end
        end

        local btn = make("TextButton", {
            Text             = "",
            Size             = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
        }, row)
        btn.MouseButton1Click:Connect(function()
            setToggle(not state)
        end)

        -- expose via getgenv if id given
        if id then
            getgenv()[id] = {
                Set = function(v) setToggle(v, false) end,
                Get = function()  return state end,
            }
        end
    end

    -- ── SLIDER ───────────────────────────────
    function Tab:AddSlider(id, opts)
        opts = opts or {}
        local min     = opts.Min      or 0
        local max     = opts.Max      or 100
        local round   = opts.Rounding or 0
        local suffix  = opts.Suffix   or ""
        local value   = opts.Default  or min
        local dragging = false

        local function fmt(v)
            if round == 0 then
                return tostring(math.floor(v)) .. suffix
            else
                return string.format("%." .. round .. "f", v) .. suffix
            end
        end

        local wrap = make("Frame", {
            Size             = UDim2.new(1, 0, 0, 52),
            BackgroundColor3 = Theme.Surface,
        }, tabFrame)
        corner(Theme.CornerElement, wrap)
        stroke(1, Theme.Border, wrap)
        padding(8, 12, 8, 12, wrap)

        local header = make("Frame", {
            Size             = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
        }, wrap)

        make("TextLabel", {
            Text       = opts.Title or id or "Slider",
            TextColor3 = Theme.TextPrimary,
            Font       = Enum.Font.Gotham,
            TextSize   = 13,
            Size       = UDim2.new(0.7, 0, 1, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, header)

        local valLabel = make("TextLabel", {
            Text       = fmt(value),
            TextColor3 = Theme.TextSecondary,
            Font       = Enum.Font.GothamSemibold,
            TextSize   = 12,
            Size       = UDim2.new(0.3, 0, 1, 0),
            Position   = UDim2.new(0.7, 0, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Right,
        }, header)

        local track = make("Frame", {
            Size             = UDim2.new(1, 0, 0, 6),
            Position         = UDim2.new(0, 0, 1, -6),
            BackgroundColor3 = Theme.SliderTrack,
        }, wrap)
        corner(3, track)

        local fillPct = (value - min) / (max - min)
        local fill = make("Frame", {
            Size             = UDim2.new(fillPct, 0, 1, 0),
            BackgroundColor3 = Theme.SliderFill,
        }, track)
        corner(3, fill)

        local knob = make("Frame", {
            Size             = UDim2.new(0, 14, 0, 14),
            Position         = UDim2.new(fillPct, -7, 0.5, -7),
            BackgroundColor3 = Theme.Accent,
        }, track)
        corner(7, knob)

        local hitbox = make("TextButton", {
            Text             = "",
            Size             = UDim2.new(1, 0, 0, 24),
            Position         = UDim2.new(0, 0, 0.5, -12),
            BackgroundTransparency = 1,
        }, track)

        local function setValue(v)
            v = math.clamp(v, min, max)
            if round == 0 then
                v = math.floor(v)
            else
                local m = 10^round
                v = math.floor(v * m + 0.5) / m
            end
            value = v
            local pct = (v - min) / (max - min)
            tween(fill,  { Size = UDim2.new(pct, 0, 1, 0) }, 0.05)
            tween(knob,  { Position = UDim2.new(pct, -7, 0.5, -7) }, 0.05)
            valLabel.Text = fmt(v)
            if opts.Callback then pcall(opts.Callback, v) end
        end

        local function fromMouse()
            local rel = UserInputService:GetMouseLocation().X
            local abs  = track.AbsolutePosition.X
            local sz   = track.AbsoluteSize.X
            local pct  = math.clamp((rel - abs) / sz, 0, 1)
            setValue(min + pct * (max - min))
        end

        hitbox.MouseButton1Down:Connect(function()
            dragging = true
            fromMouse()
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                fromMouse()
            end
        end)
        UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

        if id then
            getgenv()[id] = {
                Set = function(v) setValue(v) end,
                Get = function()  return value end,
            }
        end
    end

    -- ── DROPDOWN ─────────────────────────────
    function Tab:AddDropdown(id, opts)
        opts = opts or {}
        local values   = opts.Values  or {}
        local selected = opts.Default or (values[1] or "")
        local open     = false

        local wrap = make("Frame", {
            Size             = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = Theme.Surface,
            ClipsDescendants = false,
            ZIndex           = 5,
        }, tabFrame)
        corner(Theme.CornerElement, wrap)
        stroke(1, Theme.Border, wrap)
        padding(0, 10, 0, 12, wrap)

        make("TextLabel", {
            Text       = opts.Title or id or "Dropdown",
            TextColor3 = Theme.TextPrimary,
            Font       = Enum.Font.Gotham,
            TextSize   = 13,
            Size       = UDim2.new(0.55, 0, 1, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex     = 5,
        }, wrap)

        local selLabel = make("TextLabel", {
            Text       = selected,
            TextColor3 = Theme.TextSecondary,
            Font       = Enum.Font.GothamSemibold,
            TextSize   = 12,
            Size       = UDim2.new(0.35, 0, 1, 0),
            Position   = UDim2.new(0.55, 0, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex     = 5,
        }, wrap)

        local arrow = make("TextLabel", {
            Text       = "▾",
            TextColor3 = Theme.TextSecondary,
            Font       = Enum.Font.GothamBold,
            TextSize   = 12,
            Size       = UDim2.new(0, 20, 1, 0),
            Position   = UDim2.new(1, -20, 0, 0),
            BackgroundTransparency = 1,
            ZIndex     = 5,
        }, wrap)

        -- dropdown list
        local list = make("Frame", {
            Size             = UDim2.new(1, 0, 0, 0),
            Position         = UDim2.new(0, 0, 1, 4),
            BackgroundColor3 = Theme.Surface,
            ClipsDescendants = true,
            ZIndex           = 10,
            Visible          = false,
        }, wrap)
        corner(Theme.CornerElement, list)
        stroke(1, Theme.Border, list)

        local listLayout2 = listLayout(list, 2)
        padding(4, 6, 4, 6, list)

        local ITEM_H = 28

        local function buildItems()
            for _, c in ipairs(list:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            for _, v in ipairs(values) do
                local item = make("TextButton", {
                    Text             = v,
                    TextColor3       = v == selected and Theme.TextPrimary or Theme.TextSecondary,
                    Font             = Enum.Font.Gotham,
                    TextSize         = 12,
                    Size             = UDim2.new(1, 0, 0, ITEM_H),
                    BackgroundColor3 = v == selected and Theme.SurfaceHover or Color3.fromRGB(0,0,0),
                    BackgroundTransparency = v == selected and 0 or 1,
                    AutoButtonColor  = false,
                    ZIndex           = 11,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                }, list)
                corner(5, item)
                padding(0, 6, 0, 6, item)

                item.MouseEnter:Connect(function()
                    if v ~= selected then
                        tween(item, { BackgroundTransparency = 0,
                            BackgroundColor3 = Theme.SurfaceHover }, 0.1)
                    end
                end)
                item.MouseLeave:Connect(function()
                    if v ~= selected then
                        tween(item, { BackgroundTransparency = 1 }, 0.1)
                    end
                end)
                item.MouseButton1Click:Connect(function()
                    selected = v
                    selLabel.Text = v
                    if opts.Callback then pcall(opts.Callback, v) end
                    buildItems()
                    -- close
                    open = false
                    tween(list, { Size = UDim2.new(1, 0, 0, 0) }, 0.18)
                    tween(arrow, { Rotation = 0 }, 0.18)
                    task.delay(0.2, function() list.Visible = false end)
                end)
            end
        end
        buildItems()

        local function toggleDropdown()
            open = not open
            if open then
                list.Visible = true
                local targetH = #values * (ITEM_H + 2) + 8
                tween(list, { Size = UDim2.new(1, 0, 0, targetH) }, 0.2)
                tween(arrow, { Rotation = 180 }, 0.2)
            else
                tween(list, { Size = UDim2.new(1, 0, 0, 0) }, 0.18)
                tween(arrow, { Rotation = 0 }, 0.18)
                task.delay(0.2, function() list.Visible = false end)
            end
        end

        local hitbox = make("TextButton", {
            Text             = "",
            Size             = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ZIndex           = 6,
        }, wrap)
        hitbox.MouseButton1Click:Connect(toggleDropdown)

        if id then
            getgenv()[id] = {
                Set = function(v)
                    selected = v
                    selLabel.Text = v
                    buildItems()
                end,
                Get = function() return selected end,
                SetValues = function(v)
                    values = v
                    buildItems()
                end,
            }
        end
    end

    -- ── TEXTBOX ──────────────────────────────
    function Tab:AddTextBox(id, opts)
        opts = opts or {}

        local wrap = make("Frame", {
            Size             = UDim2.new(1, 0, 0, 52),
            BackgroundColor3 = Theme.Surface,
        }, tabFrame)
        corner(Theme.CornerElement, wrap)
        stroke(1, Theme.Border, wrap)
        padding(6, 12, 6, 12, wrap)

        make("TextLabel", {
            Text       = opts.Title or id or "TextBox",
            TextColor3 = Theme.TextPrimary,
            Font       = Enum.Font.Gotham,
            TextSize   = 12,
            Size       = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, wrap)

        local box = make("TextBox", {
            Text             = opts.Default or "",
            PlaceholderText  = opts.Placeholder or "Type here...",
            TextColor3       = Theme.TextPrimary,
            PlaceholderColor3 = Theme.TextDisabled,
            Font             = Enum.Font.Gotham,
            TextSize         = 12,
            Size             = UDim2.new(1, 0, 0, 22),
            Position         = UDim2.new(0, 0, 1, -22),
            BackgroundColor3 = Theme.SurfaceHover,
            TextXAlignment   = Enum.TextXAlignment.Left,
            ClearTextOnFocus = opts.ClearOnFocus ~= nil and opts.ClearOnFocus or false,
        }, wrap)
        corner(5, box)
        padding(0, 6, 0, 6, box)

        local str = stroke(1, Theme.Border, box)
        box.Focused:Connect(function()
            tweenColor(str, "Color", Theme.AccentDim)
        end)
        box.FocusLost:Connect(function(enter)
            tweenColor(str, "Color", Theme.Border)
            if opts.Callback then
                pcall(opts.Callback, box.Text, enter)
            end
        end)

        if id then
            getgenv()[id] = {
                Set = function(v) box.Text = v end,
                Get = function()  return box.Text end,
            }
        end
    end

    -- ── KEYBIND ──────────────────────────────
    function Tab:AddKeybind(id, opts)
        opts = opts or {}
        local key     = opts.Default or Enum.KeyCode.Unknown
        local binding = false

        local row = make("Frame", {
            Size             = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = Theme.Surface,
        }, tabFrame)
        corner(Theme.CornerElement, row)
        stroke(1, Theme.Border, row)
        padding(0, 12, 0, 12, row)

        make("TextLabel", {
            Text       = opts.Title or id or "Keybind",
            TextColor3 = Theme.TextPrimary,
            Font       = Enum.Font.Gotham,
            TextSize   = 13,
            Size       = UDim2.new(0.6, 0, 1, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, row)

        local keyBtn = make("TextButton", {
            Text             = key == Enum.KeyCode.Unknown and "[None]" or key.Name,
            TextColor3       = Theme.TextSecondary,
            Font             = Enum.Font.GothamSemibold,
            TextSize         = 11,
            Size             = UDim2.new(0, 80, 0, 22),
            Position         = UDim2.new(1, -80, 0.5, -11),
            BackgroundColor3 = Theme.SurfaceHover,
            AutoButtonColor  = false,
        }, row)
        corner(5, keyBtn)

        keyBtn.MouseButton1Click:Connect(function()
            binding = true
            keyBtn.Text      = "..."
            keyBtn.TextColor3 = Theme.Accent
        end)

        UserInputService.InputBegan:Connect(function(inp, gp)
            if not binding then return end
            if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
            binding           = false
            key               = inp.KeyCode
            keyBtn.Text       = key.Name
            keyBtn.TextColor3 = Theme.TextSecondary
            if opts.Callback then pcall(opts.Callback, key) end
        end)

        if id then
            getgenv()[id] = {
                Set = function(k)
                    key = k
                    keyBtn.Text = k.Name
                end,
                Get = function() return key end,
            }
        end
    end

    -- ── COLOR PICKER ─────────────────────────
    function Tab:AddColorPicker(id, opts)
        opts = opts or {}
        local color = opts.Default or Color3.fromRGB(255, 255, 255)
        local open  = false
        local h, s, v = Color3.toHSV(color)

        local wrap = make("Frame", {
            Size             = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = Theme.Surface,
            ClipsDescendants = false,
            ZIndex           = 4,
        }, tabFrame)
        corner(Theme.CornerElement, wrap)
        stroke(1, Theme.Border, wrap)
        padding(0, 12, 0, 12, wrap)

        make("TextLabel", {
            Text       = opts.Title or id or "Color",
            TextColor3 = Theme.TextPrimary,
            Font       = Enum.Font.Gotham,
            TextSize   = 13,
            Size       = UDim2.new(0.7, 0, 1, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex     = 4,
        }, wrap)

        local preview = make("Frame", {
            Size             = UDim2.new(0, 26, 0, 20),
            Position         = UDim2.new(1, -26, 0.5, -10),
            BackgroundColor3 = color,
            ZIndex           = 5,
        }, wrap)
        corner(5, preview)
        stroke(1, Theme.Border, preview)

        -- Picker panel
        local panel = make("Frame", {
            Size             = UDim2.new(1, 0, 0, 0),
            Position         = UDim2.new(0, 0, 1, 4),
            BackgroundColor3 = Theme.Surface,
            ClipsDescendants = true,
            ZIndex           = 10,
            Visible          = false,
        }, wrap)
        corner(Theme.CornerElement, panel)
        stroke(1, Theme.Border, panel)

        -- SV square
        local SV_SIZE = 140
        local svFrame = make("ImageLabel", {
            Size             = UDim2.new(0, SV_SIZE, 0, SV_SIZE),
            Position         = UDim2.new(0, 8, 0, 8),
            BackgroundColor3 = Color3.fromHSV(h, 1, 1),
            Image            = "rbxassetid://4155801252", -- S+V gradient overlay
            ZIndex           = 11,
        }, panel)
        corner(6, svFrame)

        local svKnob = make("Frame", {
            Size             = UDim2.new(0, 10, 0, 10),
            Position         = UDim2.new(s, -5, 1-v, -5),
            BackgroundColor3 = Color3.new(1,1,1),
            ZIndex           = 12,
        }, svFrame)
        corner(5, svKnob)

        -- Hue bar
        local hueBar = make("ImageLabel", {
            Size             = UDim2.new(0, 12, 0, SV_SIZE),
            Position         = UDim2.new(0, 8 + SV_SIZE + 8, 0, 8),
            Image            = "rbxassetid://698052001",
            ZIndex           = 11,
        }, panel)
        corner(4, hueBar)

        local hueKnob = make("Frame", {
            Size             = UDim2.new(1, 4, 0, 4),
            Position         = UDim2.new(0, -2, h, -2),
            BackgroundColor3 = Color3.new(1,1,1),
            ZIndex           = 12,
        }, hueBar)
        corner(2, hueKnob)

        local PANEL_H = SV_SIZE + 24

        local function updateColor()
            color = Color3.fromHSV(h, s, v)
            preview.BackgroundColor3 = color
            svFrame.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            svKnob.Position  = UDim2.new(s, -5, 1-v, -5)
            hueKnob.Position = UDim2.new(0, -2, h, -2)
            if opts.Callback then pcall(opts.Callback, color) end
        end

        -- SV drag
        local svDrag = false
        local function svFromMouse()
            local mp = UserInputService:GetMouseLocation()
            local ap = svFrame.AbsolutePosition
            local as = svFrame.AbsoluteSize
            s = math.clamp((mp.X - ap.X) / as.X, 0, 1)
            v = 1 - math.clamp((mp.Y - ap.Y) / as.Y, 0, 1)
            updateColor()
        end
        local svHit = make("TextButton", {
            Text = "", Size = UDim2.new(1,0,1,0),
            BackgroundTransparency = 1, ZIndex = 13,
        }, svFrame)
        svHit.MouseButton1Down:Connect(function() svDrag = true svFromMouse() end)

        -- Hue drag
        local hueDrag = false
        local function hueFromMouse()
            local mp = UserInputService:GetMouseLocation()
            local ap = hueBar.AbsolutePosition
            local as = hueBar.AbsoluteSize
            h = math.clamp((mp.Y - ap.Y) / as.Y, 0, 1)
            updateColor()
        end
        local hueHit = make("TextButton", {
            Text = "", Size = UDim2.new(1,0,1,0),
            BackgroundTransparency = 1, ZIndex = 13,
        }, hueBar)
        hueHit.MouseButton1Down:Connect(function() hueDrag = true hueFromMouse() end)

        UserInputService.InputChanged:Connect(function(inp)
            if inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
            if svDrag  then svFromMouse()  end
            if hueDrag then hueFromMouse() end
        end)
        UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                svDrag = false hueDrag = false
            end
        end)

        local hitbox = make("TextButton", {
            Text             = "",
            Size             = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ZIndex           = 6,
        }, wrap)
        hitbox.MouseButton1Click:Connect(function()
            open = not open
            if open then
                panel.Visible = true
                tween(panel, { Size = UDim2.new(1, 0, 0, PANEL_H) }, 0.2)
            else
                tween(panel, { Size = UDim2.new(1, 0, 0, 0) }, 0.18)
                task.delay(0.2, function() panel.Visible = false end)
            end
        end)

        if id then
            getgenv()[id] = {
                Set = function(c)
                    color = c
                    h, s, v = Color3.toHSV(c)
                    updateColor()
                end,
                Get = function() return color end,
            }
        end
    end

    return Tab
end

-- ════════════════════════════════════════════
--  RETURN
-- ════════════════════════════════════════════
return KaworuUI
