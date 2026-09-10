--// Services
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

--// Config
local MAX_PAGES = 3
local MAX_PLAYERS_FILTER = math.huge -- Change to filter servers above X players

--// Prevent duplicate GUI
if CoreGui:FindFirstChild("EmptyServerFinder") then
    CoreGui:FindFirstChild("EmptyServerFinder"):Destroy()
end

--// Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EmptyServerFinder"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

--// Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 400)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(80, 80, 120)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

--// Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local TitleFixCorner = Instance.new("Frame")
TitleFixCorner.Size = UDim2.new(1, 0, 0, 15)
TitleFixCorner.Position = UDim2.new(0, 0, 1, -15)
TitleFixCorner.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
TitleFixCorner.BorderSizePixel = 0
TitleFixCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🎯 Empty Server Finder"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

--// Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

--// Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -70, 0, 5)
MinBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 14
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Parent = TitleBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinBtn

--// Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -30, 0, 50)
StatusLabel.Position = UDim2.new(0, 15, 0, 50)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Ready to search..."
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
StatusLabel.TextSize = 13
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextWrapped = true
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextYAlignment = Enum.TextYAlignment.Top
StatusLabel.Parent = MainFrame

--// Info Section
local InfoFrame = Instance.new("Frame")
InfoFrame.Size = UDim2.new(1, -30, 0, 90)
InfoFrame.Position = UDim2.new(0, 15, 0, 110)
InfoFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
InfoFrame.BorderSizePixel = 0
InfoFrame.Parent = MainFrame

local InfoCorner = Instance.new("UICorner")
InfoCorner.CornerRadius = UDim.new(0, 8)
InfoCorner.Parent = InfoFrame

local InfoLayout = Instance.new("UIListLayout")
InfoLayout.Padding = UDim.new(0, 8)
InfoLayout.SortOrder = Enum.SortOrder.LayoutOrder
InfoLayout.Parent = InfoFrame

local InfoPadding = Instance.new("UIPadding")
InfoPadding.PaddingTop = UDim.new(0, 10)
InfoPadding.PaddingLeft = UDim.new(0, 12)
InfoPadding.PaddingRight = UDim.new(0, 12)
InfoPadding.Parent = InfoFrame

--// Place ID Display
local PlaceIdLabel = Instance.new("TextLabel")
PlaceIdLabel.Size = UDim2.new(1, 0, 0, 20)
PlaceIdLabel.BackgroundTransparency = 1
PlaceIdLabel.Text = "📍 Place ID: " .. PlaceId
PlaceIdLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
PlaceIdLabel.TextSize = 12
PlaceIdLabel.Font = Enum.Font.Gotham
PlaceIdLabel.TextXAlignment = Enum.TextXAlignment.Left
PlaceIdLabel.LayoutOrder = 1
PlaceIdLabel.Parent = InfoFrame

--// Current Players Display
local CurrentPlayersLabel = Instance.new("TextLabel")
CurrentPlayersLabel.Size = UDim2.new(1, 0, 0, 20)
CurrentPlayersLabel.BackgroundTransparency = 1
CurrentPlayersLabel.Text = "👥 Current Server: " .. #Players:GetPlayers() .. " players"
CurrentPlayersLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
CurrentPlayersLabel.TextSize = 12
CurrentPlayersLabel.Font = Enum.Font.Gotham
CurrentPlayersLabel.TextXAlignment = Enum.TextXAlignment.Left
CurrentPlayersLabel.LayoutOrder = 2
CurrentPlayersLabel.Parent = InfoFrame

--// Servers Scanned Display
local ScannedLabel = Instance.new("TextLabel")
ScannedLabel.Size = UDim2.new(1, 0, 0, 20)
ScannedLabel.BackgroundTransparency = 1
ScannedLabel.Text = "🔍 Servers Found: 0"
ScannedLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
ScannedLabel.TextSize = 12
ScannedLabel.Font = Enum.Font.Gotham
ScannedLabel.TextXAlignment = Enum.TextXAlignment.Left
ScannedLabel.LayoutOrder = 3
ScannedLabel.Parent = InfoFrame

--// Best Server Info
local BestFrame = Instance.new("Frame")
BestFrame.Size = UDim2.new(1, -30, 0, 80)
BestFrame.Position = UDim2.new(0, 15, 0, 210)
BestFrame.BackgroundColor3 = Color3.fromRGB(25, 35, 30)
BestFrame.BorderSizePixel = 0
BestFrame.Visible = false
BestFrame.Parent = MainFrame

local BestCorner = Instance.new("UICorner")
BestCorner.CornerRadius = UDim.new(0, 8)
BestCorner.Parent = BestFrame

local BestStroke = Instance.new("UIStroke")
BestStroke.Color = Color3.fromRGB(60, 180, 100)
BestStroke.Thickness = 1
BestStroke.Transparency = 0.5
BestStroke.Parent = BestFrame

local BestTitle = Instance.new("TextLabel")
BestTitle.Size = UDim2.new(1, -20, 0, 20)
BestTitle.Position = UDim2.new(0, 10, 0, 8)
BestTitle.BackgroundTransparency = 1
BestTitle.Text = "✅ Best Server Found"
BestTitle.TextColor3 = Color3.fromRGB(100, 255, 150)
BestTitle.TextSize = 13
BestTitle.Font = Enum.Font.GothamBold
BestTitle.TextXAlignment = Enum.TextXAlignment.Left
BestTitle.Parent = BestFrame

local BestInfo = Instance.new("TextLabel")
BestInfo.Size = UDim2.new(1, -20, 0, 45)
BestInfo.Position = UDim2.new(0, 10, 0, 30)
BestInfo.BackgroundTransparency = 1
BestInfo.Text = ""
BestInfo.TextColor3 = Color3.fromRGB(180, 255, 200)
BestInfo.TextSize = 12
BestInfo.Font = Enum.Font.Gotham
BestInfo.TextWrapped = true
BestInfo.TextXAlignment = Enum.TextXAlignment.Left
BestInfo.TextYAlignment = Enum.TextYAlignment.Top
BestInfo.Parent = BestFrame

--// Search Button
local SearchBtn = Instance.new("TextButton")
SearchBtn.Size = UDim2.new(1, -30, 0, 42)
SearchBtn.Position = UDim2.new(0, 15, 0, 305)
SearchBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
SearchBtn.Text = "🔍 Find Empty Server"
SearchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBtn.TextSize = 14
SearchBtn.Font = Enum.Font.GothamBold
SearchBtn.Parent = MainFrame

local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0, 8)
SearchCorner.Parent = SearchBtn

--// Teleport Button
local TeleportBtn = Instance.new("TextButton")
TeleportBtn.Size = UDim2.new(1, -30, 0, 42)
TeleportBtn.Position = UDim2.new(0, 15, 0, 350)
TeleportBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
TeleportBtn.Text = "🚀 Teleport Now"
TeleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TeleportBtn.TextSize = 14
TeleportBtn.Font = Enum.Font.GothamBold
TeleportBtn.Visible = false
TeleportBtn.Parent = MainFrame

local TeleportCorner = Instance.new("UICorner")
TeleportCorner.CornerRadius = UDim.new(0, 8)
TeleportCorner.Parent = TeleportBtn

--// Reopen Button (when minimized)
local ReopenBtn = Instance.new("TextButton")
ReopenBtn.Size = UDim2.new(0, 45, 0, 45)
ReopenBtn.Position = UDim2.new(0, 10, 0.5, -22)
ReopenBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
ReopenBtn.Text = "🎯"
ReopenBtn.TextSize = 20
ReopenBtn.Font = Enum.Font.GothamBold
ReopenBtn.Visible = false
ReopenBtn.Parent = ScreenGui

local ReopenCorner = Instance.new("UICorner")
ReopenCorner.CornerRadius = UDim.new(0, 8)
ReopenCorner.Parent = ReopenBtn

--// Variables
local bestServerFound = nil
local isSearching = false

--// Functions
local function updateStatus(text, color)
    StatusLabel.Text = text
    StatusLabel.TextColor3 = color or Color3.fromRGB(150, 150, 170)
end

local function getServers(cursor)
    local url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?limit=100"
    if cursor then
        url = url .. "&cursor=" .. cursor
    end

    local success, response = pcall(function()
        return game:HttpGetAsync(url)
    end)

    if not success then return nil, nil end

    local data = HttpService:JSONDecode(response)
    return data.data, data.nextPageCursor
end

local function findEmptyServer()
    isSearching = true
    bestServerFound = nil
    BestFrame.Visible = false
    TeleportBtn.Visible = false

    SearchBtn.Text = "⏳ Searching..."
    SearchBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    SearchBtn.AutoButtonColor = false

    local allServers = {}
    local cursor = nil
    local pages = 0

    repeat
        updateStatus("📡 Fetching page " .. (pages + 1) .. "...", Color3.fromRGB(100, 200, 255))
        local servers, nextCursor = getServers(cursor)

        if not servers then break end

        for _, server in ipairs(servers) do
            table.insert(allServers, server)
        end

        ScannedLabel.Text = "🔍 Servers Found: " .. #allServers
        cursor = nextCursor
        pages += 1
        task.wait(0.1)
    until not cursor or pages >= MAX_PAGES

    -- Find best server
    local lowest = math.huge
    local currentPlaying = #Players:GetPlayers()

    for _, server in ipairs(allServers) do
        if server.playing < server.maxPlayers 
           and server.playing < lowest 
           and server.playing < MAX_PLAYERS_FILTER then
            lowest = server.playing
            bestServerFound = server
        end
    end

    SearchBtn.Text = "🔍 Find Empty Server"
    SearchBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
    SearchBtn.AutoButtonColor = true
    isSearching = false

    if bestServerFound then
        local s = bestServerFound
        local isCurrent = (s.playing == currentPlaying and s.id == game.JobId)

        BestInfo.Text = string.format(
            "Players: %d/%d\nServer ID: %s",
            s.playing, s.maxPlayers,
            s.id:sub(1, 20) .. "..."
        )
        BestFrame.Visible = true
        TeleportBtn.Visible = true

        updateStatus("✅ Found! " .. s.playing .. " players (lowest)", Color3.fromRGB(100, 255, 150))
    else
        updateStatus("❌ No available servers found.", Color3.fromRGB(255, 100, 100))
    end
end

local function teleport()
    if not bestServerFound then return end

    local s = bestServerFound
    updateStatus("🚀 Teleporting to server...", Color3.fromRGB(255, 200, 100))

    TeleportBtn.Text = "⏳ Teleporting..."
    TeleportBtn.AutoButtonColor = false

    task.wait(0.5)

    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(PlaceId, s.id, LocalPlayer)
    end)

    if not success then
        updateStatus("❌ Teleport failed: " .. tostring(err), Color3.fromRGB(255, 100, 100))
        TeleportBtn.Text = "🚀 Teleport Now"
        TeleportBtn.AutoButtonColor = true
    end
end

--// Button Events
SearchBtn.MouseButton1Click:Connect(function()
    if not isSearching then
        task.spawn(findEmptyServer)
    end
end)

TeleportBtn.MouseButton1Click:Connect(teleport)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    ReopenBtn.Visible = true
end)

ReopenBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    ReopenBtn.Visible = false
end)

--// Hover Effects
local function addHover(btn, normalColor, hoverColor)
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = hoverColor
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = normalColor
    end)
end

addHover(SearchBtn, Color3.fromRGB(50, 100, 200), Color3.fromRGB(70, 120, 220))
addHover(TeleportBtn, Color3.fromRGB(50, 180, 80), Color3.fromRGB(70, 200, 100))
addHover(CloseBtn, Color3.fromRGB(200, 50, 50), Color3.fromRGB(230, 70, 70))
addHover(MinBtn, Color3.fromRGB(80, 80, 100), Color3.fromRGB(100, 100, 120))
addHover(ReopenBtn, Color3.fromRGB(50, 50, 80), Color3.fromRGB(70, 70, 100))

print("✅ Empty Server Finder GUI loaded!")
