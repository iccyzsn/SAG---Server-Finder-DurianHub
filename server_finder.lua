--═══════════════════════════════════════════════════════════
--  🍈 DurianHub — Community Server Finder
--  PC + Android • Fixes #1,3,4,5,6,7,8,9,10,11,12
--  [#2 intentionally unchanged: executor-only by design]
--═══════════════════════════════════════════════════════════

if not game:IsLoaded() then game.Loaded:Wait() end

--═══════════════ CONFIG ═══════════════
local MAX_PAGES             = 10     -- [#4] was 3 (~300 servers); now ~1000
local PAGE_DELAY            = 0.15   -- pause between API pages (rate-limit safety)
local AUTO_REFRESH_INTERVAL = 30
local LOGO_REPO = "https://raw.githubusercontent.com/iccyzsn/SAG---Server-Finder-DurianHub/main/img/"

-- [#5] NOTE: the API's sortOrder is NOT a guarantee of lowest-population
-- ordering. We sort locally on every render; MAX_PAGES controls coverage.
-- Raise MAX_PAGES for deeper scans (each page = 100 servers).

--═══════════════ SERVICES ═══════════════
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

--═══════════════ CLEANUP REGISTRY [#8, #9] ═══════════════
-- Service-level connections (UserInputService, workspace) survive
-- ScreenGui:Destroy(). Every run registers a cleanup fn; the next run
-- (or Destroying) disconnects everything from the previous run.
local ENV = (type(getgenv) == "function" and getgenv()) or _G
if ENV.DURIANHUB_CLEANUP then
    pcall(ENV.DURIANHUB_CLEANUP)
end

local guiAlive = true
local tracked  = {}

local function track(conn)
    if conn then table.insert(tracked, conn) end
    return conn
end

local function cleanup()
    if not guiAlive then return end
    guiAlive = false
    for _, c in ipairs(tracked) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(tracked)
    if ENV.DURIANHUB_CLEANUP == cleanup then
        ENV.DURIANHUB_CLEANUP = nil
    end
end
ENV.DURIANHUB_CLEANUP = cleanup

--═══════════════ GUI PARENT (mobile-safe) ═══════════════
local function getGuiParent()
    if type(gethui) == "function" then
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

local oldGui = GUI_PARENT:FindFirstChild("DurianHub_ServerFinder")
if oldGui then oldGui:Destroy() end -- fires old run's Destroying → old cleanup

--═══════════════ DEVICE / LAYOUT [#10, #11] ═══════════════
local Viewport = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize)
    or Vector2.new(1280, 720)

local function computeLayout(vp)
    local mobile = (UserInputService.TouchEnabled and not UserInputService.MouseEnabled)
        or vp.X < 600
    if mobile then
        return {
            mobile = true,
            pad = 12, headerH = 44, logoSize = 40,
            divY = 62,
            searchY = 68,  searchH = 36,
            toolY   = 110, toolH = 34,
            statusY = 150, statusH = 24, statusText = 11,
            listY   = 180,
            width   = math.clamp(vp.X - 20, 300, 400),
            height  = math.clamp(vp.Y - 40, 360, 540),
            entryH  = 62, joinW = 84, joinH = 38,
            btnText = 12, metaText = 11, titleText = 13, rowH = 34,
        }
    else
        return {
            mobile = false,
            pad = 16, headerH = 48, logoSize = 44,
            divY = 70,
            searchY = 78,  searchH = 36,
            toolY   = 78,  toolH = 36,
            statusY = 122, statusH = 28, statusText = 12,
            listY   = 158,
            width   = 560, height = 480,
            entryH  = 56, joinW = 92, joinH = 34,
            btnText = 13, metaText = 12, titleText = 13, rowH = 30,
        }
    end
end

local L        = computeLayout(Viewport)
local IsMobile = L.mobile

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
local allServers = {}
local currentSort = "Low → High"   -- [#3] was "All Servers" — purpose is least players
local autoOn     = true
local scanning   = false
local searchText = ""

local sortOptions = { "Low → High", "All Servers", "High → Low", "Not Full Only" }

--═══════════════ HELPERS ═══════════════
local function new(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then inst[k] = v end
    end
    if parent then inst.Parent = parent end
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
    if type(request) == "function" then
        local ok2, res2 = pcall(function()
            return request({ Url = url, Method = "GET" }).Body
        end)
        if ok2 and res2 and #res2 > 0 then return res2 end
    end
    return nil
end

--═══════════════ LOGO ═══════════════
local LOGO_ASSET = nil
if writefile and isfile and getcustomasset then
    for _, fileName in ipairs({ "DurianHub.png", "DurianHub.jpeg", "DurianHub.jpg" }) do
        local localName = "DurianHub_" .. fileName
        if not isfile(localName) then
            local body = httpGet(LOGO_REPO .. fileName)
            if body then pcall(function() writefile(localName, body) end) end
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
local ScreenGui = new("ScreenGui", {
    Name           = "DurianHub_ServerFinder",
    ResetOnSpawn   = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder   = 999,
}, GUI_PARENT)
ScreenGui.Destroying:Connect(cleanup) -- [#8] cleanup on any destroy path

if type(protectgui) == "function" then pcall(protectgui, ScreenGui) end

--═══════════════ FLOATING LOGO (minimized state) ═══════════════
local LOGO_FLOAT_SIZE = 56

local LogoFloat = new("TextButton", {
    AnchorPoint      = Vector2.new(0.5, 0.5),
    Position         = UDim2.new(0.5, 0, 0.5, 0),
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
local NORMAL_SIZE = UDim2.new(0, L.width, 0, L.height)
local MAX_SIZE    = UDim2.new(1, IsMobile and -16 or -40, 1, IsMobile and -30 or -80)
local CENTER      = UDim2.new(0.5, 0, 0.5, 0)

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

local DurianLabel = new("TextLabel", {
    Size = UDim2.new(0, 66, 0, 22),
    Position = UDim2.new(0, L.logoSize + 12, 0, 5),
    BackgroundTransparency = 1,
    Text = "Durian", TextColor3 = C.Forest, TextSize = 19,
    Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
}, Header)

local HubTag = new("Frame", {
    AutomaticSize    = Enum.AutomaticSize.X,
    Size             = UDim2.new(0, 0, 0, 18),
    Position         = UDim2.new(0, L.logoSize + 78, 0, 7),
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

local Subtitle = new("TextLabel", {
    Size = UDim2.new(0, 220, 0, 14),
    Position = UDim2.new(0, L.logoSize + 12, 0, 27),
    BackgroundTransparency = 1,
    Text = "Community Server Finder", TextColor3 = C.SubText,
    TextSize = 11, Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Header)

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

local Divider = new("Frame", {
    Size             = UDim2.new(1, -2 * L.pad, 0, 1),
    Position         = UDim2.new(0, L.pad, 0, L.divY),
    BackgroundColor3 = C.Divider,
    BorderSizePixel  = 0,
}, MainFrame)

--═══════════════ TOOLBAR ELEMENTS ═══════════════
local SearchBox = new("TextBox", {
    Position         = UDim2.new(0, L.pad, 0, L.searchY),
    Size             = UDim2.new(1, -2 * L.pad, 0, L.searchH),
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

local function toolButton(text)
    local btn = new("TextButton", {
        Position         = UDim2.new(0, 0, 0, 0),
        Size             = UDim2.new(0, 80, 0, L.toolH),
        BackgroundColor3 = C.White,
        Text             = text,
        TextColor3       = Color3.fromRGB(56, 66, 54),
        TextSize         = L.btnText,
        Font             = Enum.Font.GothamBold,
        AutoButtonColor  = false,
    }, MainFrame)
    corner(9, btn)
    local st = stroke(C.Border, 1, btn)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = C.HoverCream end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = C.White end)
    return btn, st
end

local SortBtn    = toolButton(currentSort .. "  ▾")
local RefreshBtn, RefreshStroke = toolButton("↻  Refresh")
local AutoBtn, AutoStroke       = toolButton("⏱  Auto: ON")

AutoBtn.BackgroundColor3 = C.GoldBG
AutoBtn.TextColor3       = C.GoldText
AutoStroke.Color         = C.GoldBorder

local StatusBadge = new("Frame", {
    AnchorPoint      = Vector2.new(1, 0),
    Position         = UDim2.new(1, -L.pad, 0, L.statusY),
    AutomaticSize    = Enum.AutomaticSize.X,
    Size             = UDim2.new(0, 0, 0, L.statusH),
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

--═══════════════ SORT DROPDOWN SHELL ═══════════════
local SortList = new("Frame", {
    Size             = UDim2.new(0, 140, 0, #sortOptions * L.rowH + 8),
    Position         = UDim2.new(0, L.pad, 0, L.statusY + L.statusH + 4),
    BackgroundColor3 = C.White,
    BorderSizePixel  = 0,
    Visible          = false,
    ZIndex           = 40,
}, MainFrame)
corner(10, SortList)
stroke(C.Border, 1, SortList)

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

--═══════════════ LAYOUT FUNCTIONS [#10, #11] ═══════════════
local function layoutHeader()
    Header.Size  = UDim2.new(1, -2 * L.pad, 0, L.headerH)
    IconBox.Size = UDim2.new(0, L.logoSize, 0, L.logoSize)
    IconBox.Position = UDim2.new(0, 0, 0.5, -L.logoSize / 2)
    local textX = L.logoSize + 12
    DurianLabel.Position = UDim2.new(0, textX, 0, 5)
    HubTag.Position      = UDim2.new(0, textX + 66, 0, 7)
    Subtitle.Position    = UDim2.new(0, textX, 0, 27)
    local wbSize = IsMobile and 34 or 30
    MinBtn.Size   = UDim2.new(0, wbSize, 0, wbSize)
    MaxBtn.Size   = UDim2.new(0, wbSize, 0, wbSize)
    CloseBtn.Size = UDim2.new(0, wbSize, 0, wbSize)
    Divider.Position = UDim2.new(0, L.pad, 0, L.divY)
end

local function layoutToolbar()
    SearchBox.Position = UDim2.new(0, L.pad, 0, L.searchY)
    SearchBox.Size = L.mobile
        and UDim2.new(1, -2 * L.pad, 0, L.searchH)
        or  UDim2.new(1, -(2 * L.pad) - 180, 0, L.searchH)

    if L.mobile then
        local w3   = L.width - 2 * L.pad - 16
        local sortW = math.floor(w3 * 0.40)
        local btnW  = math.floor((w3 - sortW - 16) / 2)
        SortBtn.Position = UDim2.new(0, L.pad, 0, L.toolY)
        SortBtn.Size     = UDim2.new(0, sortW, 0, L.toolH)
        RefreshBtn.Position = UDim2.new(0, L.pad + sortW + 8, 0, L.toolY)
        RefreshBtn.Size     = UDim2.new(0, btnW, 0, L.toolH)
        AutoBtn.Position    = UDim2.new(0, L.pad + sortW + btnW + 16, 0, L.toolY)
        AutoBtn.Size        = UDim2.new(0, btnW, 0, L.toolH)
        StatusBadge.AnchorPoint = Vector2.new(0, 0)
        StatusBadge.Position    = UDim2.new(0, L.pad, 0, L.statusY)
    else
        RefreshBtn.Position = UDim2.new(1, -L.pad - 164, 0, L.toolY)
        RefreshBtn.Size     = UDim2.new(0, 78, 0, L.toolH)
        AutoBtn.Position    = UDim2.new(1, -L.pad - 82, 0, L.toolY)
        AutoBtn.Size        = UDim2.new(0, 78, 0, L.toolH)
        SortBtn.Position    = UDim2.new(0, L.pad, 0, L.statusY)
        SortBtn.Size        = UDim2.new(0, 120, 0, L.statusH)
        StatusBadge.AnchorPoint = Vector2.new(1, 0)
        StatusBadge.Position    = UDim2.new(1, -L.pad, 0, L.statusY)
    end
    StatusBadge.Size = UDim2.new(0, 0, 0, L.statusH)

    SortList.Size = UDim2.new(0, L.mobile and 160 or 140, 0, #sortOptions * L.rowH + 8)
    SortList.Position = UDim2.new(0, L.pad, 0,
        (L.mobile and L.toolY or L.statusY) + (L.mobile and L.toolH or L.statusH) + 4)

    ListFrame.Position = UDim2.new(0, L.pad, 0, L.listY)
    ListFrame.Size     = UDim2.new(1, -2 * L.pad, 1, -(L.listY + 12))
    ListFrame.ScrollBarThickness = L.mobile and 8 or 5
end

local function syncToolTexts()
    RefreshBtn.Text = scanning and "⏳"
        or (L.mobile and "↻ Refresh" or "↻  Refresh")
    AutoBtn.Text = autoOn
        and (L.mobile and "⏱ Auto ON" or "⏱  Auto: ON")
        or  (L.mobile and "⏱ Auto OFF" or "⏱  Auto: OFF")
end

layoutHeader()
layoutToolbar()
syncToolTexts()

--═══════════════ FETCH [#4, #5] ═══════════════
local function fetchServers(onProgress)
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
        pages += 1
        if onProgress then onProgress(#servers, pages) end

        cursor = data.nextPageCursor
        if cursor and pages < MAX_PAGES then
            task.wait(PAGE_DELAY)
        end
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

    -- [#5] local sort is the source of truth, not the API's ordering
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

    -- [#12] per-mode width budget so title/tag/meta never fight the Join btn
    local titleOffset = -(L.joinW + 64)

    for i, server in ipairs(filtered) do
        local isTop = (currentSort ~= "High → Low") and i <= 3
        local entry = new("Frame", {
            Size             = UDim2.new(1, -8, 0, L.entryH),
            BackgroundColor3 = C.CardBG,
            BorderSizePixel  = 0,
            LayoutOrder      = i,
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

        local tagName, tagBG, tagBorder, tagText =
            loadTagFor(server.playing, server.maxPlayers)
        local nameY = L.mobile and 10 or 9

        new("TextLabel", {
            Size = UDim2.new(1, titleOffset, 0, 18),
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
            Position         = UDim2.new(1, -(L.joinW + 28), 0, nameY + 1),
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

        -- [#12] compact meta on mobile
        local metaText = L.mobile
            and ("👥 %d/%d  ·  #%s"):format(server.playing, server.maxPlayers, string.sub(server.id, 1, 8))
            or  ("👥  %d / %d      🆔  #%s"):format(server.playing, server.maxPlayers, string.sub(server.id, 1, 8))

        new("TextLabel", {
            Size = UDim2.new(1, titleOffset, 0, 14),
            Position = UDim2.new(0, 14, 0, nameY + 22),
            BackgroundTransparency = 1,
            Text = metaText,
            TextColor3 = C.Muted, TextSize = L.metaText,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, entry)

        local JoinBtn = new("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position    = UDim2.new(1, -12, 0.5, 0),
            Size        = UDim2.new(0, L.joinW, 0, L.joinH),
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
            local ok = pcall(function()
                TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LocalPlayer)
            end)
            if not ok then
                JoinBtn.Text = "Join"
                setStatus("Teleport failed", C.DotRed)
            end
        end)
    end

    setStatus(tostring(#filtered) .. (L.mobile and " online" or " Servers Online"), C.DotGreen)
end

--═══════════════ REFRESH [#6, #7] ═══════════════
local function refresh()
    if scanning then return end
    scanning = true
    syncToolTexts()
    setStatus(L.mobile and "Scanning..." or "Scanning servers...", C.DotGold)

    -- [#6] clear stale entries immediately; no old data on screen mid-scan
    for _, child in ipairs(ListFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    task.spawn(function()
        -- [#7] pcall guarantees scanning resets on ANY error
        local ok, result = pcall(fetchServers, function(found, pages)
            if guiAlive then
                setStatus(("Scanning p.%d — %d servers"):format(pages, found), C.DotGold)
            end
        end)

        scanning = false
        if not guiAlive then return end
        syncToolTexts()

        if not ok then
            setStatus("Scan failed", C.DotRed)
            return
        end

        allServers = result
        if #allServers == 0 then
            setStatus("No servers found", C.DotRed)
        else
            renderList()
        end
    end)
end

--═══════════════ SORT MENU ITEMS ═══════════════
local function syncSortText()
    SortBtn.Text = currentSort .. (L.mobile and " ▾" or "  ▾")
end

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
        syncSortText()
        SortList.Visible = false
        renderList()
    end)
end

--═══════════════ WINDOW STATE + TWEENS ═══════════════
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

    track(UserInputService.InputChanged:Connect(function(input)
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
    end))

    return function() return moved end
end

-- [#1] assign drag getters BEFORE any closure that reads them
makeDraggable(Header, MainFrame)
local logoDragMoved = makeDraggable(LogoFloat, LogoFloat)

--═══════════════ BUTTON WIRING ═══════════════
MinBtn.MouseButton1Click:Connect(function()
    if not isMinimized then
        isMinimized = true
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
    -- [#1] logoDragMoved is a proper local, assigned above
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
    cleanup()          -- [#8] disconnect all service connections
    ScreenGui:Destroy()
end)

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
        AutoBtn.BackgroundColor3 = C.GoldBG
        AutoBtn.TextColor3       = C.GoldText
        AutoStroke.Color         = C.GoldBorder
    else
        AutoBtn.BackgroundColor3 = C.White
        AutoBtn.TextColor3       = Color3.fromRGB(56, 66, 54)
        AutoStroke.Color         = C.Border
    end
    syncToolTexts()
end)

-- Tap/click-away closes sort menu (tracked — dies with cleanup)
track(UserInputService.InputBegan:Connect(function(input, processed)
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
end))

--═══════════════ RESPONSIVE RELAYOUT [#10, #11] ═══════════════
local function doRelayout(vp)
    Viewport = vp
    L        = computeLayout(vp)
    IsMobile = L.mobile

    NORMAL_SIZE = UDim2.new(0, L.width, 0, L.height)
    MAX_SIZE    = UDim2.new(1, IsMobile and -16 or -40, 1, IsMobile and -30 or -80)

    if isMaximized then
        MainFrame.Size = MAX_SIZE
    elseif not isMinimized then
        MainFrame.Size = NORMAL_SIZE
        -- clamp back on-screen after rotation
        local abs = MainFrame.AbsolutePosition
        if abs.X > vp.X - 60 or abs.Y > vp.Y - 60
           or abs.X + MainFrame.AbsoluteSize.X < 60
           or abs.Y + MainFrame.AbsoluteSize.Y < 60 then
            MainFrame.Position = CENTER
            savedPos = CENTER
        end
    end
    if isMinimized then
        savedSize = NORMAL_SIZE -- remembered size follows new layout
    end

    SearchBox.TextSize    = L.btnText
    SortBtn.TextSize      = L.btnText
    RefreshBtn.TextSize   = L.btnText
    AutoBtn.TextSize      = L.btnText
    StatusLabel.TextSize  = L.statusText

    layoutHeader()
    layoutToolbar()
    syncSortText()
    syncToolTexts()

    -- rebuild entries with new metrics
    if not scanning and #allServers > 0 then
        renderList()
    end
end

local lastVpX, lastVpY = Viewport.X, Viewport.Y
local relayoutPending = false

local function requestRelayout()
    if relayoutPending then return end
    relayoutPending = true
    task.delay(0.35, function()
        relayoutPending = false
        if not guiAlive then return end
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(lastVpX, lastVpY)
        if math.abs(vp.X - lastVpX) < 80 and math.abs(vp.Y - lastVpY) < 80 then
            return -- ignore tiny resizes (keyboard pop-up etc.)
        end
        lastVpX, lastVpY = vp.X, vp.Y
        doRelayout(vp)
    end)
end

local function bindCamera()
    local cam = workspace.CurrentCamera
    if cam then
        track(cam:GetPropertyChangedSignal("ViewportSize"):Connect(requestRelayout))
    end
end
bindCamera()
track(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera))

--═══════════════ AUTO REFRESH LOOP ═══════════════
task.spawn(function()
    while guiAlive and ScreenGui.Parent do
        task.wait(AUTO_REFRESH_INTERVAL)
        if guiAlive and autoOn and not scanning then
            refresh()
        end
    end
end)

--═══════════════ BOOT ═══════════════
print(("🍈 DurianHub loaded! [%s | parent: %s | logo: %s]"):format(
    IsMobile and "MOBILE" or "PC",
    ScreenGui.Parent and ScreenGui.Parent.Name or "?",
    LOGO_ASSET and "repo ✓" or "none"
))
refresh()
