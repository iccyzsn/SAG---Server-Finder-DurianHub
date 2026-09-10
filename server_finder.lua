--═══════════════════════════════════════════════════════════
--  🍈 DurianHub — Community Server Finder
--  PC + Android • Fixed invisible-GUI bug • No placeholders
--═══════════════════════════════════════════════════════════

if not game:IsLoaded() then game.Loaded:Wait() end

--// CONFIG
local MAX_PAGES             = 3
local AUTO_REFRESH_INTERVAL = 30
local LOGO_REPO = "https://raw.githubusercontent.com/iccyzsn/SAG---Server-Finder-DurianHub/main/img/"

--// SERVICES
local HttpService        = game:GetService("HttpService")
local TweenService       = game:GetService("TweenService")
local TeleportService    = game:GetService("TeleportService")
local Players            = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService   = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlaceId     = game.PlaceId

local GameName = "Server Finder"
pcall(function()
    GameName = MarketplaceService:GetProductInfo(PlaceId).Name or GameName
end)

--═══════════════ DEVICE DETECTION ═══════════════
local Viewport = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize)
    or Vector2.new(1280, 720)

local IsMobile = (UserInputService.TouchEnabled and not UserInputService.MouseEnabled)
    or Viewport.X < 600

--// Responsive layout
local L
if IsMobile then
    L = {
        pad = 12, headerH = 44, logoSize = 40,
        searchY = 70,  searchH = 36,
        toolY   = 112, toolH   = 32,
        statusY = 150, statusH = 26, statusText = 11,
        listY   = 182,
        width   = math.clamp(Viewport.X - 20, 300, 400),
        height  = math.clamp(Viewport.Y - 30, 380, 520),
        entryH  = 62, joinW = 88, joinH = 38,
        btnText = 12, metaText = 11, titleText = 13,
        rowH    = 34,
    }
else
    L = {
        pad = 16, headerH = 48, logoSize = 44,
        searchY = 80,  searchH = 36,
        toolY   = 80,  toolH   = 36,
        statusY = 122, statusH = 28, statusText = 12,
        listY   = 158,
        width   = 560, height = 480,
        entryH  = 56, joinW = 92, joinH = 34,
        btnText = 13, metaText = 12, titleText = 13,
        rowH    = 30,
    }
end

local NORMAL_SIZE = UDim2.new(0, L.width, 0, L.height)
local MAX_SIZE    = UDim2.new(1, IsMobile and -16 or -40, 1, IsMobile and -30 or -80)
local CENTER      = UDim2.new(0.5, 0, 0.5, 0)

--═══════════════ PALETTE ═══════════════
local C = {
    Forest = Color3.fromRGB(36, 72, 32),      Sage = Color3.fromRGB(59, 107, 53),
    Gold = Color3.fromRGB(224, 169, 56),
    GoldBG = Color3.fromRGB(247, 237, 213),   GoldBorder = Color3.fromRGB(235, 212, 159),
    GoldText = Color3.fromRGB(122, 81, 8),
    Cream = Color3.fromRGB(253, 251, 244),    CreamDeep = Color3.fromRGB(245, 235, 211),
    CardBG = Color3.fromRGB(250, 248, 244),   White = Color3.fromRGB(255, 255, 255),
    Border = Color3.fromRGB(224, 217, 204),   BorderSoft = Color3.fromRGB(236, 230, 218),
    Divider = Color3.fromRGB(239, 235, 225),
    Text = Color3.fromRGB(26, 33, 25),        Muted = Color3.fromRGB(102, 112, 100),
    SubText = Color3.fromRGB(113, 125, 111),
    GreenBG = Color3.fromRGB(234, 245, 233),  GreenText = Color3.fromRGB(43, 122, 39),
    StatusBG = Color3.fromRGB(240, 245, 239), StatusBorder = Color3.fromRGB(204, 224, 201),
    DotGreen = Color3.fromRGB(34, 197, 94),   DotGold = Color3.fromRGB(224, 169, 56),
    DotRed = Color3.fromRGB(220, 80, 80),
    HoverCream = Color3.fromRGB(244, 240, 230),
    IdText = Color3.fromRGB(140, 150, 137),
    InputBG = Color3.fromRGB(250, 248, 243),
}

--═══════════════ STATE ═══════════════
local allServers  = {}
local currentSort = "All Servers"
local autoOn      = true
local scanning    = false
local searchText  = ""

--═══════════════ HELPERS ═══════════════
-- ✅ FIXED: never lets a "Parent" prop get overwritten with nil afterward
local function new(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then
            inst[k] = v
        end
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

local function corner(r, parent)
    return new("UICorner", { CornerRadius = UDim.new(0, r) }, parent)
end

local function stroke(color, t, parent)
    return new("UIStroke", {
        Color = color, Thickness = t or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function httpGet(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and res and #res > 0 then return res end
    if request then
        local ok2, res2 = pcall(function()
            return request({ Url = url, Method = "GET" }).Body
        end)
        if ok2 and res2 and #res2 > 0 then return res2 end
    end
    return nil
end

--═══════════════ GUI PARENT (mobile-safe chain) ═══════════════
local function getGuiParent()
    if gethui then
        local ok, ui = pcall(gethui)
        if ok and ui then return ui end
    end
    local probe = Instance.new("Folder")
    local canCore = pcall(function()
        probe.Name = "__DH_Probe"
        probe.Parent = game:GetService("CoreGui")
    end)
    if canCore then
        probe:Destroy()
        return game:GetService("CoreGui")
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local GUI_PARENT = getGuiParent()

--═══════════════ LOGO ═══════════════
local LOGO_ASSET = nil
if writefile and isfile and getcustomasset then
    for _, fileName in ipairs({ "DurianHub.png", "DurianHub.jpeg", "DurianHub.jpg" }) do
        local localName = "DurianHub_" .. fileName
        if not isfile(localName) then
            local body = httpGet(LOGO_REPO .. fileName)
            if body then
                pcall(function() writefile(localName, body) end)
            end
        end
        if isfile(localName) then
            local ok, asset = pcall(getcustomasset, localName)
            if ok and asset then
                LOGO_ASSET = asset
                break
            end
        end
    end
end

--═══════════════ ROOT ═══════════════
local old = GUI_PARENT:FindFirstChild("DurianHub_ServerFinder")
if old then old:Destroy() end

-- ✅ FIXED: parent passed as 3rd arg, not inside props
local ScreenGui = new("ScreenGui", {
    Name           = "DurianHub_ServerFinder",
    ResetOnSpawn   = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder   = 999,
    IgnoreGuiInset = false,
}, GUI_PARENT)

if protectgui then pcall(protectgui, ScreenGui) end

--═══════════════ MINIMIZED LOGO BUTTON ═══════════════
local LOGO_FLOAT_SIZE = IsMobile and 58 or 52

local LogoFloat = new("TextButton", {
    AnchorPoint      = Vector2.new(0.5, 0.5),
    Position         = CENTER,
    Size             = UDim2.new(0, LOGO_FLOAT_SIZE, 0, LOGO_FLOAT_SIZE),
    BackgroundColor3 = C.Cream,
    BorderSizePixel  = 0,
    Text             = "",
    AutoButtonColor  = false,
    Visible          = false,
    ZIndex           = 50,
}, ScreenGui)
corner(16, LogoFloat)
stroke(C.GoldBorder, 1.5, LogoFloat)

if LOGO_ASSET then
    new("ImageLabel", {
        Size = UDim2.new(1, -12, 1, -12),
        Position = UDim2.new(0, 6, 0, 6),
        BackgroundTransparency = 1,
        Image = LOGO_ASSET,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 51,
    }, LogoFloat)
end

--═══════════════ MAIN FRAME ═══════════════
local MainFrame = new("Frame", {
    AnchorPoint      = Vector2.new(0.5, 0.5),
    Position         = CENTER,
    Size             = NORMAL_SIZE,
    BackgroundColor3 = C.White,
    BorderSizePixel  = 0,
    Active           = true,
}, ScreenGui)
corner(20, MainFrame)
stroke(Color3.fromRGB(230, 224, 212), 1, MainFrame)

--═══════════════ HEADER ═══════════════
local Header = new("Frame", {
    Size                   = UDim2.new(1, -2 * L.pad, 0, L.headerH),
    Position               = UDim2.new(0, L.pad, 0, 12),
    BackgroundTransparency = 1,
    Active                 = true,
}, MainFrame)

-- Logo icon box in header
local IconBox = new("Frame", {
    Size             = UDim2.new(0, L.logoSize, 0, L.logoSize),
    Position         = UDim2.new(0, 0, 0.5, -L.logoSize / 2),
    BackgroundColor3 = C.Cream,
    BorderSizePixel  = 0,
}, Header)
corner(math.floor(L.logoSize * 0.29), IconBox)
stroke(Color3.fromRGB(224, 206, 158), 1, IconBox)
if LOGO_ASSET then
    new("ImageLabel", {
        Size = UDim2.new(1, -10, 1, -10),
        Position = UDim2.new(0, 5, 0, 5),
        BackgroundTransparency = 1,
        Image = LOGO_ASSET,
        ScaleType = Enum.ScaleType.Fit,
    }, IconBox)
end

local textX = L.logoSize + 12

new("TextLabel", {
    Size = UDim2.new(0, 66, 0, 22), Position = UDim2.new(0, textX, 0, 5),
    BackgroundTransparency = 1,
    Text = "Durian", TextColor3 = C.Forest, TextSize = 19,
    Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
}, Header)

local HubTag = new("Frame", {
    AutomaticSize    = Enum.AutomaticSize.X,
    Size             = UDim2.new(0, 0, 0, 18),
    Position         = UDim2.new(0, textX + 66, 0, 7),
    BackgroundColor3 = C.GoldBG,
    BorderSizePixel  = 0,
}, Header)
corner(5, HubTag)
stroke(C.GoldBorder, 1, HubTag)
new("UIPadding", {
    PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6),
}, HubTag)
new("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
    Text = "HUB", TextColor3 = C.GoldText, TextSize = 11,
    Font = Enum.Font.GothamBold,
}, HubTag)

new("TextLabel", {
    Size = UDim2.new(0, 220, 0, 14), Position = UDim2.new(0, textX, 0, 27),
    BackgroundTransparency = 1,
    Text = "Community Server Finder", TextColor3 = C.SubText,
    TextSize = 11, Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Header)

-- Window buttons
local function windowButton(text, xOffset, isClose)
    local btn = new("TextButton", {
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, xOffset, 0.5, 0),
        Size             = UDim2.new(0, IsMobile and 34 or 30, 0, IsMobile and 34 or 30),
        BackgroundColor3 = C.White,
        Text             = text,
        TextColor3       = isClose and Color3.fromRGB(190, 60, 60) or Color3.fromRGB(92, 102, 90),
        TextSize         = 14,
        Font             = Enum.Font.GothamBold,
        BorderSizePixel  = 0,
        AutoButtonColor  = false,
    }, Header)
    corner(9, btn)
    stroke(C.Border, 1, btn)
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = isClose and Color3.fromRGB(253, 235, 235) or C.HoverCream
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = C.White
    end)
    return btn
end

local MinBtn   = windowButton("—", 0, false)
local MaxBtn   = windowButton("▢", IsMobile and -42 or -38, false)
local CloseBtn = windowButton("✕", IsMobile and -84 or -76, true)

new("Frame", { -- header divider
    Size             = UDim2.new(1, -2 * L.pad, 0, 1),
    Position         = UDim2.new(0, L.pad, 0, L.headerH + 22),
    BackgroundColor3 = C.Divider,
    BorderSizePixel  = 0,
}, MainFrame)

--═══════════════ TOOLBAR ═══════════════
local SearchBox = new("TextBox", {
    Position         = UDim2.new(0, L.pad, 0, L.searchY),
    Size             = IsMobile
        and UDim2.new(1, -2 * L.pad, 0, L.searchH)
        or UDim2.new(1, -(2 * L.pad) - 180, 0, L.searchH),
    BackgroundColor3 = C.InputBG,
    Text             = "",
    PlaceholderText  = "🔍  Filter by server or ID...",
    PlaceholderColor3 = C.IdText,
    TextColor3       = C.Text,
    TextSize         = L.btnText,
    Font             = Enum.Font.GothamMedium,
    ClearTextOnFocus = false,
}, MainFrame)
corner(9, SearchBox)
local SearchStroke = stroke(C.Border, 1, SearchBox)
SearchBox.Focused:Connect(function()
    SearchBox.BackgroundColor3 = C.White
    SearchStroke.Color = C.Forest
end)
SearchBox.FocusLost:Connect(function()
    SearchBox.BackgroundColor3 = C.InputBG
    SearchStroke.Color = C.Border
end)

local function toolButton(pos, size, text)
    local btn = new("TextButton", {
        Position = pos, Size = size,
        BackgroundColor3 = C.White,
        Text = text, TextColor3 = Color3.fromRGB(56, 66, 54),
        TextSize = L.btnText, Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
    }, MainFrame)
    corner(9, btn)
    local st = stroke(C.Border, 1, btn)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = C.HoverCream end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = C.White end)
    return btn, st
end

local RefreshBtn, RefreshStroke
local AutoBtn, AutoStroke
local SortBtn

if IsMobile then
    local third = (L.width - 2 * L.pad - 16) / 3
    SortBtn = toolButton(
        UDim2.new(0, L.pad, 0, L.toolY), UDim2.new(0, third + 16, 0, L.toolH),
        "All Servers ▾"
    )
    RefreshBtn, RefreshStroke = toolButton(
        UDim2.new(0, L.pad + third + 26, 0, L.toolY), UDim2.new(0, third - 5, 0, L.toolH),
        "↻ Refresh"
    )
    AutoBtn, AutoStroke = toolButton(
        UDim2.new(0, L.pad + third * 2 + 21, 0, L.toolY), UDim2.new(0, third - 5, 0, L.toolH),
        "⏱ Auto ON"
    )
else
    RefreshBtn, RefreshStroke = toolButton(
        UDim2.new(1, -L.pad - 160, 0, L.toolY), UDim2.new(0, 76, 0, L.toolH),
        "↻  Refresh"
    )
    AutoBtn, AutoStroke = toolButton(
        UDim2.new(1, -L.pad - 80, 0, L.toolY), UDim2.new(0, 76, 0, L.toolH),
        "⏱  Auto: ON"
    )
    SortBtn = toolButton(
        UDim2.new(0, L.pad, 0, L.statusY), UDim2.new(0, 110, 0, L.statusH),
        "All Servers  ▾"
    )
end

-- Gold "ON" state for Auto
AutoBtn.BackgroundColor3 = C.GoldBG
AutoBtn.TextColor3 = C.GoldText
AutoStroke.Color = C.GoldBorder

-- Status badge
local StatusBadge = new("Frame", {
    AnchorPoint   = Vector2.new(IsMobile and 0 or 1, 0),
    Position      = IsMobile
        and UDim2.new(0, L.pad, 0, L.statusY)
        or UDim2.new(1, -L.pad, 0, L.statusY),
    AutomaticSize = Enum.AutomaticSize.X,
    Size          = UDim2.new(0, 0, 0, L.statusH),
    BackgroundColor3 = C.StatusBG,
    BorderSizePixel  = 0,
}, MainFrame)
corner(14, StatusBadge)
stroke(C.StatusBorder, 1, StatusBadge)
new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 6),
    VerticalAlignment = Enum.VerticalAlignment.Center,
}, StatusBadge)
new("UIPadding", {
    PaddingLeft = UDim.new(0, 11), PaddingRight = UDim.new(0, 11),
}, StatusBadge)

local StatusDot = new("Frame", {
    Size = UDim2.new(0, 8, 0, 8), BackgroundColor3 = C.DotGreen,
    BorderSizePixel = 0,
}, StatusBadge)
corner(4, StatusDot)

local StatusLabel = new("TextLabel", {
    AutomaticSize = Enum.AutomaticSize.X,
    Size = UDim2.new(0, 0, 0, 14),
    BackgroundTransparency = 1,
    Text = "Ready", TextColor3 = C.Forest, TextSize = L.statusText,
    Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
}, StatusBadge)

--═══════════════ SERVER LIST ═══════════════
local ListFrame = new("ScrollingFrame", {
    Position             = UDim2.new(0, L.pad, 0, L.listY),
    Size                 = UDim2.new(1, -2 * L.pad, 1, -(L.listY + 12)),
    BackgroundTransparency = 1,
    BorderSizePixel      = 0,
    ScrollBarThickness   = IsMobile and 8 or 5,
    ScrollBarImageColor3 = Color3.fromRGB(212, 204, 189),
    CanvasSize           = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize  = Enum.AutomaticSize.Y,
}, MainFrame)
new("UIListLayout", {
    Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
}, ListFrame)

--═══════════════ FETCH ═══════════════
local function fetchServers()
    local servers, cursor, pages = {}, nil, 0
    repeat
        local url = "https://games.roblox.com/v1/games/" .. PlaceId
            .. "/servers/Public?sortOrder=Asc&limit=100"
        if cursor then url = url .. "&cursor=" .. cursor end

        local body = httpGet(url)
        if not body then break end

        local ok, data = pcall(HttpService.JSONDecode, HttpService, body)
        if not ok or not data then break end

        for _, s in ipairs(data.data or {}) do table.insert(servers, s) end
        cursor = data.nextPageCursor
        pages += 1
        task.wait(0.1)
    until not cursor or pages >= MAX_PAGES
    return servers
end

--═══════════════ RENDER ═══════════════
local function setStatus(text, dotColor)
    StatusLabel.Text = text
    StatusDot.BackgroundColor3 = dotColor or C.DotGreen
end

local function loadTagFor(playing, maxPlayers)
    if playing <= 3 then
        return "EMPTY", C.GoldBG, C.GoldBorder, C.GoldText
    elseif playing <= maxPlayers * 0.35 then
        return "LOW", C.GreenBG, C.StatusBorder, C.GreenText
    else
        return "BUSY", C.Divider, C.Border, C.Muted
    end
end

local function renderList()
    for _, child in ipairs(ListFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local q = string.lower(searchText)
    local filtered = {}
    for _, s in ipairs(allServers) do
        local hay = string.lower(s.id .. " " .. s.playing .. "/" .. s.maxPlayers)
        if q == "" or string.find(hay, q, 1, true) then
            table.insert(filtered, s)
        end
    end

    if currentSort == "Low → High" or currentSort == "Not Full Only" then
        if currentSort == "Not Full Only" then
            local kept = {}
            for _, s in ipairs(filtered) do
                if s.playing < s.maxPlayers then table.insert(kept, s) end
            end
            filtered = kept
        end
        table.sort(filtered, function(a, b) return a.playing < b.playing end)
    elseif currentSort == "High → Low" then
        table.sort(filtered, function(a, b) return a.playing > b.playing end)
    end

    local nameWidth = -(L.joinW + 100)

    for i, server in ipairs(filtered) do
        local isTop = (currentSort ~= "High → Low") and i <= 3
        local entry = new("Frame", {
            Size = UDim2.new(1, -8, 0, L.entryH),
            BackgroundColor3 = C.CardBG,
            BorderSizePixel = 0,
            LayoutOrder = i,
        }, ListFrame)
        corner(12, entry)
        local entryStroke = stroke(C.BorderSoft, 1, entry)
        if isTop then
            entryStroke.Color = C.Gold
            entryStroke.Transparency = 0.35
        end

        entry.MouseEnter:Connect(function()
            entry.BackgroundColor3 = C.White
            entryStroke.Color = C.Sage
        end)
        entry.MouseLeave:Connect(function()
            entry.BackgroundColor3 = C.CardBG
            entryStroke.Color = isTop and C.Gold or C.BorderSoft
        end)

        -- Title
        local tagName, tagBG, tagBorder, tagText = loadTagFor(server.playing, server.maxPlayers)
        local nameY = IsMobile and 10 or 9

        new("TextLabel", {
            Size = UDim2.new(1, nameWidth, 0, 18),
            Position = UDim2.new(0, 14, 0, nameY),
            BackgroundTransparency = 1,
            Text = (isTop and ("#" .. i .. "  ") or "") .. GameName,
            TextColor3 = C.Text, TextSize = L.titleText,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, entry)

        local Tag = new("Frame", {
            AnchorPoint      = Vector2.new(1, 0),
            Position         = UDim2.new(1, -(L.joinW + 34), 0, nameY + 2),
            AutomaticSize    = Enum.AutomaticSize.X,
            Size             = UDim2.new(0, 0, 0, 15),
            BackgroundColor3 = tagBG,
            BorderSizePixel  = 0,
        }, entry)
        corner(4, Tag)
        stroke(tagBorder, 1, Tag)
        new("UIPadding", {
            PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5),
        }, Tag)
        new("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
            Text = tagName, TextColor3 = tagText, TextSize = 10,
            Font = Enum.Font.GothamBold,
        }, Tag)

        -- Meta
        new("TextLabel", {
            Size = UDim2.new(1, nameWidth, 0, 14),
            Position = UDim2.new(0, 14, 0, nameY + 22),
            BackgroundTransparency = 1,
            Text = "👥  " .. server.playing .. " / " .. server.maxPlayers
                .. "      🆔  #" .. string.sub(server.id, 1, 8),
            TextColor3 = C.Muted, TextSize = L.metaText,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, entry)

        -- Join
        local JoinBtn = new("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -12, 0.5, 0),
            Size = UDim2.new(0, L.joinW, 0, L.joinH),
            BackgroundColor3 = C.Forest,
            Text = "Join", TextColor3 = C.White,
            TextSize = L.btnText, Font = Enum.Font.GothamBold,
            AutoButtonColor = false,
        }, entry)
        corner(8, JoinBtn)
        JoinBtn.MouseEnter:Connect(function() JoinBtn.BackgroundColor3 = C.Sage end)
        JoinBtn.MouseLeave:Connect(function() JoinBtn.BackgroundColor3 = C.Forest end)
        JoinBtn.MouseButton1Click:Connect(function()
            JoinBtn.Text = "..."
            task.wait(0.2)
            local ok, err = pcall(function()
                TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LocalPlayer)
            end)
            if not ok then
                JoinBtn.Text = "Join"
                setStatus("Teleport failed", C.DotRed)
            end
        end)
    end

    setStatus((#filtered) .. (IsMobile and " online" or " Servers Online"), C.DotGreen)
end

--═══════════════ REFRESH ═══════════════
local function refresh()
    if scanning then return end
    scanning = true
    setStatus(IsMobile and "Scanning..." or "Scanning servers...", C.DotGold)
    RefreshBtn.Text = IsMobile and "⏳" or "⏳"

    task.spawn(function()
        allServers = fetchServers()
        scanning = false
        RefreshBtn.Text = IsMobile and "↻ Refresh" or "↻  Refresh"

        if #allServers == 0 then
            setStatus("No servers found", C.DotRed)
        else
            renderList()
        end
    end)
end

--═══════════════ SORT MENU ═══════════════
local sortOptions = { "All Servers", "Low → High", "High → Low", "Not Full Only" }

local menuAnchorY = IsMobile and L.toolY or L.statusY
local menuAnchorH = IsMobile and L.toolH or L.statusH

local SortList = new("Frame", {
    Size = UDim2.new(0, IsMobile and 150 or 140, 0, #sortOptions * L.rowH + 8),
    Position = UDim2.new(0, L.pad, 0, menuAnchorY + menuAnchorH + 4),
    BackgroundColor3 = C.White,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 40,
}, MainFrame)
corner(10, SortList)
stroke(C.Border, 1, SortList)

for i, opt in ipairs(sortOptions) do
    local ob = new("TextButton", {
        Size = UDim2.new(1, -8, 0, L.rowH - 4),
        Position = UDim2.new(0, 4, 0, (i - 1) * L.rowH + 4),
        BackgroundColor3 = C.White,
        Text = opt, TextColor3 = C.Text, TextSize = L.btnText,
        Font = Enum.Font.GothamMedium, AutoButtonColor = false,
        ZIndex = 41,
    }, SortList)
    corner(7, ob)
    ob.MouseEnter:Connect(function() ob.BackgroundColor3 = C.GoldBG end)
    ob.MouseLeave:Connect(function() ob.BackgroundColor3 = C.White end)
    ob.MouseButton1Click:Connect(function()
        currentSort = opt
        SortBtn.Text = opt .. (IsMobile and " ▾" or "  ▾")
        SortList.Visible = false
        renderList()
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
        AutoBtn.Text = IsMobile and "⏱ Auto ON" or "⏱  Auto: ON"
        AutoBtn.BackgroundColor3 = C.GoldBG
        AutoBtn.TextColor3 = C.GoldText
        AutoStroke.Color = C.GoldBorder
    else
        AutoBtn.Text = IsMobile and "⏱ Auto OFF" or "⏱  Auto: OFF"
        AutoBtn.BackgroundColor3 = C.White
        AutoBtn.TextColor3 = Color3.fromRGB(56, 66, 54)
        AutoStroke.Color = C.Border
    end
end)

-- Min / Max / Close
local isMinimized, isMaximized = false, false
local savedSize, savedPos = NORMAL_SIZE, CENTER

local function tweenFrame(size, pos)
    local t = TweenService:Create(MainFrame,
        TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = size, Position = pos })
    t:Play()
    return t
end

local function popLogo()
    LogoFloat.Visible = true
    LogoFloat.Size = UDim2.new(0, 34, 0, 34)
    TweenService:Create(LogoFloat,
        TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Size = UDim2.new(0, LOGO_FLOAT_SIZE, 0, LOGO_FLOAT_SIZE) }):Play()
end

local function restoreWindow()
    isMinimized = false
    LogoFloat.Visible = false
    MainFrame.Visible = true
    local size = isMaximized and MAX_SIZE or savedSize
    local pos  = isMaximized and CENTER or savedPos
    tweenFrame(size, pos)
end

MinBtn.MouseButton1Click:Connect(function()
    if not isMinimized then
        isMinimized = true
        -- ✅ don't overwrite saved size while maximized
        if not isMaximized then
            savedSize, savedPos = MainFrame.Size, MainFrame.Position
        end
        MainFrame.Visible = false
        popLogo()
    else
        restoreWindow()
    end
end)

LogoFloat.MouseButton1Click:Connect(function()
    if isMinimized and logoDragMoved() < 8 then
        restoreWindow()
    end
end)

MaxBtn.MouseButton1Click:Connect(function()
    if isMinimized then return end
    if not isMaximized then
        isMaximized = true
        savedSize, savedPos = MainFrame.Size, MainFrame.Position
        MaxBtn.Text = "❐"
        tweenFrame(MAX_SIZE, CENTER)
    else
        isMaximized = false
        MaxBtn.Text = "▢"
        tweenFrame(savedSize, savedPos)
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

--═══════════════ DRAGGING ═══════════════
local function makeDraggable(handle, target)
    local dragging, dragInput, dragStart, startPos, moved = false, nil, nil, nil, 0

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            moved     = 0
            dragStart = input.Position
            startPos  = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
           or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            moved = math.abs(delta.X) + math.abs(delta.Y)
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
            if target == MainFrame and not isMaximized then
                savedPos = target.Position
            end
        end
    end)

    return function() return moved end
end

makeDraggable(Header, MainFrame)
local logoDragMoved = makeDraggable(LogoFloat, LogoFloat)

-- Tap-away closes sort menu
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if (input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch)
       and SortList.Visible then
        local p = input.Position
        local a, s = SortList.AbsolutePosition, SortList.AbsoluteSize
        local inside = p.X >= a.X and p.X <= a.X + s.X
            and p.Y >= a.Y and p.Y <= a.Y + s.Y
        if not inside then SortList.Visible = false end
    end
end)

-- Recenter if viewport changes (rotation/resize)
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        Viewport = workspace.CurrentCamera.ViewportSize
        local abs = MainFrame.AbsolutePosition
        if abs.X > Viewport.X - 40 or abs.Y > Viewport.Y - 40 then
            MainFrame.Position = CENTER
            savedPos = CENTER
        end
    end)
end

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
print(("🍈 DurianHub loaded! [%s | UI: %s | logo: %s]"):format(
    IsMobile and "MOBILE" or "PC",
    ScreenGui.Parent and ScreenGui.Parent.Name or "?",
    LOGO_ASSET and "repo ✓" or "none"
))
refresh()
