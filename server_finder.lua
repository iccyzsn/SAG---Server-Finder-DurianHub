-- Services
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- HTTP request function detection
local requestFunc
local executors = {
    syn and syn.request,
    http and http.request,
    http_request,
    fluxus and fluxus.request,
    request
}
for _, f in ipairs(executors) do
    if f then requestFunc = f; break end
end
if not requestFunc then
    error("No HTTP request function found! 😢")
end

-- Get game name
local gameName = "Unknown"
pcall(function()
    local info = MarketplaceService:GetProductInfo(game.PlaceId)
    gameName = info.Name or gameName
end)

-- ==================== UI COLOURS (DurianHub palette) ====================
local COLORS = {
    PrimaryGreen   = Color3.fromRGB(36, 72, 32),
    SecondaryGreen = Color3.fromRGB(59, 107, 53),
    Gold           = Color3.fromRGB(224, 169, 56),
    LightGold      = Color3.fromRGB(245, 200, 105),
    Cream          = Color3.fromRGB(248, 246, 240),
    TextDark       = Color3.fromRGB(26, 33, 25),
    TextMuted      = Color3.fromRGB(102, 112, 100),
    Border         = Color3.fromRGB(230, 224, 212),
    CardBg         = Color3.fromRGB(250, 248, 244),
    CardHover      = Color3.fromRGB(255, 255, 255),
    Shadow         = Color3.fromRGB(0, 0, 0),
}

-- ==================== CREATE MAIN GUI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DurianHubGUI"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ==================== MAIN FRAME ====================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MainFrame.BorderSizePixel = 0
MainFrame.Size = UDim2.new(0, 820, 0, 580)
MainFrame.Position = UDim2.new(0.5, -410, 0.5, -290)
MainFrame.ClipsDescendants = false

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 24)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = COLORS.Border
MainStroke.Thickness = 1
MainStroke.Transparency = 0.7
MainStroke.Parent = MainFrame

local ShadowOverlay = Instance.new("Frame")
ShadowOverlay.Parent = MainFrame
ShadowOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ShadowOverlay.BackgroundTransparency = 0.04
ShadowOverlay.BorderSizePixel = 0
ShadowOverlay.Size = UDim2.new(1, 0, 1, 0)
local ShadowCorner = Instance.new("UICorner")
ShadowCorner.CornerRadius = UDim.new(0, 24)
ShadowCorner.Parent = ShadowOverlay

-- ==================== HEADER ====================
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Parent = MainFrame
Header.BackgroundTransparency = 1
Header.Size = UDim2.new(1, -32, 0, 64)
Header.Position = UDim2.new(0, 16, 0, 16)

local DurianIcon = Instance.new("TextLabel")
DurianIcon.Parent = Header
DurianIcon.BackgroundTransparency = 1
DurianIcon.Size = UDim2.new(0, 48, 0, 48)
DurianIcon.Position = UDim2.new(0, 0, 0, 8)
DurianIcon.Font = Enum.Font.GothamBold
DurianIcon.Text = "🍈"
DurianIcon.TextColor3 = COLORS.PrimaryGreen
DurianIcon.TextSize = 36

local TitleGroup = Instance.new("Frame")
TitleGroup.Name = "TitleGroup"
TitleGroup.Parent = Header
TitleGroup.BackgroundTransparency = 1
TitleGroup.Size = UDim2.new(0, 200, 1, 0)
TitleGroup.Position = UDim2.new(0, 60, 0, 0)

local BrandName = Instance.new("TextLabel")
BrandName.Parent = TitleGroup
BrandName.BackgroundTransparency = 1
BrandName.Size = UDim2.new(1, 0, 0, 28)
BrandName.Position = UDim2.new(0, 0, 0, 6)
BrandName.Font = Enum.Font.GothamBold
BrandName.Text = "DurianHUB"
BrandName.TextColor3 = COLORS.PrimaryGreen
BrandName.TextSize = 22
BrandName.TextXAlignment = Enum.TextXAlignment.Left

local HubTag = Instance.new("TextLabel")
HubTag.Parent = BrandName
HubTag.BackgroundColor3 = COLORS.LightGold
HubTag.BackgroundTransparency = 0.3
HubTag.Size = UDim2.new(0, 52, 0, 20)
HubTag.Position = UDim2.new(0, 112, 0, 4)
HubTag.Font = Enum.Font.GothamBold
HubTag.Text = "HUB"
HubTag.TextColor3 = COLORS.PrimaryGreen
HubTag.TextSize = 13
local HubCorner = Instance.new("UICorner")
HubCorner.CornerRadius = UDim.new(0, 6)
HubCorner.Parent = HubTag

local Subtext = Instance.new("TextLabel")
Subtext.Parent = TitleGroup
Subtext.BackgroundTransparency = 1
Subtext.Size = UDim2.new(1, 0, 0, 18)
Subtext.Position = UDim2.new(0, 0, 0, 34)
Subtext.Font = Enum.Font.Gotham
Subtext.Text = "Community Server Finder"
Subtext.TextColor3 = COLORS.TextMuted
Subtext.TextSize = 12
Subtext.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Parent = Header
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.BackgroundTransparency = 0.8
CloseBtn.Size = UDim2.new(0, 38, 0, 38)
CloseBtn.Position = UDim2.new(1, -38, 0, 13)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = COLORS.TextDark
CloseBtn.TextSize = 18
CloseBtn.AutoButtonColor = false
local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 10)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 0, 0)
    }):Play()
    wait(0.3)
    ScreenGui:Destroy()
end)

-- ==================== TOOLBAR ====================
local Toolbar = Instance.new("Frame")
Toolbar.Name = "Toolbar"
Toolbar.Parent = MainFrame
Toolbar.BackgroundTransparency = 1
Toolbar.Size = UDim2.new(1, -32, 0, 44)
Toolbar.Position = UDim2.new(0, 16, 0, 88)

local SearchBox = Instance.new("TextBox")
SearchBox.Parent = Toolbar
SearchBox.BackgroundColor3 = COLORS.Cream
SearchBox.BackgroundTransparency = 0.6
SearchBox.Size = UDim2.new(0, 200, 1, 0)
SearchBox.Position = UDim2.new(0, 0, 0, 0)
SearchBox.Font = Enum.Font.Gotham
SearchBox.Text = ""
SearchBox.TextColor3 = COLORS.TextDark
SearchBox.TextSize = 14
SearchBox.PlaceholderText = "🔍 Filter servers..."
SearchBox.ClearTextOnFocus = false
local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0, 10)
SearchCorner.Parent = SearchBox
local SearchStroke = Instance.new("UIStroke")
SearchStroke.Color = COLORS.Border
SearchStroke.Thickness = 1
SearchStroke.Parent = SearchBox

local RegionFilter = Instance.new("TextBox")
RegionFilter.Parent = Toolbar
RegionFilter.BackgroundColor3 = COLORS.Cream
RegionFilter.BackgroundTransparency = 0.6
RegionFilter.Size = UDim2.new(0, 140, 1, 0)
RegionFilter.Position = UDim2.new(0, 212, 0, 0)
RegionFilter.Font = Enum.Font.Gotham
RegionFilter.Text = "All Regions"
RegionFilter.TextColor3 = COLORS.TextDark
RegionFilter.TextSize = 13
RegionFilter.ClearTextOnFocus = false
RegionFilter.PlaceholderText = "🌍 Region"
local RegionCorner = Instance.new("UICorner")
RegionCorner.CornerRadius = UDim.new(0, 10)
RegionCorner.Parent = RegionFilter
local RegionStroke = Instance.new("UIStroke")
RegionStroke.Color = COLORS.Border
RegionStroke.Thickness = 1
RegionStroke.Parent = RegionFilter

local regions = {"All Regions", "Americas", "Europe", "Asia-Pacific"}
local regionIndex = 1
RegionFilter.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local input = RegionFilter.Text:lower()
        for i, r in ipairs(regions) do
            if r:lower():find(input) then
                regionIndex = i
                RegionFilter.Text = r
                break
            end
        end
        refreshServers()
    end
end)
RegionFilter.MouseButton1Click:Connect(function()
    regionIndex = regionIndex % #regions + 1
    RegionFilter.Text = regions[regionIndex]
    refreshServers()
end)

local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Parent = Toolbar
RefreshBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
RefreshBtn.BackgroundTransparency = 0.8
RefreshBtn.Size = UDim2.new(0, 90, 1, 0)
RefreshBtn.Position = UDim2.new(0, 364, 0, 0)
RefreshBtn.Font = Enum.Font.GothamBold
RefreshBtn.Text = "↻ Refresh"
RefreshBtn.TextColor3 = COLORS.TextDark
RefreshBtn.TextSize = 13
local RefCorner = Instance.new("UICorner")
RefCorner.CornerRadius = UDim.new(0, 10)
RefCorner.Parent = RefreshBtn
local RefStroke = Instance.new("UIStroke")
RefStroke.Color = COLORS.Border
RefStroke.Thickness = 1
RefStroke.Parent = RefreshBtn

local AutoBtn = Instance.new("TextButton")
AutoBtn.Parent = Toolbar
AutoBtn.BackgroundColor3 = COLORS.Gold
AutoBtn.BackgroundTransparency = 0.2
AutoBtn.Size = UDim2.new(0, 100, 1, 0)
AutoBtn.Position = UDim2.new(0, 464, 0, 0)
AutoBtn.Font = Enum.Font.GothamBold
AutoBtn.Text = "⏱ Auto: ON"
AutoBtn.TextColor3 = COLORS.PrimaryGreen
AutoBtn.TextSize = 13
local AutoCorner = Instance.new("UICorner")
AutoCorner.CornerRadius = UDim.new(0, 10)
AutoCorner.Parent = AutoBtn
local AutoStroke = Instance.new("UIStroke")
AutoStroke.Color = COLORS.Gold
AutoStroke.Thickness = 1
AutoStroke.Parent = AutoBtn

local StatusBadge = Instance.new("Frame")
StatusBadge.Parent = Toolbar
StatusBadge.BackgroundColor3 = COLORS.Cream
StatusBadge.BackgroundTransparency = 0.7
StatusBadge.Size = UDim2.new(0, 160, 1, 0)
StatusBadge.Position = UDim2.new(1, -160, 0, 0)
local BadgeCorner = Instance.new("UICorner")
BadgeCorner.CornerRadius = UDim.new(0, 20)
BadgeCorner.Parent = StatusBadge
local BadgeStroke = Instance.new("UIStroke")
BadgeStroke.Color = COLORS.Border
BadgeStroke.Thickness = 1
BadgeStroke.Parent = StatusBadge

local StatusDot = Instance.new("Frame")
StatusDot.Parent = StatusBadge
StatusDot.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
StatusDot.Size = UDim2.new(0, 8, 0, 8)
StatusDot.Position = UDim2.new(0, 12, 0.5, -4)
local DotCorner = Instance.new("UICorner")
DotCorner.CornerRadius = UDim.new(1, 0)
DotCorner.Parent = StatusDot

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Parent = StatusBadge
StatusLabel.BackgroundTransparency = 1
StatusLabel.Size = UDim2.new(1, -24, 1, 0)
StatusLabel.Position = UDim2.new(0, 26, 0, 0)
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.Text = "Loading..."
StatusLabel.TextColor3 = COLORS.PrimaryGreen
StatusLabel.TextSize = 13
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

-- ==================== SERVER LIST ====================
local ListContainer = Instance.new("Frame")
ListContainer.Name = "ListContainer"
ListContainer.Parent = MainFrame
ListContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ListContainer.BackgroundTransparency = 0.9
ListContainer.Size = UDim2.new(1, -32, 1, -180)
ListContainer.Position = UDim2.new(0, 16, 0, 142)
local ListCorner = Instance.new("UICorner")
ListCorner.CornerRadius = UDim.new(0, 16)
ListCorner.Parent = ListContainer

local ServerScroll = Instance.new("ScrollingFrame")
ServerScroll.Parent = ListContainer
ServerScroll.BackgroundTransparency = 1
ServerScroll.Size = UDim2.new(1, 0, 1, 0)
ServerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ServerScroll.ScrollBarThickness = 6
ServerScroll.ScrollBarImageColor3 = COLORS.Border
ServerScroll.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right

local ListLayout = Instance.new("UIListLayout")
ListLayout.Parent = ServerScroll
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 8)

ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ServerScroll.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
end)

-- ==================== SERVER ENTRY TEMPLATE ====================
local Template = Instance.new("Frame")
Template.Name = "ServerTemplate"
Template.Parent = ServerScroll
Template.BackgroundColor3 = COLORS.CardBg
Template.Size = UDim2.new(1, 0, 0, 68)
Template.Visible = false
local TplCorner = Instance.new("UICorner")
TplCorner.CornerRadius = UDim.new(0, 14)
TplCorner.Parent = Template
local TplStroke = Instance.new("UIStroke")
TplStroke.Color = COLORS.Border
TplStroke.Thickness = 1
TplStroke.Parent = Template

local InfoArea = Instance.new("Frame")
InfoArea.Parent = Template
InfoArea.BackgroundTransparency = 1
InfoArea.Size = UDim2.new(0.75, 0, 1, 0)

local TitleRow = Instance.new("Frame")
TitleRow.Parent = InfoArea
TitleRow.BackgroundTransparency = 1
TitleRow.Size = UDim2.new(1, 0, 0, 28)

local ServerName = Instance.new("TextLabel")
ServerName.Parent = TitleRow
ServerName.BackgroundTransparency = 1
ServerName.Size = UDim2.new(0.6, 0, 1, 0)
ServerName.Font = Enum.Font.GothamBold
ServerName.Text = "Game Name"
ServerName.TextColor3 = COLORS.TextDark
ServerName.TextSize = 15
ServerName.TextXAlignment = Enum.TextXAlignment.Left

local PingTag = Instance.new("TextLabel")
PingTag.Parent = TitleRow
PingTag.BackgroundColor3 = COLORS.LightGold
PingTag.BackgroundTransparency = 0.5
PingTag.Size = UDim2.new(0, 48, 0, 18)
PingTag.Position = UDim2.new(0.62, 0, 0.5, -9)
PingTag.Font = Enum.Font.GothamBold
PingTag.Text = "12ms"
PingTag.TextColor3 = COLORS.PrimaryGreen
PingTag.TextSize = 11
local PingCorner = Instance.new("UICorner")
PingCorner.CornerRadius = UDim.new(0, 4)
PingCorner.Parent = PingTag

local MetaRow = Instance.new("Frame")
MetaRow.Parent = InfoArea
MetaRow.BackgroundTransparency = 1
MetaRow.Size = UDim.new(1, 0, 0, 24)
MetaRow.Position = UDim.new(0, 0, 0, 28)

local PlayerCount = Instance.new("TextLabel")
PlayerCount.Parent = MetaRow
PlayerCount.BackgroundTransparency = 1
PlayerCount.Size = UDim2.new(0.25, 0, 1, 0)
PlayerCount.Font = Enum.Font.Gotham
PlayerCount.Text = "👥 4/32"
PlayerCount.TextColor3 = COLORS.TextMuted
PlayerCount.TextSize = 13
PlayerCount.TextXAlignment = Enum.TextXAlignment.Left

local RegionLabel = Instance.new("TextLabel")
RegionLabel.Parent = MetaRow
RegionLabel.BackgroundTransparency = 1
RegionLabel.Size = UDim2.new(0.25, 0, 1, 0)
RegionLabel.Position = UDim2.new(0.28, 0, 0, 0)
RegionLabel.Font = Enum.Font.Gotham
RegionLabel.Text = "🌍 US-West"
RegionLabel.TextColor3 = COLORS.TextMuted
RegionLabel.TextSize = 13
RegionLabel.TextXAlignment = Enum.TextXAlignment.Left

local ServerID = Instance.new("TextLabel")
ServerID.Parent = MetaRow
ServerID.BackgroundColor3 = COLORS.Border
ServerID.BackgroundTransparency = 0.7
ServerID.Size = UDim2.new(0, 80, 0, 20)
ServerID.Position = UDim2.new(0.55, 0, 0.5, -10)
ServerID.Font = Enum.Font.Gotham
ServerID.Text = "#abc123"
ServerID.TextColor3 = COLORS.TextMuted
ServerID.TextSize = 12
local IDCorner = Instance.new("UICorner")
IDCorner.CornerRadius = UDim.new(0, 4)
IDCorner.Parent = ServerID

local JoinBtn = Instance.new("TextButton")
JoinBtn.Name = "JoinBtn"
JoinBtn.Parent = Template
JoinBtn.BackgroundColor3 = COLORS.PrimaryGreen
JoinBtn.Size = UDim2.new(0, 100, 0, 36)
JoinBtn.Position = UDim2.new(1, -110, 0.5, -18)
JoinBtn.Font = Enum.Font.GothamBold
JoinBtn.Text = "Join Server"
JoinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
JoinBtn.TextSize = 13
local JoinCorner = Instance.new("UICorner")
JoinCorner.CornerRadius = UDim.new(0, 9)
JoinCorner.Parent = JoinBtn

JoinBtn.MouseEnter:Connect(function()
    TweenService:Create(JoinBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.SecondaryGreen}):Play()
end)
JoinBtn.MouseLeave:Connect(function()
    TweenService:Create(JoinBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.PrimaryGreen}):Play()
end)

-- ==================== LOADING SPINNER ====================
local Spinner = Instance.new("ImageLabel")
Spinner.Parent = ListContainer
Spinner.BackgroundTransparency = 1
Spinner.Size = UDim2.new(0, 40, 0, 40)
Spinner.Position = UDim2.new(0.5, -20, 0.5, -20)
Spinner.Image = "rbxassetid://5108447180"
Spinner.ImageColor3 = COLORS.Gold
Spinner.Visible = false

spawn(function()
    while true do
        if Spinner.Visible then
            Spinner.Rotation = (Spinner.Rotation + 5) % 360
        end
        wait()
    end
end)

-- ==================== CORE FUNCTIONS ====================
local allServers = {}
local refreshCooldown = false

local function fetchServers(cursor)
    local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)
    if cursor then url = url .. "&cursor=" .. cursor end
    local success, response = pcall(function()
        return requestFunc({Url = url, Method = "GET"})
    end)
    if not success or not response or response.StatusCode ~= 200 then
        return nil, "Network error"
    end
    local decoded = HttpService:JSONDecode(response.Body)
    if not decoded or not decoded.data then
        return nil, "Invalid response"
    end
    return decoded, nil
end

local function applyFilters()
    local query = SearchBox.Text:lower()
    local regionText = RegionFilter.Text
    local regionFilter = regionText:lower()
    local selectedRegion = nil
    if regionFilter:find("americas") then selectedRegion = "US"
    elseif regionFilter:find("europe") then selectedRegion = "EU"
    elseif regionFilter:find("asia") then selectedRegion = "Asia"
    else selectedRegion = "all" end

    for _, child in ipairs(ServerScroll:GetChildren()) do
        if child ~= Template then
            child:Destroy()
        end
    end

    local count = 0
    table.sort(allServers, function(a, b)
        return (a.playing or 0) < (b.playing or 0)
    end)

    for _, server in ipairs(allServers) do
        if server.playing < server.maxPlayers then
            local region = server.region or ""
            local regionMatch = (selectedRegion == "all") or (region:find(selectedRegion) ~= nil)
            if regionMatch then
                local idStr = tostring(server.id):lower()
                local nameMatch = (gameName:lower():find(query) or idStr:find(query))
                if nameMatch then
                    local entry = Template:Clone()
                    entry.Visible = true
                    entry.Name = "ServerEntry_" .. server.id

                    local nameLabel = entry:FindFirstChild("InfoArea"):FindFirstChild("TitleRow"):FindFirstChild("ServerName")
                    nameLabel.Text = gameName

                    local pingTag = entry:FindFirstChild("InfoArea"):FindFirstChild("TitleRow"):FindFirstChild("PingTag")
                    local playerCount = server.playing or 0
                    local max = server.maxPlayers or 32
                    local fill = playerCount / max
                    if fill < 0.3 then pingTag.Text = "Low 🟢"
                    elseif fill < 0.6 then pingTag.Text = "Med 🟡"
                    else pingTag.Text = "High 🔴" end

                    local meta = entry:FindFirstChild("InfoArea"):FindFirstChild("MetaRow")
                    local playerLabel = meta:FindFirstChild("PlayerCount")
                    playerLabel.Text = string.format("👥 %d/%d", playerCount, max)

                    local regionLabel = meta:FindFirstChild("RegionLabel")
                    regionLabel.Text = "🌍 " .. (server.region or "Unknown")

                    local idLabel = meta:FindFirstChild("ServerID")
                    idLabel.Text = "#" .. tostring(server.id):sub(1, 6)

                    local joinBtn = entry:FindFirstChild("JoinBtn")
                    joinBtn.MouseButton1Click:Connect(function()
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                    end)

                    entry.Parent = ServerScroll
                    count = count + 1
                end
            end
        end
    end

    StatusLabel.Text = string.format("%d Server%s Online", count, count == 1 and "" or "s")
end

local function refreshServers()
    if refreshCooldown then return end
    refreshCooldown = true
    wait(0.5)
    refreshCooldown = false

    for _, child in ipairs(ServerScroll:GetChildren()) do
        if child ~= Template then
            child:Destroy()
        end
    end

    Spinner.Visible = true
    StatusLabel.Text = "Loading..."

    local servers = {}
    local cursor = nil
    local errorMsg = nil
    repeat
        local data, err = fetchServers(cursor)
        if not data then
            errorMsg = err or "Unknown error"
            break
        end
        for _, s in ipairs(data.data) do
            table.insert(servers, s)
        end
        cursor = data.nextPageCursor
    until not cursor

    Spinner.Visible = false

    if errorMsg then
        StatusLabel.Text = "⚠️ " .. errorMsg
        return
    end

    allServers = servers
    applyFilters()
end

-- ==================== EVENT CONNECTIONS ====================
SearchBox:GetPropertyChangedSignal("Text"):Connect(applyFilters)
RefreshBtn.MouseButton1Click:Connect(refreshServers)

local autoRefreshEnabled = true
local autoRefreshRunning = false

function startAutoRefresh()
    if autoRefreshRunning then return end
    autoRefreshRunning = true
    spawn(function()
        while autoRefreshEnabled do
            wait(15)
            if autoRefreshEnabled then
                refreshServers()
            end
        end
        autoRefreshRunning = false
    end)
end

AutoBtn.MouseButton1Click:Connect(function()
    autoRefreshEnabled = not autoRefreshEnabled
    if autoRefreshEnabled then
        AutoBtn.Text = "⏱ Auto: ON"
        AutoBtn.BackgroundColor3 = COLORS.Gold
        AutoBtn.BackgroundTransparency = 0.2
        AutoBtn.TextColor3 = COLORS.PrimaryGreen
        startAutoRefresh()
    else
        AutoBtn.Text = "⏱ Auto: OFF"
        AutoBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
        AutoBtn.BackgroundTransparency = 0.2
        AutoBtn.TextColor3 = Color3.fromRGB(200, 70, 70)
        -- The loop will stop because autoRefreshEnabled is false
    end
end)

-- ==================== DRAGGABLE ====================
local function makeDraggable(object)
    local dragging, dragInput, dragStart, startPos
    object.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = object.AbsolutePosition
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    object.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            object.Position = UDim2.new(0, startPos.X + delta.X, 0, startPos.Y + delta.Y)
        end
    end)
end

makeDraggable(MainFrame)

-- ==================== SHOW/HIDE TOGGLE (floating pill) ====================
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Parent = ScreenGui
ToggleBtn.BackgroundColor3 = COLORS.PrimaryGreen
ToggleBtn.Size = UDim2.new(0, 120, 0, 40)
ToggleBtn.Position = UDim2.new(0.5, -60, 1, -60)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Text = "Hide Panel"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 14
local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleBtn
local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(255, 255, 255)
ToggleStroke.Thickness = 1
ToggleStroke.Transparency = 0.3
ToggleStroke.Parent = ToggleBtn

local isHidden = false
ToggleBtn.MouseButton1Click:Connect(function()
    isHidden = not isHidden
    local targetPos = isHidden and UDim2.new(0.5, -60, 1.2, 0) or UDim2.new(0.5, -60, 1, -60)
    TweenService:Create(ToggleBtn, TweenInfo.new(0.3), {Position = targetPos}):Play()
    if isHidden then
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 0, 0)
        }):Play()
    else
        MainFrame.Size = UDim2.new(0, 820, 0, 580)
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            BackgroundTransparency = 0
        }):Play()
    end
end)

-- ==================== INITIAL LOAD ====================
refreshServers()
startAutoRefresh()
