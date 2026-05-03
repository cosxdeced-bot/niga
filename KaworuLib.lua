-- ╔══════════════════════════════════════════════════╗
-- ║  KaworuUI  v2.0  |  Luna-style · Monochrome     ║
-- ╚══════════════════════════════════════════════════╝

local KaworuUI   = {}
KaworuUI.__index = KaworuUI

-- ─── Services ───────────────────────────────────────
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer

-- ─── Theme ──────────────────────────────────────────
local T = {
    -- Base
    WindowBg    = Color3.fromRGB(15,  15,  15),
    SidebarBg   = Color3.fromRGB(10,  10,  10),
    ContentBg   = Color3.fromRGB(18,  18,  18),
    TitlebarBg  = Color3.fromRGB(10,  10,  10),
    -- Surfaces
    Card        = Color3.fromRGB(24,  24,  24),
    CardHover   = Color3.fromRGB(32,  32,  32),
    CardStroke  = Color3.fromRGB(38,  38,  38),
    -- Tab
    TabIdle     = Color3.fromRGB(10,  10,  10),
    TabHover    = Color3.fromRGB(22,  22,  22),
    TabActive   = Color3.fromRGB(255, 255, 255),
    TabIdleTxt  = Color3.fromRGB(90,  90,  90),
    TabActiveTxt= Color3.fromRGB(10,  10,  10),
    -- Text
    TxtPrimary  = Color3.fromRGB(240, 240, 240),
    TxtSecondary= Color3.fromRGB(110, 110, 110),
    TxtDisabled = Color3.fromRGB(55,  55,  55),
    -- Accent / white
    Accent      = Color3.fromRGB(255, 255, 255),
    AccentDim   = Color3.fromRGB(180, 180, 180),
    -- Toggle
    ToggleOn    = Color3.fromRGB(255, 255, 255),
    ToggleOff   = Color3.fromRGB(45,  45,  45),
    Knob        = Color3.fromRGB(10,  10,  10),
    -- Divider
    Divider     = Color3.fromRGB(30,  30,  30),
    -- Notify
    NotifyBg    = Color3.fromRGB(20,  20,  20),
    NotifyLine  = Color3.fromRGB(255, 255, 255),
}

-- ─── Tween helpers ─────────────────────────────────
local function tw(obj, props, t, style, dir)
    TweenService:Create(obj,
        TweenInfo.new(t or .18, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props):Play()
end

-- ─── GUI factory ────────────────────────────────────
local function new(cls, props, parent)
    local o = Instance.new(cls)
    for k,v in pairs(props or {}) do o[k]=v end
    if parent then o.Parent = parent end
    return o
end

local function corner(r, p)
    new("UICorner",{CornerRadius=UDim.new(0,r)},p)
end

local function stroke(thick, col, p)
    new("UIStroke",{Thickness=thick or 1,Color=col or T.CardStroke,
        ApplyStrokeMode=Enum.ApplyStrokeMode.Border},p)
end

local function pad(t,r,b,l,p)
    new("UIPadding",{
        PaddingTop=UDim.new(0,t or 0), PaddingRight=UDim.new(0,r or 0),
        PaddingBottom=UDim.new(0,b or 0), PaddingLeft=UDim.new(0,l or 0)},p)
end

local function list(p, gap, dir, ha, va)
    new("UIListLayout",{
        Padding=UDim.new(0,gap or 6),
        FillDirection=dir or Enum.FillDirection.Vertical,
        HorizontalAlignment=ha or Enum.HorizontalAlignment.Left,
        VerticalAlignment=va or Enum.VerticalAlignment.Top,
        SortOrder=Enum.SortOrder.LayoutOrder},p)
end

local function label(txt, size, col, font, parent, props)
    props = props or {}
    props.Text = txt
    props.TextSize = size or 13
    props.TextColor3 = col or T.TxtPrimary
    props.Font = font or Enum.Font.Gotham
    props.BackgroundTransparency = 1
    if not props.Size then props.Size = UDim2.new(1,0,0,size and size+4 or 17) end
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    return new("TextLabel", props, parent)
end

-- ─── Drag ───────────────────────────────────────────
local function draggable(frame, handle)
    handle = handle or frame
    local drag, ds, sp = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=true; ds=i.Position; sp=frame.Position
        end
    end)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-ds
            frame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
end

-- ─── Notifications ──────────────────────────────────
local function buildNotify(sg)
    local holder = new("Frame",{
        Name="NotifyHolder",
        Size=UDim2.new(0,280,1,0),
        Position=UDim2.new(1,-290,0,0),
        BackgroundTransparency=1, ZIndex=200
    },sg)
    local ll = list(holder,8)
    ll.VerticalAlignment = Enum.VerticalAlignment.Bottom
    pad(0,0,14,0,holder)
    return holder
end

local function pushNotify(holder, opts)
    local card = new("Frame",{
        Size=UDim2.new(1,0,0,0),
        BackgroundColor3=T.NotifyBg,
        BackgroundTransparency=0,
        ClipsDescendants=true, ZIndex=200,
        LayoutOrder=-os.clock()
    },holder)
    corner(10,card)
    stroke(1,T.CardStroke,card)

    -- accent left bar
    new("Frame",{
        Size=UDim2.new(0,3,1,-16),
        Position=UDim2.new(0,0,0,8),
        BackgroundColor3=T.NotifyLine,
        BorderSizePixel=0, ZIndex=201
    },card)

    local inner = new("Frame",{
        Size=UDim2.new(1,-18,1,0),
        Position=UDim2.new(0,14,0,0),
        BackgroundTransparency=1, ZIndex=201
    },card)
    list(inner,3)
    pad(10,8,10,0,inner)

    label(opts.Title or "KaworuUI",13,T.TxtPrimary,Enum.Font.GothamBold,inner)
    label(opts.Content or "",11,T.TxtSecondary,Enum.Font.Gotham,inner,{
        Size=UDim2.new(1,0,0,28), TextWrapped=true
    })

    -- animate height 0 → 68
    tw(card,{Size=UDim2.new(1,0,0,68)},0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out)

    task.delay(opts.Duration or 4,function()
        tw(card,{Size=UDim2.new(1,0,0,0)},0.22)
        tw(card,{BackgroundTransparency=1},0.22)
        task.wait(0.25)
        card:Destroy()
    end)
end

-- ════════════════════════════════════════════════════
--  WINDOW
-- ════════════════════════════════════════════════════
function KaworuUI.new(opts)
    opts = opts or {}
    local self = setmetatable({},KaworuUI)
    self._tabs       = {}
    self._activeTab  = nil
    self._minimized  = false
    self._minKey     = opts.MinimizeKey or Enum.KeyCode.RightControl

    -- ScreenGui
    local sg = new("ScreenGui",{
        Name="KaworuUI", ResetOnSpawn=false,
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling, IgnoreGuiInset=true
    })
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(sg) end
    end)
    if gethui then sg.Parent=gethui()
    elseif game:GetService("CoreGui") then
        pcall(function() sg.Parent=game:GetService("CoreGui") end)
        if not sg.Parent then sg.Parent=LocalPlayer:WaitForChild("PlayerGui") end
    else sg.Parent=LocalPlayer:WaitForChild("PlayerGui") end
    self._sg = sg

    local W = opts.Size and opts.Size.X or 520
    local H = opts.Size and opts.Size.Y or 460
    self._winW = W
    self._winH = H

    -- ── Outer window ────────────────────────────────
    local win = new("Frame",{
        Name="Window",
        Size=UDim2.new(0,W,0,H),
        Position=UDim2.new(0.5,-W/2,0.5,-H/2),
        BackgroundColor3=T.WindowBg,
        ClipsDescendants=false,
    },sg)
    corner(12,win)
    stroke(1,T.CardStroke,win)
    self._win = win

    -- ── Title bar ───────────────────────────────────
    local TITLE_H = 42
    local titlebar = new("Frame",{
        Name="Titlebar",
        Size=UDim2.new(1,0,0,TITLE_H),
        BackgroundColor3=T.TitlebarBg,
        ClipsDescendants=false,
        ZIndex=2,
    },win)
    -- patch bottom corners flat on titlebar
    new("Frame",{
        Size=UDim2.new(1,0,0,12),
        Position=UDim2.new(0,0,1,-12),
        BackgroundColor3=T.TitlebarBg,
        BorderSizePixel=0, ZIndex=2
    },titlebar)
    corner(12,titlebar)

    -- bottom border line of titlebar
    new("Frame",{
        Size=UDim2.new(1,0,0,1),
        Position=UDim2.new(0,0,1,-1),
        BackgroundColor3=T.Divider,
        BorderSizePixel=0, ZIndex=3
    },titlebar)

    -- dot decorations (Luna-style 3 dots)
    local dotColors = {
        Color3.fromRGB(255,90,90),
        Color3.fromRGB(255,190,50),
        Color3.fromRGB(80,200,100),
    }
    for i,dc in ipairs(dotColors) do
        local dot = new("Frame",{
            Size=UDim2.new(0,11,0,11),
            Position=UDim2.new(0,10+(i-1)*17,0.5,-5),
            BackgroundColor3=dc, ZIndex=3
        },titlebar)
        corner(6,dot)
    end

    label(opts.Title or "KaworuUI",14,T.TxtPrimary,Enum.Font.GothamBold,titlebar,{
        Size=UDim2.new(1,-200,1,0),
        Position=UDim2.new(0,70,0,0),
        ZIndex=3
    })
    if opts.SubTitle then
        label(opts.SubTitle,11,T.TxtSecondary,Enum.Font.Gotham,titlebar,{
            Size=UDim2.new(0,200,1,0),
            Position=UDim2.new(0,70,0,16),
            ZIndex=3
        })
    end

    -- minimize button (─)  top-right
    local minBtn = new("TextButton",{
        Text="─", TextColor3=T.TxtSecondary,
        Font=Enum.Font.GothamBold, TextSize=12,
        Size=UDim2.new(0,28,0,22),
        Position=UDim2.new(1,-64,0.5,-11),
        BackgroundColor3=T.Card,
        AutoButtonColor=false, ZIndex=3
    },titlebar)
    corner(6,minBtn)

    -- close button (×) — swaps role: hides/shows (minimize)
    local closeBtn = new("TextButton",{
        Text="×", TextColor3=T.TxtSecondary,
        Font=Enum.Font.GothamBold, TextSize=16,
        Size=UDim2.new(0,28,0,22),
        Position=UDim2.new(1,-30,0.5,-11),
        BackgroundColor3=T.Card,
        AutoButtonColor=false, ZIndex=3
    },titlebar)
    corner(6,closeBtn)

    draggable(win, titlebar)

    -- ── Body (sidebar + content) ─────────────────────
    local SIDEBAR_W = 110
    local BODY_Y    = TITLE_H

    local sidebar = new("ScrollingFrame",{
        Name="Sidebar",
        Size=UDim2.new(0,SIDEBAR_W,1,-BODY_Y),
        Position=UDim2.new(0,0,0,BODY_Y),
        BackgroundColor3=T.SidebarBg,
        ScrollBarThickness=0,
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ClipsDescendants=true,
        BorderSizePixel=0, ZIndex=2
    },win)
    -- patch right corners flat
    new("Frame",{
        Size=UDim2.new(0,12,1,0),
        Position=UDim2.new(1,-12,0,0),
        BackgroundColor3=T.SidebarBg,
        BorderSizePixel=0, ZIndex=2
    },sidebar)
    corner(12,sidebar)
    list(sidebar, 4)
    pad(8,0,8,6,sidebar)

    -- sidebar right border
    new("Frame",{
        Size=UDim2.new(0,1,1,-BODY_Y),
        Position=UDim2.new(0,SIDEBAR_W,0,BODY_Y),
        BackgroundColor3=T.Divider,
        BorderSizePixel=0, ZIndex=3
    },win)

    local contentArea = new("ScrollingFrame",{
        Name="Content",
        Size=UDim2.new(1,-SIDEBAR_W-1,1,-BODY_Y),
        Position=UDim2.new(0,SIDEBAR_W+1,0,BODY_Y),
        BackgroundColor3=T.ContentBg,
        ScrollBarThickness=3,
        ScrollBarImageColor3=Color3.fromRGB(50,50,50),
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ClipsDescendants=true,
        BorderSizePixel=0, ZIndex=2
    },win)
    -- patch left corners flat
    new("Frame",{
        Size=UDim2.new(0,12,1,0),
        Position=UDim2.new(0,0,0,0),
        BackgroundColor3=T.ContentBg,
        BorderSizePixel=0, ZIndex=2
    },contentArea)
    corner(12,contentArea)
    self._content = contentArea
    self._sidebar = sidebar

    -- ── Minimize / Close logic ───────────────────────
    local function setMinimized(v)
        self._minimized = v
        if v then
            tw(win,{Size=UDim2.new(0,W,0,TITLE_H)},0.28,Enum.EasingStyle.Quart)
        else
            tw(win,{Size=UDim2.new(0,W,0,H)},0.28,Enum.EasingStyle.Quart)
        end
    end

    closeBtn.MouseButton1Click:Connect(function()
        setMinimized(not self._minimized)
    end)
    minBtn.MouseButton1Click:Connect(function()
        setMinimized(not self._minimized)
    end)

    -- hover effects for buttons
    for _,btn in ipairs({closeBtn,minBtn}) do
        btn.MouseEnter:Connect(function()
            tw(btn,{BackgroundColor3=T.CardHover},0.1)
            tw(btn,{TextColor3=T.TxtPrimary},0.1)
        end)
        btn.MouseLeave:Connect(function()
            tw(btn,{BackgroundColor3=T.Card},0.1)
            tw(btn,{TextColor3=T.TxtSecondary},0.1)
        end)
    end

    UserInputService.InputBegan:Connect(function(inp,gp)
        if gp then return end
        if inp.KeyCode==self._minKey then setMinimized(not self._minimized) end
    end)

    -- notify holder
    local nh = buildNotify(sg)
    self._notify = function(o) pushNotify(nh,o) end

    return self
end

function KaworuUI:Notify(opts) self._notify(opts) end

-- ════════════════════════════════════════════════════
--  TAB
-- ════════════════════════════════════════════════════
function KaworuUI:AddTab(opts)
    opts = opts or {}
    local Tab = { _self = self }

    -- sidebar button
    local btn = new("TextButton",{
        Text="",
        Size=UDim2.new(1,-6,0,34),
        BackgroundColor3=T.TabIdle,
        AutoButtonColor=false, ZIndex=3,
        LayoutOrder=#self._tabs+1
    },self._sidebar)
    corner(8,btn)

    -- icon area + label
    local btnLabel = label(opts.Title or "Tab",12,T.TabIdleTxt,Enum.Font.GothamSemibold,btn,{
        Size=UDim2.new(1,0,1,0),
        TextXAlignment=Enum.TextXAlignment.Center,
        ZIndex=4
    })

    -- active indicator bar (left edge)
    local bar = new("Frame",{
        Size=UDim2.new(0,3,0,18),
        Position=UDim2.new(0,0,0.5,-9),
        BackgroundColor3=T.Accent,
        BackgroundTransparency=1,
        BorderSizePixel=0, ZIndex=4
    },btn)
    corner(2,bar)

    -- tab content frame inside contentArea
    local frame = new("Frame",{
        Name="Tab_"..(opts.Title or ""),
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        Visible=false, ZIndex=2
    },self._content)
    list(frame,6)
    pad(10,10,10,10,frame)

    Tab._btn   = btn
    Tab._frame = frame
    Tab._bar   = bar
    Tab._label = btnLabel

    local function activate()
        for _,t in ipairs(self._tabs) do
            tw(t._btn,{BackgroundColor3=T.TabIdle},0.15)
            tw(t._label,{TextColor3=T.TabIdleTxt},0.15)
            tw(t._bar,{BackgroundTransparency=1},0.15)
            t._frame.Visible=false
        end
        tw(btn,{BackgroundColor3=T.TabActive},0.15)
        tw(btnLabel,{TextColor3=T.TabActiveTxt},0.15)
        tw(bar,{BackgroundTransparency=0},0.15)
        frame.Visible=true
        self._activeTab=Tab
    end

    btn.MouseButton1Click:Connect(activate)
    btn.MouseEnter:Connect(function()
        if self._activeTab~=Tab then
            tw(btn,{BackgroundColor3=T.TabHover},0.1)
        end
    end)
    btn.MouseLeave:Connect(function()
        if self._activeTab~=Tab then
            tw(btn,{BackgroundColor3=T.TabIdle},0.1)
        end
    end)

    table.insert(self._tabs,Tab)
    if #self._tabs==1 then activate() end

    -- ════ ELEMENTS ════════════════════════════════════

    -- ── Section ──────────────────────────────────────
    function Tab:AddSection(title)
        local wrap = new("Frame",{
            Size=UDim2.new(1,0,0,0),
            AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1
        },frame)
        list(wrap,5)

        -- section header row
        local row = new("Frame",{
            Size=UDim2.new(1,0,0,20),
            BackgroundTransparency=1
        },wrap)
        -- accent bar
        new("Frame",{
            Size=UDim2.new(0,3,0,12),
            Position=UDim2.new(0,0,0.5,-6),
            BackgroundColor3=T.Accent,
            BorderSizePixel=0
        },row)
        label((title or ""):upper(),10,T.TxtDisabled,Enum.Font.GothamBold,row,{
            Size=UDim2.new(1,-10,1,0),
            Position=UDim2.new(0,10,0,0),
        })
        new("Frame",{
            Size=UDim2.new(1,0,0,1),
            BackgroundColor3=T.Divider,
            BorderSizePixel=0
        },wrap)
    end

    -- ── Label ─────────────────────────────────────────
    function Tab:AddLabel(txt)
        label(txt,12,T.TxtSecondary,Enum.Font.Gotham,frame,{
            Size=UDim2.new(1,0,0,18)
        })
    end

    -- ── Separator ────────────────────────────────────
    function Tab:AddSeparator()
        new("Frame",{
            Size=UDim2.new(1,0,0,1),
            BackgroundColor3=T.Divider,
            BorderSizePixel=0
        },frame)
    end

    -- ── Button ───────────────────────────────────────
    function Tab:AddButton(opts)
        opts=opts or {}
        local btn2 = new("TextButton",{
            Text="",
            Size=UDim2.new(1,0,0,38),
            BackgroundColor3=T.Card,
            AutoButtonColor=false, ZIndex=2
        },frame)
        corner(8,btn2)
        stroke(1,T.CardStroke,btn2)
        pad(0,12,0,12,btn2)

        label(opts.Title or "Button",13,T.TxtPrimary,Enum.Font.GothamSemibold,btn2,{
            Size=UDim2.new(0.7,0,1,0), ZIndex=3
        })
        if opts.Description then
            label(opts.Description,11,T.TxtSecondary,Enum.Font.Gotham,btn2,{
                Size=UDim2.new(0.7,0,1,0),
                Position=UDim2.new(0,0,0,18), ZIndex=3
            })
        end

        -- right arrow
        label("›",16,T.TxtSecondary,Enum.Font.GothamBold,btn2,{
            Size=UDim2.new(0,20,1,0),
            Position=UDim2.new(1,-20,0,0),
            TextXAlignment=Enum.TextXAlignment.Center, ZIndex=3
        })

        btn2.MouseEnter:Connect(function() tw(btn2,{BackgroundColor3=T.CardHover},0.12) end)
        btn2.MouseLeave:Connect(function() tw(btn2,{BackgroundColor3=T.Card},0.12) end)
        btn2.MouseButton1Down:Connect(function() tw(btn2,{BackgroundColor3=T.CardStroke},0.06) end)
        btn2.MouseButton1Up:Connect(function()
            tw(btn2,{BackgroundColor3=T.CardHover},0.08)
            if opts.Callback then pcall(opts.Callback) end
        end)
        btn2.MouseButton1Click:Connect(function()
            if opts.Callback then pcall(opts.Callback) end
        end)
    end

    -- ── Toggle ───────────────────────────────────────
    function Tab:AddToggle(id, opts)
        opts=opts or {}
        local state = opts.Default or false

        local row = new("Frame",{
            Size=UDim2.new(1,0,0,38),
            BackgroundColor3=T.Card, ZIndex=2
        },frame)
        corner(8,row)
        stroke(1,T.CardStroke,row)
        pad(0,12,0,12,row)

        label(opts.Title or id or "Toggle",13,T.TxtPrimary,Enum.Font.Gotham,row,{
            Size=UDim2.new(1,-58,1,0), ZIndex=3
        })

        -- Track
        local track = new("Frame",{
            Size=UDim2.new(0,42,0,24),
            Position=UDim2.new(1,-42,0.5,-12),
            BackgroundColor3=state and T.ToggleOn or T.ToggleOff,
            ZIndex=3
        },row)
        corner(12,track)

        local knob = new("Frame",{
            Size=UDim2.new(0,18,0,18),
            Position=state and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9),
            BackgroundColor3=state and T.Knob or Color3.fromRGB(160,160,160),
            ZIndex=4
        },track)
        corner(9,knob)

        local function set(v, silent)
            state=v
            tw(track,{BackgroundColor3=state and T.ToggleOn or T.ToggleOff},0.2)
            tw(knob,{
                Position=state and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9),
                BackgroundColor3=state and T.Knob or Color3.fromRGB(160,160,160)
            },0.2)
            if not silent and opts.Callback then pcall(opts.Callback,state) end
        end

        local hit = new("TextButton",{
            Text="",Size=UDim2.new(1,0,1,0),
            BackgroundTransparency=1, ZIndex=5
        },row)
        hit.MouseButton1Click:Connect(function() set(not state) end)
        row.MouseEnter:Connect(function() tw(row,{BackgroundColor3=T.CardHover},0.1) end)
        row.MouseLeave:Connect(function() tw(row,{BackgroundColor3=T.Card},0.1) end)

        if id then
            getgenv()[id]={
                Set=function(v) set(v,false) end,
                Get=function() return state end,
            }
        end
    end

    -- ── Slider ───────────────────────────────────────
    function Tab:AddSlider(id, opts)
        opts=opts or {}
        local min=opts.Min or 0
        local max=opts.Max or 100
        local rnd=opts.Rounding or 0
        local suf=opts.Suffix or ""
        local val=opts.Default or min
        local drag=false

        local function fmt(v)
            if rnd==0 then return tostring(math.floor(v))..suf end
            return string.format("%."..rnd.."f",v)..suf
        end

        local wrap = new("Frame",{
            Size=UDim2.new(1,0,0,54),
            BackgroundColor3=T.Card, ZIndex=2
        },frame)
        corner(8,wrap)
        stroke(1,T.CardStroke,wrap)
        pad(8,12,8,12,wrap)

        -- header
        local hdr = new("Frame",{
            Size=UDim2.new(1,0,0,18),
            BackgroundTransparency=1, ZIndex=3
        },wrap)
        label(opts.Title or id or "Slider",13,T.TxtPrimary,Enum.Font.Gotham,hdr,{
            Size=UDim2.new(0.65,0,1,0), ZIndex=3
        })
        local valLbl = label(fmt(val),12,T.AccentDim,Enum.Font.GothamBold,hdr,{
            Size=UDim2.new(0.35,0,1,0),
            Position=UDim2.new(0.65,0,0,0),
            TextXAlignment=Enum.TextXAlignment.Right, ZIndex=3
        })

        -- track
        local track = new("Frame",{
            Size=UDim2.new(1,0,0,6),
            Position=UDim2.new(0,0,1,-6),
            BackgroundColor3=T.ToggleOff, ZIndex=3
        },wrap)
        corner(3,track)

        local pct=(val-min)/(max-min)
        local fill = new("Frame",{
            Size=UDim2.new(pct,0,1,0),
            BackgroundColor3=T.Accent, ZIndex=4
        },track)
        corner(3,fill)

        local knob2 = new("Frame",{
            Size=UDim2.new(0,14,0,14),
            Position=UDim2.new(pct,-7,0.5,-7),
            BackgroundColor3=T.Accent, ZIndex=5
        },track)
        corner(7,knob2)
        stroke(2,T.ContentBg,knob2)

        local function setVal(v)
            v=math.clamp(v,min,max)
            if rnd==0 then v=math.floor(v)
            else local m=10^rnd; v=math.floor(v*m+.5)/m end
            val=v
            local p=(v-min)/(max-min)
            tw(fill,{Size=UDim2.new(p,0,1,0)},0.05)
            tw(knob2,{Position=UDim2.new(p,-7,0.5,-7)},0.05)
            valLbl.Text=fmt(v)
            if opts.Callback then pcall(opts.Callback,v) end
        end

        local function fromMouse()
            local rel=UserInputService:GetMouseLocation().X
            local p=math.clamp((rel-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
            setVal(min+p*(max-min))
        end

        local hit2=new("TextButton",{
            Text="",Size=UDim2.new(1,0,0,22),
            Position=UDim2.new(0,0,0.5,-11),
            BackgroundTransparency=1, ZIndex=6
        },track)
        hit2.MouseButton1Down:Connect(function() drag=true; fromMouse() end)
        UserInputService.InputChanged:Connect(function(i)
            if drag and i.UserInputType==Enum.UserInputType.MouseMovement then fromMouse() end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
        end)

        wrap.MouseEnter:Connect(function() tw(wrap,{BackgroundColor3=T.CardHover},0.1) end)
        wrap.MouseLeave:Connect(function() tw(wrap,{BackgroundColor3=T.Card},0.1) end)

        if id then
            getgenv()[id]={Set=function(v) setVal(v) end, Get=function() return val end}
        end
    end

    -- ── Dropdown ─────────────────────────────────────
    function Tab:AddDropdown(id, opts)
        opts=opts or {}
        local vals=opts.Values or {}
        local sel=opts.Default or vals[1] or ""
        local open=false
        local ITEM=28

        local wrap = new("Frame",{
            Size=UDim2.new(1,0,0,38),
            BackgroundColor3=T.Card,
            ClipsDescendants=false, ZIndex=4
        },frame)
        corner(8,wrap)
        stroke(1,T.CardStroke,wrap)
        pad(0,12,0,12,wrap)

        label(opts.Title or id or "Dropdown",13,T.TxtPrimary,Enum.Font.Gotham,wrap,{
            Size=UDim2.new(0.5,0,1,0), ZIndex=5
        })

        local selLbl=label(sel,12,T.AccentDim,Enum.Font.GothamBold,wrap,{
            Size=UDim2.new(0.4,0,1,0),
            Position=UDim2.new(0.5,0,0,0),
            TextXAlignment=Enum.TextXAlignment.Right, ZIndex=5
        })

        local arrow=label("▾",13,T.TxtSecondary,Enum.Font.GothamBold,wrap,{
            Size=UDim2.new(0,18,1,0),
            Position=UDim2.new(1,-18,0,0),
            TextXAlignment=Enum.TextXAlignment.Center, ZIndex=5
        })

        -- list
        local listFrame=new("Frame",{
            Size=UDim2.new(1,0,0,0),
            Position=UDim2.new(0,0,1,4),
            BackgroundColor3=T.Card,
            ClipsDescendants=true, ZIndex=10, Visible=false
        },wrap)
        corner(8,listFrame)
        stroke(1,T.CardStroke,listFrame)

        local ll2=list(listFrame,2)
        pad(4,6,4,6,listFrame)

        local function buildItems()
            for _,c in ipairs(listFrame:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            for _,v in ipairs(vals) do
                local it=new("TextButton",{
                    Text=v,
                    TextColor3=v==sel and T.TxtPrimary or T.TxtSecondary,
                    Font=v==sel and Enum.Font.GothamSemibold or Enum.Font.Gotham,
                    TextSize=12,
                    Size=UDim2.new(1,0,0,ITEM),
                    BackgroundColor3=v==sel and T.CardHover or T.Card,
                    BackgroundTransparency=v==sel and 0 or 1,
                    AutoButtonColor=false,
                    ZIndex=11, TextXAlignment=Enum.TextXAlignment.Left
                },listFrame)
                corner(5,it); pad(0,6,0,6,it)
                it.MouseEnter:Connect(function()
                    if v~=sel then tw(it,{BackgroundTransparency=0,BackgroundColor3=T.CardHover},0.1) end
                end)
                it.MouseLeave:Connect(function()
                    if v~=sel then tw(it,{BackgroundTransparency=1},0.1) end
                end)
                it.MouseButton1Click:Connect(function()
                    sel=v; selLbl.Text=v
                    if opts.Callback then pcall(opts.Callback,v) end
                    buildItems()
                    open=false
                    tw(listFrame,{Size=UDim2.new(1,0,0,0)},0.18)
                    tw(arrow,{Rotation=0},0.18)
                    task.delay(.2,function() listFrame.Visible=false end)
                end)
            end
        end
        buildItems()

        local function toggle()
            open=not open
            if open then
                listFrame.Visible=true
                tw(listFrame,{Size=UDim2.new(1,0,0,#vals*(ITEM+2)+8)},0.2,Enum.EasingStyle.Quart)
                tw(arrow,{Rotation=180},0.2)
            else
                tw(listFrame,{Size=UDim2.new(1,0,0,0)},0.18)
                tw(arrow,{Rotation=0},0.18)
                task.delay(.2,function() listFrame.Visible=false end)
            end
        end

        local hit=new("TextButton",{Text="",Size=UDim2.new(1,0,1,0),
            BackgroundTransparency=1,ZIndex=6},wrap)
        hit.MouseButton1Click:Connect(toggle)
        wrap.MouseEnter:Connect(function() tw(wrap,{BackgroundColor3=T.CardHover},0.1) end)
        wrap.MouseLeave:Connect(function()
            if not open then tw(wrap,{BackgroundColor3=T.Card},0.1) end
        end)

        if id then
            getgenv()[id]={
                Set=function(v) sel=v; selLbl.Text=v; buildItems() end,
                Get=function() return sel end,
                SetValues=function(v) vals=v; buildItems() end,
            }
        end
    end

    -- ── TextBox ──────────────────────────────────────
    function Tab:AddTextBox(id, opts)
        opts=opts or {}
        local wrap=new("Frame",{
            Size=UDim2.new(1,0,0,56),
            BackgroundColor3=T.Card, ZIndex=2
        },frame)
        corner(8,wrap); stroke(1,T.CardStroke,wrap); pad(8,12,8,12,wrap)

        label(opts.Title or id or "Input",12,T.TxtSecondary,Enum.Font.Gotham,wrap,{
            Size=UDim2.new(1,0,0,16), ZIndex=3
        })

        local box=new("TextBox",{
            Text=opts.Default or "",
            PlaceholderText=opts.Placeholder or "Type here...",
            TextColor3=T.TxtPrimary,
            PlaceholderColor3=T.TxtDisabled,
            Font=Enum.Font.Gotham, TextSize=12,
            Size=UDim2.new(1,0,0,24),
            Position=UDim2.new(0,0,1,-24),
            BackgroundColor3=T.ContentBg,
            TextXAlignment=Enum.TextXAlignment.Left,
            ClearTextOnFocus=opts.ClearOnFocus~=nil and opts.ClearOnFocus or false,
            ZIndex=3
        },wrap)
        corner(6,box); pad(0,6,0,8,box)

        local str2=stroke(1,T.CardStroke,box)
        box.Focused:Connect(function() tw(str2,{Color=T.AccentDim},0.12) end)
        box.FocusLost:Connect(function(enter)
            tw(str2,{Color=T.CardStroke},0.12)
            if opts.Callback then pcall(opts.Callback,box.Text,enter) end
        end)

        if id then
            getgenv()[id]={Set=function(v) box.Text=v end,Get=function() return box.Text end}
        end
    end

    -- ── Keybind ──────────────────────────────────────
    function Tab:AddKeybind(id, opts)
        opts=opts or {}
        local key=opts.Default or Enum.KeyCode.Unknown
        local binding=false

        local row=new("Frame",{
            Size=UDim2.new(1,0,0,38),
            BackgroundColor3=T.Card, ZIndex=2
        },frame)
        corner(8,row); stroke(1,T.CardStroke,row); pad(0,12,0,12,row)

        label(opts.Title or id or "Keybind",13,T.TxtPrimary,Enum.Font.Gotham,row,{
            Size=UDim2.new(0.6,0,1,0), ZIndex=3
        })

        local keyBtn=new("TextButton",{
            Text=key==Enum.KeyCode.Unknown and "[None]" or key.Name,
            TextColor3=T.AccentDim,
            Font=Enum.Font.GothamSemibold, TextSize=11,
            Size=UDim2.new(0,80,0,24),
            Position=UDim2.new(1,-80,0.5,-12),
            BackgroundColor3=T.ContentBg,
            AutoButtonColor=false, ZIndex=3
        },row)
        corner(6,keyBtn); stroke(1,T.CardStroke,keyBtn)

        keyBtn.MouseButton1Click:Connect(function()
            binding=true
            keyBtn.Text="..."
            tw(keyBtn,{TextColor3=T.Accent},0.1)
        end)
        UserInputService.InputBegan:Connect(function(inp,gp)
            if not binding then return end
            if inp.UserInputType~=Enum.UserInputType.Keyboard then return end
            binding=false; key=inp.KeyCode
            keyBtn.Text=key.Name
            tw(keyBtn,{TextColor3=T.AccentDim},0.1)
            if opts.Callback then pcall(opts.Callback,key) end
        end)

        row.MouseEnter:Connect(function() tw(row,{BackgroundColor3=T.CardHover},0.1) end)
        row.MouseLeave:Connect(function() tw(row,{BackgroundColor3=T.Card},0.1) end)

        if id then
            getgenv()[id]={
                Set=function(k) key=k; keyBtn.Text=k.Name end,
                Get=function() return key end
            }
        end
    end

    -- ── ColorPicker ──────────────────────────────────
    function Tab:AddColorPicker(id, opts)
        opts=opts or {}
        local col=opts.Default or Color3.new(1,1,1)
        local h,s,v=Color3.toHSV(col)
        local open=false
        local svDrag,hueDrag=false,false
        local SZ=130

        local wrap=new("Frame",{
            Size=UDim2.new(1,0,0,38),
            BackgroundColor3=T.Card,
            ClipsDescendants=false, ZIndex=4
        },frame)
        corner(8,wrap); stroke(1,T.CardStroke,wrap); pad(0,12,0,12,wrap)

        label(opts.Title or id or "Color",13,T.TxtPrimary,Enum.Font.Gotham,wrap,{
            Size=UDim2.new(0.7,0,1,0), ZIndex=5
        })

        local preview=new("Frame",{
            Size=UDim2.new(0,28,0,20),
            Position=UDim2.new(1,-28,0.5,-10),
            BackgroundColor3=col, ZIndex=5
        },wrap)
        corner(6,preview); stroke(1,T.CardStroke,preview)

        local panel=new("Frame",{
            Size=UDim2.new(1,0,0,0),
            Position=UDim2.new(0,0,1,4),
            BackgroundColor3=T.Card,
            ClipsDescendants=true, ZIndex=10, Visible=false
        },wrap)
        corner(8,panel); stroke(1,T.CardStroke,panel)

        -- SV area
        local svArea=new("ImageLabel",{
            Size=UDim2.new(0,SZ,0,SZ),
            Position=UDim2.new(0,8,0,8),
            BackgroundColor3=Color3.fromHSV(h,1,1),
            Image="rbxassetid://4155801252",
            ZIndex=11
        },panel)
        corner(6,svArea)

        local svKnob=new("Frame",{
            Size=UDim2.new(0,10,0,10),
            Position=UDim2.new(s,-5,1-v,-5),
            BackgroundColor3=Color3.new(1,1,1),
            ZIndex=12
        },svArea)
        corner(5,svKnob); stroke(2,Color3.fromRGB(0,0,0),svKnob)

        -- Hue bar
        local hueBar=new("ImageLabel",{
            Size=UDim2.new(0,14,0,SZ),
            Position=UDim2.new(0,8+SZ+8,0,8),
            Image="rbxassetid://698052001",
            ZIndex=11
        },panel)
        corner(5,hueBar)

        local hueKnob=new("Frame",{
            Size=UDim2.new(1,4,0,4),
            Position=UDim2.new(0,-2,h,-2),
            BackgroundColor3=Color3.new(1,1,1),
            ZIndex=12
        },hueBar)
        corner(2,hueKnob); stroke(1,Color3.fromRGB(80,80,80),hueKnob)

        local PH=SZ+24
        panel.Size=UDim2.new(1,0,0,0)

        local function upd()
            col=Color3.fromHSV(h,s,v)
            preview.BackgroundColor3=col
            svArea.BackgroundColor3=Color3.fromHSV(h,1,1)
            svKnob.Position=UDim2.new(s,-5,1-v,-5)
            hueKnob.Position=UDim2.new(0,-2,h,-2)
            if opts.Callback then pcall(opts.Callback,col) end
        end

        local function svMouse()
            local mp=UserInputService:GetMouseLocation()
            local ap=svArea.AbsolutePosition; local as=svArea.AbsoluteSize
            s=math.clamp((mp.X-ap.X)/as.X,0,1)
            v=1-math.clamp((mp.Y-ap.Y)/as.Y,0,1)
            upd()
        end
        local function hueMouse()
            local mp=UserInputService:GetMouseLocation()
            local ap=hueBar.AbsolutePosition; local as=hueBar.AbsoluteSize
            h=math.clamp((mp.Y-ap.Y)/as.Y,0,1)
            upd()
        end

        local svHit=new("TextButton",{Text="",Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,ZIndex=13},svArea)
        local hueHit=new("TextButton",{Text="",Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,ZIndex=13},hueBar)
        svHit.MouseButton1Down:Connect(function() svDrag=true; svMouse() end)
        hueHit.MouseButton1Down:Connect(function() hueDrag=true; hueMouse() end)
        UserInputService.InputChanged:Connect(function(i)
            if i.UserInputType~=Enum.UserInputType.MouseMovement then return end
            if svDrag then svMouse() end
            if hueDrag then hueMouse() end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then svDrag=false;hueDrag=false end
        end)

        local hit=new("TextButton",{Text="",Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,ZIndex=6},wrap)
        hit.MouseButton1Click:Connect(function()
            open=not open
            if open then
                panel.Visible=true
                tw(panel,{Size=UDim2.new(1,0,0,PH)},0.2,Enum.EasingStyle.Quart)
            else
                tw(panel,{Size=UDim2.new(1,0,0,0)},0.18)
                task.delay(.2,function() panel.Visible=false end)
            end
        end)

        wrap.MouseEnter:Connect(function() tw(wrap,{BackgroundColor3=T.CardHover},0.1) end)
        wrap.MouseLeave:Connect(function() tw(wrap,{BackgroundColor3=T.Card},0.1) end)

        if id then
            getgenv()[id]={
                Set=function(c) col=c; h,s,v=Color3.toHSV(c); upd() end,
                Get=function() return col end
            }
        end
    end

    return Tab
end

return KaworuUI
