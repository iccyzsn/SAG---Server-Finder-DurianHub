-- 🌐 Server Finder – Improved UI
-- Reliable, lightweight, and visually polished

local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- HTTP request detection (same as original)
local requestFunc = nil
if syn and syn.request then
    requestFunc = syn.request
elseif http and http.request then
    requestFunc = http.request
elseif http_request then
    requestFunc = http_request
elseif fluxus and fluxus.request then
    requestFunc = fluxus.request
elseif request then
    requestFunc = request
else
    error("No HTTP request function found! 😢")
end

-- Get game name
local gameName = "Unknown"
pcall(function()
    local info = MarketplaceService:GetProductInfo(game.PlaceId)
    gameName = info.Name or gameName
end)

-- === UI COLOURS ===
local Colors = {
    BG = Color3.fromRGB(28, 28, 35),
    Frame = Color3.fromRGB(40, 40, 50),
    Accent = Color3.fromRGB(100, 180, 255),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(200, 200, 200),
    Card = Color3.fromRGB(55, 55, 68),
    CardHover = Color3.fromRGB(65, 65, 80),
    Join = Color3.fromRGB(75, 150, 255),
    JoinHover = Color3.fromRGB(100, 180, 255),
    Close = Color3.fromRGB(220, 60, 60),
    Toggle = Color3.fromRGB(60, 200, 100),
}

-- === CREATE GUI ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ServerFinder"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- === MAIN FRAME ===
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Colors.Frame
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -380, 0.5, -240)
MainFrame.Size = UDim2.new(0, 760, 0, 480)
MainFrame.ClipsDescendants = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(60, 60, 80)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Subtle gradient overlay
local MainGrad = Instance.new("UIGradient")
MainGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 45, 55)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 40))
})
MainGrad.Parent = MainFrame

-- === HEADER ===
local Header = Instance.new("Frame")
Header.Parent = MainFrame
Header.BackgroundTransparency = 1
Header.Size = UDim2.new(1, -20, 0, 50)
Header.Position = UDim2.new(0, 10, 0, 10)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Parent = Header
TitleLabel.BackgroundTransparency = 1
TitleLabel.Size = UDim2.new(0.7, 0, 1, 0)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "🚀 Server Finder"
TitleLabel.TextColor3 = Colors.Text
TitleLabel.TextSize = 22
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = Header
CloseBtn.BackgroundColor3 = Colors.Close
CloseBtn.Size = UDim2.new(0, 36, 0, 36)
CloseBtn.Position = UDim2.new(1, -36, 0, 7)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 18
CloseBtn.AutoButtonColor = false
local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(MainFrame, TweenInfo.new(0.3), {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 0, 0)
    }):Play()
    wait(0.3)
    ScreenGui:Destroy()
end)

-- === SERVER LIST ===
local ListContainer = Instance.new("Frame")
ListContainer.Parent = MainFrame
ListContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
ListContainer.BorderSizePixel = 0
ListContainer.Size = UDim2.new(1, -20, 1, -90)
ListContainer.Position = UDim2.new(0, 10, 0, 70)
local ListCorner = Instance.new("UICorner")
ListCorner.CornerRadius = UDim.new(0, 12)
ListCorner.Parent = ListContainer

local ServerScroll = Instance.new("ScrollingFrame")
ServerScroll.Parent = ListContainer
ServerScroll.BackgroundTransparency = 1
ServerScroll.Size = UDim2.new(1, 0, 1, 0)
ServerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ServerScroll.ScrollBarThickness = 5
ServerScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)

local ListLayout = Instance.new("UIListLayout")
ListLayout.Parent = ServerScroll
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 6)

ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ServerScroll.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
end)

-- === TEMPLATE FOR SERVER ENTRY ===
local Template = Instance.new("Frame")
Template.Name = "Template"
Template.Parent = ServerScroll
Template.BackgroundColor3 = Colors.Card
Template.Size = UDim2.new(1, -8, 0, 56)
Template.Visible = false
local TplCorner = Instance.new("UICorner")
TplCorner.CornerRadius = UDim.new(0, 10)
TplCorner.Parent = Template

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Parent = Template
InfoLabel.BackgroundTransparency = 1
InfoLabel.Size = UDim2.new(0.7, 0, 1, 0)
InfoLabel.Position = UDim2.new(0.04, 0, 0, 0)
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.Text = "Server Name\n👥 0/0  |  Region: --"
InfoLabel.TextColor3 = Colors.TextDim
InfoLabel.TextSize = 14
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.TextYAlignment = Enum.TextYAlignment.Center
InfoLabel.RichText = true

local JoinBtn = Instance.new("TextButton")
JoinBtn.Parent = Template
JoinBtn.BackgroundColor3 = Colors.Join
JoinBtn.Size = UDim2.new(0, 90, 0, 34)
JoinBtn.Position = UDim2.new(1, -100, 0.5, -17)
JoinBtn.Font = Enum.Font.GothamBold
JoinBtn.Text = "Join"
JoinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
JoinBtn.TextSize = 14
local JoinCorner = Instance.new("UICorner")
JoinCorner.CornerRadius = UDim.new(0, 8)
JoinCorner.Parent = JoinBtn

-- Hover effects
JoinBtn.MouseEnter:Connect(function()
    TweenService:Create(JoinBtn, TweenInfo.new(0.15), {BackgroundColor3 = Colors.JoinHover}):Play()
end)
JoinBtn.MouseLeave:Connect(function()
    TweenService:Create(JoinBtn, TweenInfo.new(0.15), {BackgroundColor3 = Colors.Join}):Play()
end)

Template.MouseEnter:Connect(function()
    TweenService:Create(Template, TweenInfo.new(0.1), {BackgroundColor3 = Colors.CardHover}):Play()
end)
Template.MouseLeave:Connect(function()
    TweenService:Create(Template, TweenInfo.new(0.1), {BackgroundColor3 = Colors.Card}):Play()
end)

-- === STATUS LABEL (loading / count) ===
local StatusBar = Instance.new("Frame")
StatusBar.Parent = MainFrame
StatusBar.BackgroundTransparency = 1
StatusBar.Size = UDim2.new(1, -20, 0, 30)
StatusBar.Position = UDim2.new(0, 10, 1, -40)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Parent = StatusBar
StatusLabel.BackgroundTransparency = 1
StatusLabel.Size = UDim2.new(1, 0, 1, 0)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Loading servers..."
StatusLabel.TextColor3 = Colors.TextDim
StatusLabel.TextSize = 14
StatusLabel.TextXAlignment = Enum.TextXAlignment.Center

-- === HIDE/SHOW TOGGLE ===
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Parent = ScreenGui
ToggleBtn.BackgroundColor3 = Colors.Toggle
ToggleBtn.Size = UDim2.new(0, 70, 0, 36)
ToggleBtn.Position = UDim2.new(0.01, 0, 0.45, -18)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Text = "Hide"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 14
local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 12)
ToggleCorner.Parent = ToggleBtn

local isHidden = false
ToggleBtn.MouseButton1Click:Connect(function()
    isHidden = not isHidden
    if isHidden then
        TweenService:Create(MainFrame, TweenInfo.new(0.3), {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 0, 0)
        }):Play()
        ToggleBtn.Text = "Show"
    else
        MainFrame.Size = UDim2.new(0, 760, 0, 480)
        TweenService:Create(MainFrame, TweenInfo.new(0.3), {
            BackgroundTransparency = 0
        }):Play()
        ToggleBtn.Text = "Hide"
    end
end)

-- === DRAGGABLE ===
local function MakeDraggable(guiObject)
    local dragging, dragInput, dragStart, startPos
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.AbsolutePosition
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(0, startPos.X + delta.X, 0, startPos.Y + delta.Y)
        end
    end)
end

MakeDraggable(MainFrame)
MakeDraggable(ToggleBtn)

-- === FETCH & DISPLAY SERVERS ===
local function createServerEntry(server)
    local clone = Template:Clone()
    clone.Visible = true
    clone.Name = "Server_" .. server.id

    local info = clone:FindFirstChildOfClass("TextLabel")
    if info then
        local region = server.region or "Unknown"
        info.Text = string.format("%s\n👥 %d/%d  |  🌍 %s", gameName, server.playing, server.maxPlayers, region)
    end

    local join = clone:FindFirstChildOfClass("TextButton")
    if join then
        join.MouseButton1Click:Connect(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
        end)
    end

    clone.Parent = ServerScroll
end

local function fetchServers(cursor)
    local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)
    if cursor then url = url .. "&cursor=" .. cursor end
    local response = requestFunc({Url = url, Method = "GET"})
    if response and response.Body then
        return HttpService:JSONDecode(response.Body)
    end
    return nil
end

spawn(function()
    StatusLabel.Text = "Fetching servers..."
    local servers = {}
    local cursor = nil
    repeat
        local data = fetchServers(cursor)
        if data and data.data then
            for _, s in ipairs(data.data) do
                table.insert(servers, s)
            end
            cursor = data.nextPageCursor
        else
            break
        end
    until not cursor

    if #servers == 0 then
        StatusLabel.Text = "No public servers found."
        return
    end

    -- Sort by lowest players first
    table.sort(servers, function(a, b) return a.playing < b.playing end)

    local count = 0
    for _, s in ipairs(servers) do
        if s.playing < s.maxPlayers then
            createServerEntry(s)
            count = count + 1
        end
    end

    StatusLabel.Text = string.format("%d server%s available", count, count == 1 and "" : "s")
end)
