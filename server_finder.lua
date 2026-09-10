--═══════════════════════════════════════════════════════════
--  🍈 DurianHub — Community Server Finder
--  Design ported from HTML → Roblox executor GUI
--═══════════════════════════════════════════════════════════

--// Services
local HttpService        = game:GetService("HttpService")
local TeleportService    = game:GetService("TeleportService")
local Players            = game:GetService("Players")
local CoreGui            = game:GetService("CoreGui")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService   = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlaceId     = game.PlaceId

--// Config
local MAX_PAGES             = 3
local AUTO_REFRESH_INTERVAL = 30

--// Game name (for entry titles)
local GameName = "this game"
pcall(function()
    GameName = MarketplaceService:GetProductInfo(PlaceId).Name
end)

--═══════════════ COLOR PALETTE (from the CSS) ═══════════════
local C = {
    Forest       = Color3.fromRGB(36, 72, 32),    -- #244820
    Sage         = Color3.fromRGB(59, 107, 53),   -- #3B6B35
    Gold         = Color3.fromRGB(224, 169, 56),  -- #E0A938
    GoldLight    = Color3.fromRGB(245, 200, 105), -- #F5C869
    GoldBG       = Color3.fromRGB(247, 237, 213), -- #f7edd5
    GoldBorder   = Color3.fromRGB(235, 212, 159), -- #ebd49f
    GoldText     = Color3.fromRGB(122, 81, 8),    -- #7a5108
    PageBG       = Color3.fromRGB(244, 241, 232), -- #f4f1e8
    CardBG       = Color3.fromRGB(250, 248, 244), -- #faf8f4
    White        = Color3.fromRGB(255, 255, 255),
    Border       = Color3.fromRGB(224, 217, 204), -- #e0d9cc
    BorderSoft   = Color3.fromRGB(236, 230, 218), -- #ece6da
    Divider      = Color3.fromRGB(239, 235, 225), -- #efebe1
    Text         = Color3.fromRGB(26, 33, 25),    -- #1a2119
    Muted        = Color3.fromRGB(102, 112, 100), -- #667064
    SubText      = Color3.fromRGB(113, 125, 111), -- #717d6f
    GreenBG      = Color3.fromRGB(234, 245, 233), -- #eaf5e9
    GreenText    = Color3.fromRGB(43, 122, 39),   -- #2b7a27
    StatusBG     = Color3.fromRGB(240, 245, 239), -- #f0f5ef
    StatusBorder = Color3.fromRGB(204, 224, 201), -- #cce0c9
    DotGreen     = Color3.fromRGB(34, 197, 94),
    DotGold      = Color3.fromRGB(224, 169, 56),
    DotRed       = Color3.fromRGB(220, 80, 80),
}

--═══════════════ STATE ═══════════════
local allServers     = {}
local currentSort    = "All Servers"
local autoOn         = true
local scanning       = false
local searchText     = ""

--═══════════════ HELPER ═══════════════
local function new(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        inst[k] = v
    end
    inst.Parent = parent
    return inst
end

local function corner(r, parent)
    return new("UICorner", { CornerRadius = UDim.new(0, r) }, parent)
end

local function stroke(color, thickness, parent)
    return new("UIStroke", {
        Color = color, Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

--═══════════════ CLEANUP OLD GUI ═══════════════
local old = CoreGui:FindFirstChild("DurianHub_ServerFinder")
if old then old:Destroy() end

--═══════════════ ROOT ═══════════════
local ScreenGui = new("ScreenGui", {
    Name           = "DurianHub_ServerFinder",
    ResetOnSpawn   = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, CoreGui)

-- Floating toggle pill (bottom-right, like the HTML)
local TogglePill = new("TextButton", {
    Size           = UDim2.new(0, 150, 0, 40),
    Position       = UDim2.new(1, -170, 1, -64),
    BackgroundColor3 = C.Forest,
    Text           = "👁  Hide Panel",
    TextColor3     = C.White,
    TextSize       = 13,
    Font           = Enum.Font.GothamBold,
    AutoButtonColor = false,
}, ScreenGui)
corner(20, TogglePill)
stroke(Color3.fromRGB(26, 53, 23), 1, TogglePill)

-- Main frame (the .main-frame card)
local MainFrame = new("Frame", {
    Size             = UDim2.new(0, 600, 0, 560),
    Position         = UDim2.new(0.5, -300, 0.5, -280),
    BackgroundColor3 = C.White,
    BorderSizePixel  = 0,
    Active           = true,
}, ScreenGui)
corner(24, MainFrame)
stroke(C.Border, 1, MainFrame)

--═══════════════ HEADER ═══════════════
local Header = new("Frame", {
    Size             = UDim2.new(1, -36, 0, 56),
    Position         = UDim2.new(0, 18, 0, 14),
    BackgroundTransparency = 1,
}, MainFrame)

-- Durian icon box (SVG replaced with emoji — swap for rbxassetid image if you have one)
local IconBox = new("Frame", {
    Size             = UDim2.new(0, 48, 0, 48),
    BackgroundColor3 = Color3.fromRGB(253, 251, 244),
    BorderSizePixel  = 0,
}, Header)
corner(14, IconBox)
stroke(Color3.fromRGB(224, 206, 158), 1, IconBox)

new("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
    Text = "🍈", TextSize = 24, Font = Enum.Font.GothamBold,
    TextColor3 = C.Text,
}, IconBox)

-- Brand: "Durian" + gold HUB tag + subtext
local BrandRow = new("Frame", {
    Size = UDim2.new(0, 300, 0, 24), Position = UDim2.new(0, 62, 0, 5),
    BackgroundTransparency = 1,
}, Header)
new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center,
}, BrandRow)

new("TextLabel", {
    Size = UDim2.new(0, 70, 0, 24), BackgroundTransparency = 1,
    Text = "Durian", TextColor3 = C.Forest, TextSize = 21,
    Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
}, BrandRow)

local HubTag = new("Frame", {
    AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 20),
    BackgroundColor3 = C.GoldBG, BorderSizePixel = 0,
}, BrandRow)
corner(6, HubTag)
stroke(C.GoldBorder, 1, HubTag)
new("UIPadding", {
    PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
}, HubTag)
new("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
    Text = "HUB", TextColor3 = C.GoldText, TextSize = 13,
    Font = Enum.Font.GothamBold,
}, HubTag)

new("TextLabel", {
    Size = UDim2.new(0, 300, 0, 16), Position = UDim2.new(0, 62, 0, 32),
    BackgroundTransparency = 1,
    Text = "Community Server Finder", TextColor3 = C.SubText,
    TextSize = 12, Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Header)

-- Close ✕ button
local CloseBtn = new("TextButton", {
    Size = UDim2.new(0, 38, 0, 38), Position = UDim2.new(1, -38, 0, 0),
    AnchorPoint = Vector2.new(1, 0),
    BackgroundColor3 = C.White, Text = "✕",
    TextColor3 = Color3.fromRGB(92, 102, 90), TextSize = 15,
    Font = Enum.Font.GothamBold, AutoButtonColor = false,
}, Header)
corner(10, CloseBtn)
stroke(C.Border, 1, CloseBtn)

-- Header divider line
new("Frame", {
    Size = UDim2.new(1, -36, 0, 1), Position = UDim2.new(0, 18, 0, 78),
    BackgroundColor3 = C.Divider, BorderSizePixel = 0,
}, MainFrame)

--═══════════════ TOOLBAR ═══════════════
local Toolbar = new("Frame", {
    Size = UDim2.new(1, -36, 0, 38), Position = UDim2.new(0, 18, 0, 90),
    BackgroundTransparency = 1,
}, MainFrame)
new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 8),
    VerticalAlignment = Enum.VerticalAlignment.Center,
}, Toolbar)

-- 🔍 Search box
local SearchBox = new("TextBox", {
    Size = UDim2.new(0, 200, 0, 38),
    BackgroundColor3 = Color3.fromRGB(250, 248, 243),
    Text = "", PlaceholderText = "🔍  Filter by server or ID...",
    PlaceholderColor3 = Color3.fromRGB(140, 150, 137),
    TextColor3 = C.Text, TextSize = 13, Font = Enum.Font.GothamMedium,
    ClearTextOnFocus = false,
}, Toolbar)
corner(10, SearchBox)
stroke(C.Border, 1, SearchBox)

-- Sort dropdown (replaces the region select — Roblox API has no region data)
local SortBtn = new("TextButton", {
    AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 38),
    BackgroundColor3 = Color3.fromRGB(250, 248, 243),
    Text = "All Servers  ▾", TextColor3 = Color3.fromRGB(56, 66, 54),
    TextSize = 13, Font = Enum.Font.GothamMedium, AutoButtonColor = false,
}, Toolbar)
corner(10, SortBtn)
stroke(C.Border, 1, SortBtn)
new("UIPadding", {
    PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
}, SortBtn)

-- ↻ Refresh
local RefreshBtn = new("TextButton", {
    AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 38),
    BackgroundColor3 = C.White,
    Text = "↻  Refresh", TextColor3 = Color3.fromRGB(56, 66, 54),
    TextSize = 13, Font = Enum.Font.GothamBold, AutoButtonColor = false,
}, Toolbar)
corner(10, RefreshBtn)
stroke(C.Border, 1, RefreshBtn)
new("UIPadding", {
    PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14),
}, RefreshBtn)

-- ⏱ Auto toggle (gold when ON, like .btn-toggle-active)
local AutoBtn = new("TextButton", {
    AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 38),
    BackgroundColor3 = C.GoldBG,
    Text = "⏱  Auto: ON", TextColor3 = C.GoldText,
    TextSize = 13, Font = Enum.Font.GothamBold, AutoButtonColor = false,
}, Toolbar)
corner(10, AutoBtn)
stroke(C.GoldBorder, 1, AutoBtn)
new("UIPadding", {
    PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14),
}, AutoBtn)

-- Status badge (pushed right)
local StatusBadge = new("Frame", {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 38),
    BackgroundColor3 = C.StatusBG, BorderSizePixel = 0,
}, Toolbar)
corner(20, StatusBadge)
stroke(C.StatusBorder, 1, StatusBadge)
new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 8),
    VerticalAlignment = Enum.VerticalAlignment.Center,
}, StatusBadge)
new("UIPadding", {
    PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14),
}, StatusBadge)

local StatusDot = new("Frame", {
    Size = UDim2.new(0, 8, 0, 8), BackgroundColor3 = C.DotGreen,
    BorderSizePixel = 0,
}, StatusBadge)
corner(4, StatusDot)

local StatusLabel = new("TextLabel", {
    AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 16),
    BackgroundTransparency = 1,
    Text = "Ready", TextColor3 = C.Forest, TextSize = 13,
    Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
}, StatusBadge)

--═══════════════ DROPDOWN MENU ═══════════════
local sortOptions = { "All Servers", "Low → High", "High → Low", "Not Full Only" }

local SortList = new("Frame", {
    Size = UDim2.new(0, 170, 0, #sortOptions * 34 + 8),
    Position = UDim2.new(0, 226, 0, 130),
    BackgroundColor3 = C.White, BorderSizePixel = 0,
    Visible = false, ZIndex = 10,
}, MainFrame)
corner(12, SortList)
stroke(C.Border, 1, SortList)

for i, opt in ipairs(sortOptions) do
    local ob = new("TextButton", {
        Size = UDim2.new(1, -8, 0, 30),
        Position = UDim2.new(0, 4, 0, (i - 1) * 34 + 4),
        BackgroundColor3 = C.White,
        Text = opt, TextColor3 = C.Text, TextSize = 13,
        Font = Enum.Font.GothamMedium, AutoButtonColor = false,
        ZIndex = 11,
    }, SortList)
    corner(8, ob)
    ob.MouseEnter:Connect(function() ob.BackgroundColor3 = C.GoldBG end)
    ob.MouseLeave:Connect(function() ob.BackgroundColor3 = C.White end)
    ob.MouseButton1Click:Connect(function()
        currentSort = opt
        SortBtn.Text = opt .. "  ▾"
        SortList.Visible = false
        renderList() -- forward-declared below
    end)
end

--═══════════════ SERVER LIST ═══════════════
local ListFrame = new("ScrollingFrame", {
    Size = UDim2.new(1, -36, 1, -156), Position = UDim2.new(0, 18, 0, 138),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 6,
    ScrollBarImageColor3 = Color3.fromRGB(212, 204, 189),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, MainFrame)
new("UIListLayout", {
    Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder,
}, ListFrame)

--═══════════════ SERVER FETCHING ═══════════════
local function httpGet(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok then return res end
    -- fallback for executors using request()
    if request then
        local ok2, res2 = pcall(function()
            return request({ Url = url, Method = "GET" }).Body
        end)
        if ok2 then return res2 end
    end
    return nil
end

local function fetchServers()
    local servers, cursor, pages = {}, nil, 0
    repeat
        local url = "https://games.roblox.com/v1/games/" .. PlaceId
            .. "/servers/Public?limit=100"
        if cursor then url = url .. "&cursor=" .. cursor end

        local body = httpGet(url)
        if not body then break end

        local data = HttpService:JSONDecode(body)
        for _, s in ipairs(data.data or {}) do
            table.insert(servers, s)
        end
        cursor = data.nextPageCursor
        pages += 1
    until not cursor or pages >= MAX_PAGES
    return servers
end

--═══════════════ STATUS ═══════════════
local function setStatus(text, dotColor)
    StatusLabel.Text = text
    StatusDot.BackgroundColor3 = dotColor or C.DotGreen
end

--═══════════════ SERVER ENTRY CARDS ═══════════════
local function loadTagFor(playing, maxPlayers)
    if playing <= 2 then
        return "EMPTY", C.GoldBG, C.GoldBorder, C.GoldText
    elseif playing <= maxPlayers * 0.35 then
        return "LOW", C.GreenBG, Color3.fromRGB(204, 224, 201), C.GreenText
    else
        return "BUSY", C.Divider, C.Border, C.Muted
    end
end

function renderList()
    -- Clear old entries
    for _, child in ipairs(ListFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    -- Filter by search text
    local q = string.lower(searchText)
    local filtered = {}
    for _, s in ipairs(allServers) do
        local haystack = string.lower(s.id .. " " .. s.playing .. "/" .. s.maxPlayers)
        if q == "" or string.find(haystack, q, 1, true) then
            table.insert(filtered, s)
        end
    end

    -- Sort per dropdown
    if currentSort == "Low → High" then
        table.sort(filtered, function(a, b) return a.playing < b.playing end)
    elseif currentSort == "High → Low" then
        table.sort(filtered, function(a, b) return a.playing > b.playing end)
    elseif currentSort == "Not Full Only" then
        local kept = {}
        for _, s in ipairs(filtered) do
            if s.playing < s.maxPlayers then table.insert(kept, s) end
        end
        table.sort(kept, function(a, b) return a.playing < b.playing end)
        filtered = kept
    end

    -- Build entries
    for i, server in ipairs(filtered) do
        local entry = new("Frame", {
            Size = UDim2.new(1, -8, 0, 64),
            BackgroundColor3 = C.CardBG,
            BorderSizePixel = 0,
            LayoutOrder = i,
        }, ListFrame)
        corner(14, entry)
        stroke(C.BorderSoft, 1, entry)

        -- Hover effect (.server-entry:hover)
        entry.MouseEnter:Connect(function()
            entry.BackgroundColor3 = C.White
            entry:FindFirstChildWhichIsA("UIStroke").Color = C.Sage
        end)
        entry.MouseLeave:Connect(function()
            entry.BackgroundColor3 = C.CardBG
            entry:FindFirstChildWhichIsA("UIStroke").Color = C.BorderSoft
        end)

        -- Title row: name + load tag
        local tagName, tagBG, tagBorder, tagText = loadTagFor(server.playing, server.maxPlayers)

        local titleRow = new("Frame", {
            Size = UDim2.new(1, -130, 0, 20), Position = UDim2.new(0, 16, 0, 10),
            BackgroundTransparency = 1,
        }, entry)
        new("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center,
        }, titleRow)

        new("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 18),
            BackgroundTransparency = 1,
            Text = GameName, TextColor3 = C.Text, TextSize = 15,
            Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, titleRow)

        local Tag = new("Frame", {
            AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 16),
            BackgroundColor3 = tagBG, BorderSizePixel = 0,
        }, titleRow)
        corner(4, Tag)
        stroke(tagBorder, 1, Tag)
        new("UIPadding", {
            PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6),
        }, Tag)
        new("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
            Text = tagName, TextColor3 = tagText, TextSize = 11,
            Font = Enum.Font.GothamBold,
        }, Tag)

        -- Meta row: players + region placeholder + job id
        new("TextLabel", {
            Size = UDim2.new(0, 200, 0, 16), Position = UDim2.new(0, 16, 0, 36),
            BackgroundTransparency = 1,
            Text = "👥  " .. server.playing .. " / " .. server.maxPlayers
                .. "      🆔  #" .. string.sub(server.id, 1, 8),
            TextColor3 = C.Muted, TextSize = 12, Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, entry)

        -- Join button (.btn-join)
        local JoinBtn = new("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -16, 0.5, 0),
            Size = UDim2.new(0, 100, 0, 34),
            BackgroundColor3 = C.Forest,
            Text = "Join Server", TextColor3 = C.White,
            TextSize = 13, Font = Enum.Font.GothamBold,
            AutoButtonColor = false,
        }, entry)
        corner(9, JoinBtn)

        JoinBtn.MouseEnter:Connect(function()
            JoinBtn.BackgroundColor3 = C.Sage
        end)
        JoinBtn.MouseLeave:Connect(function()
            JoinBtn.BackgroundColor3 = C.Forest
        end)
        JoinBtn.MouseButton1Click:Connect(function()
            JoinBtn.Text = "Connecting..."
            task.wait(0.2)
            local ok, err = pcall(function()
                TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LocalPlayer)
            end)
            if not ok then
                JoinBtn.Text = "Join Server"
                setStatus("Teleport failed: " .. tostring(err), C.DotRed)
            end
        end)
    end

    -- Update badge count
    setStatus(#filtered .. " Servers Online", C.DotGreen)
end

--═══════════════ REFRESH ═══════════════
local function refresh()
    if scanning then return end
    scanning = true
    setStatus("Scanning servers...", C.DotGold)

    task.spawn(function()
        allServers = fetchServers()
        scanning = false

        if #allServers == 0 then
            setStatus("No servers found", C.DotRed)
        else
            renderList()
        end
    end)
end

--═══════════════ WIRING ═══════════════
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    searchText = SearchBox.Text
    renderList()
end)

SortBtn.MouseButton1Click:Connect(function()
    SortList.Visible = not SortList.Visible
end)

RefreshBtn.MouseButton1Click:Connect(refresh)

AutoBtn.MouseButton1Click:Connect(function()
    autoOn = not autoOn
    if autoOn then
        AutoBtn.Text = "⏱  Auto: ON"
        AutoBtn.BackgroundColor3 = C.GoldBG
        AutoBtn.TextColor3 = C.GoldText
    else
        AutoBtn.Text = "⏱  Auto: OFF"
        AutoBtn.BackgroundColor3 = C.White
        AutoBtn.TextColor3 = Color3.fromRGB(56, 66, 54)
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

TogglePill.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    TogglePill.Text = MainFrame.Visible and "👁  Hide Panel" or "👁  Show Panel"
end)

-- Hide dropdown when clicking elsewhere
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       and SortList.Visible then
        local pos = input.Position
        local abs = SortList.AbsolutePosition
        local size = SortList.AbsoluteSize
        local inside = pos.X >= abs.X and pos.X <= abs.X + size.X
            and pos.Y >= abs.Y and pos.Y <= abs.Y + size.Y
        if not inside then SortList.Visible = false end
    end
end)

-- Dragging (by header, like a real window)
local dragging, dragInput, dragStart, startPos
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
       or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

--═══════════════ AUTO REFRESH LOOP ═══════════════
task.spawn(function()
    while ScreenGui.Parent do
        task.wait(AUTO_REFRESH_INTERVAL)
        if autoOn and not scanning then
            refresh()
        end
    end
end)

--═══════════════ BOOT ═══════════════
print("🍈 DurianHub Server Finder loaded!")
refresh()
