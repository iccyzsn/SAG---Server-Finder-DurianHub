--[[
    🎯 SERVER HOPPER — GUI EDITION (NO PROXY / READY TO RUN)
    Uses game:HttpGet to hit games.roblox.com directly (executor HTTP).
    Auto-scans on load. Click a row to hop, or press ⚡ to jump to lowest.
--]]

-- ========== SERVICES ==========
local TeleportService = game:GetService("TeleportService")
local Players         = game:GetService("Players")
local UserInput       = game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local CoreGui         = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PLACE_ID    = game.PlaceId

-- ========== HTTP WRAPPER (NO PROXY) ==========
local function httpGet(url)
    -- Try executor HTTP first (bypasses roblox.com block)
    if typeof(game.HttpGet) == "function" then
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if ok and res and #res > 0 then return res end
    end
    -- Fallback: request() (common executor global)
    if typeof(request) == "function" then
        local ok, res = pcall(function() return request({ Url = url, Method = "GET" }).Body end)
        if ok and res then return res end
    end
    -- Fallback: syn.request
    if typeof(syn) == "table" and typeof(syn.request) == "function" then
        local ok, res = pcall(function() return syn.request({ Url = url, Method = "GET" }).Body end)
        if ok and res then return res end
    end
    -- Fallback: http_request
    if typeof(http_request) == "function" then
        local ok, res = pcall(function() return http_request({ Url = url, Method = "GET" }).Body end)
        if ok and res then return res end
    end
    -- Last resort: HttpService (may 403 on roblox.com, but try anyway)
    local ok, res = pcall(function()
        return game:GetService("HttpService"):GetAsync(url)
    end)
    if ok then return res end
    return nil
end

-- ========== CLEANUP OLD GUI ==========
local parent = (gethui and gethui()) or CoreGui
pcall(function()
    local old = parent:FindFirstChild("ServerHopperGUI")
    if old then old:Destroy() end
end)

-- ========== BUILD GUI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ServerHopperGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = parent

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 520, 0, 440)
Main.Position = UDim2.new(0.5, -260, 0.5, -220)
Main.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(70, 130, 255)
MainStroke.Thickness = 1.5
MainStroke.Parent = Main

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(28, 32, 45)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)

local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 14)
TitleFix.Position = UDim2.new(0, 0, 1, -14)
TitleFix.BackgroundColor3 = Color3.fromRGB(28, 32, 45)
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🎯  Server Hopper  •  Place: " .. PLACE_ID
Title.TextColor3 = Color3.fromRGB(240, 240, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -34, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -68, 0, 6)
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 60)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 14
MinBtn.Parent = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 8)

-- Buttons Bar
local BtnBar = Instance.new("Frame")
BtnBar.Size = UDim2.new(1, -24, 0, 36)
BtnBar.Position = UDim2.new(0, 12, 0, 50)
BtnBar.BackgroundTransparency = 1
BtnBar.Parent = Main

local function newBtn(text, color, posX, width)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, width, 1, 0)
    btn.Position = UDim2.new(0, posX, 0, 0)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.AutoButtonColor = true
    btn.Parent = BtnBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    return btn
end

local ScanBtn = newBtn("🔍  Scan",       Color3.fromRGB(60, 120, 240), 0,   160)
local HopBtn  = newBtn("⚡  Hop Lowest", Color3.fromRGB(40, 180, 100), 170, 160)
local CopyBtn = newBtn("📋  Copy JobID", Color3.fromRGB(120, 80, 200), 340, 150)

-- Status
local StatusLbl = Instance.new("TextLabel")
StatusLbl.Size = UDim2.new(1, -24, 0, 24)
StatusLbl.Position = UDim2.new(0, 12, 0, 94)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Text = "Status: ready"
StatusLbl.TextColor3 = Color3.fromRGB(180, 200, 220)
StatusLbl.Font = Enum.Font.Gotham
StatusLbl.TextSize = 12
StatusLbl.TextXAlignment = Enum.TextXAlignment.Left
StatusLbl.Parent = Main

-- Server List
local ListFrame = Instance.new("ScrollingFrame")
ListFrame.Size = UDim2.new(1, -24, 1, -180)
ListFrame.Position = UDim2.new(0, 12, 0, 124)
ListFrame.BackgroundColor3 = Color3.fromRGB(15, 17, 24)
ListFrame.BorderSizePixel = 0
ListFrame.ScrollBarThickness = 6
ListFrame.ScrollBarImageColor3 = Color3.fromRGB(70, 130, 255)
ListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ListFrame.Parent = Main
Instance.new("UICorner", ListFrame).CornerRadius = UDim.new(0, 8)

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 6)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = ListFrame

local ListPadding = Instance.new("UIPadding")
ListPadding.PaddingTop    = UDim.new(0, 8)
ListPadding.PaddingLeft   = UDim.new(0, 8)
ListPadding.PaddingRight  = UDim.new(0, 8)
ListPadding.PaddingBottom = UDim.new(0, 8)
ListPadding.Parent = ListFrame

-- ========== HELPERS ==========
local function setStatus(text, color)
    StatusLbl.Text = "Status: " .. text
    StatusLbl.TextColor3 = color or Color3.fromRGB(180, 200, 220)
end

local function clearList()
    for _, c in ipairs(ListFrame:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end
    end
end

local function createRow(index, info, isLowest)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, -6, 0, 40)
    row.BackgroundColor3 = isLowest and Color3.fromRGB(30, 70, 45)
                                       or  Color3.fromRGB(26, 30, 42)
    row.Text = ""
    row.AutoButtonColor = true
    row.LayoutOrder = index
    row.Parent = ListFrame
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local ratio = info.playing / math.max(info.maxPlayers, 1)
    local playerColor
    if ratio < 0.25 then playerColor = Color3.fromRGB(80, 220, 120)
    elseif ratio < 0.6 then playerColor = Color3.fromRGB(255, 200, 80)
    else playerColor = Color3.fromRGB(255, 90, 90) end

    local rank = Instance.new("TextLabel")
    rank.Size = UDim2.new(0, 40, 1, 0)
    rank.Position = UDim2.new(0, 6, 0, 0)
    rank.BackgroundTransparency = 1
    rank.Text = "#" .. index
    rank.TextColor3 = Color3.fromRGB(150, 170, 200)
    rank.Font = Enum.Font.GothamBold
    rank.TextSize = 12
    rank.Parent = row

    local idLbl = Instance.new("TextLabel")
    idLbl.Size = UDim2.new(1, -200, 0, 18)
    idLbl.Position = UDim2.new(0, 50, 0, 4)
    idLbl.BackgroundTransparency = 1
    idLbl.Text = info.id
    idLbl.TextColor3 = Color3.fromRGB(220, 230, 245)
    idLbl.Font = Enum.Font.Code
    idLbl.TextSize = 11
    idLbl.TextXAlignment = Enum.TextXAlignment.Left
    idLbl.TextTruncate = Enum.TextTruncate.AtEnd
    idLbl.Parent = row

    local pingLbl = Instance.new("TextLabel")
    pingLbl.Size = UDim2.new(1, -200, 0, 14)
    pingLbl.Position = UDim2.new(0, 50, 0, 22)
    pingLbl.BackgroundTransparency = 1
    pingLbl.Text = string.format("Ping: %sms  •  FPS: %s",
        tostring(info.ping or "?"), tostring(info.fps or "?"))
    pingLbl.TextColor3 = Color3.fromRGB(130, 150, 180)
    pingLbl.Font = Enum.Font.Gotham
    pingLbl.TextSize = 10
    pingLbl.TextXAlignment = Enum.TextXAlignment.Left
    pingLbl.Parent = row

    local countLbl = Instance.new("TextLabel")
    countLbl.Size = UDim2.new(0, 120, 1, 0)
    countLbl.Position = UDim2.new(1, -128, 0, 0)
    countLbl.BackgroundTransparency = 1
    countLbl.Text = string.format("%d / %d", info.playing, info.maxPlayers)
    countLbl.TextColor3 = playerColor
    countLbl.Font = Enum.Font.GothamBold
    countLbl.TextSize = 13
    countLbl.TextXAlignment = Enum.TextXAlignment.Right
    countLbl.Parent = row

    row.MouseButton1Click:Connect(function()
        setStatus("Hopping to " .. info.id .. "...", Color3.fromRGB(120, 180, 255))
        local ok, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(PLACE_ID, info.id, LocalPlayer)
        end)
        if not ok then
            setStatus("Teleport failed.", Color3.fromRGB(255, 100, 100))
            warn(err)
        end
    end)
end

-- ========== FETCH (direct, no proxy) ==========
local function fetchServers()
    local servers = {}
    local cursor  = ""
    local pages   = 0
    local endpoint = "https://games.roblox.com/v1/games/%s/servers/Public?limit=100&cursor=%s"

    while pages < 10 do
        local url = string.format(endpoint, PLACE_ID, cursor)
        local body = httpGet(url)
        if not body then return nil, "HTTP request failed" end

        local ok, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(body)
        end)
        if not ok or not data or not data.data then return nil, "Bad response" end

        for _, s in ipairs(data.data) do
            servers[s.id] = {
                id = s.id,
                playing = s.playing,
                maxPlayers = s.maxPlayers,
                fps = s.fps,
                ping = s.ping,
            }
        end

        cursor = data.nextPageCursor
        if not cursor or cursor == "" then break end
        pages = pages + 1
        task.wait(0.05)
    end

    return servers
end

-- ========== STATE ==========
local cachedSorted = nil

-- ========== SCAN ==========
local scanning = false
local function doScan()
    if scanning then return end
    scanning = true
    setStatus("Scanning servers...", Color3.fromRGB(255, 200, 80))
    clearList()
    cachedSorted = nil

    task.spawn(function()
        local servers, err = fetchServers()
        if not servers then
            setStatus("Scan failed: " .. tostring(err), Color3.fromRGB(255, 100, 100))
            scanning = false
            return
        end

        local arr = {}
        for _, v in pairs(servers) do table.insert(arr, v) end
        table.sort(arr, function(a, b) return a.playing < b.playing end)

        if #arr == 0 then
            setStatus("No servers found.", Color3.fromRGB(255, 100, 100))
            scanning = false
            return
        end

        cachedSorted = arr

        local lowestId = nil
        for _, s in ipairs(arr) do
            if s.id ~= game.JobId and s.playing < s.maxPlayers then
                lowestId = s.id
                break
            end
        end

        for i, info in ipairs(arr) do
            createRow(i, info, info.id == lowestId)
            if i % 20 == 0 then task.wait() end
        end

        ListFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 16)

        local lowestPlayers = "n/a"
        for _, s in ipairs(arr) do
            if s.id == lowestId then lowestPlayers = s.playing .. " players" break end
        end

        setStatus(string.format("Found %d servers  •  Lowest: %s", #arr, lowestPlayers),
            Color3.fromRGB(120, 220, 160))
        scanning = false
    end)
end

ScanBtn.MouseButton1Click:Connect(doScan)

-- ========== HOP ==========
HopBtn.MouseButton1Click:Connect(function()
    if not cachedSorted then
        setStatus("Scan first!", Color3.fromRGB(255, 180, 80))
        return
    end

    local target
    for _, s in ipairs(cachedSorted) do
        if s.id ~= game.JobId and s.playing < s.maxPlayers then
            target = s
            break
        end
    end

    if not target then
        setStatus("No joinable server with free slots.", Color3.fromRGB(255, 100, 100))
        return
    end

    setStatus(string.format("Hopping to %s (%d players)...", target.id, target.playing),
        Color3.fromRGB(120, 180, 255))

    local ok, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(PLACE_ID, target.id, LocalPlayer)
    end)
    if not ok then
        local ok2, err2 = pcall(function()
            local opts = Instance.new("TeleportOptions")
            opts.ServerInstanceId = target.id
            TeleportService:TeleportAsync(PLACE_ID, { LocalPlayer }, opts)
        end)
        if not ok2 then
            setStatus("Teleport failed.", Color3.fromRGB(255, 100, 100))
            warn(err, err2)
        end
    end
end)

-- ========== COPY ==========
CopyBtn.MouseButton1Click:Connect(function()
    local text = (cachedSorted and cachedSorted[1] and cachedSorted[1].id) or game.JobId
    local ok = pcall(function()
        if setclipboard then setclipboard(text)
        elseif toclipboard then toclipboard(text)
        else error("no clipboard") end
    end)
    if ok then
        setStatus("Copied: " .. text, Color3.fromRGB(120, 220, 160))
    else
        setStatus("Clipboard not supported.", Color3.fromRGB(255, 100, 100))
    end
end)

-- ========== MIN / CLOSE ==========
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    local target = minimized and UDim2.new(0, 520, 0, 40)
                             or  UDim2.new(0, 520, 0, 440)
    TweenService:Create(Main, TweenInfo.new(0.22, Enum.EasingStyle.Quad), { Size = target }):Play()
    MinBtn.Text = minimized and "+" or "—"
end)

CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- ========== DRAG ==========
do
    local dragging, dragStart, startPos
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInput.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ========== AUTO RUN ==========
setStatus("Loading...", Color3.fromRGB(180, 200, 220))
task.spawn(function()
    task.wait(0.3)
    doScan()
end)
