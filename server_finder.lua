--═════════════════════════════════════════════════════════
--  💻 Server Finder v2 — fixed UI + minimize/maximize
--═════════════════════════════════════════════════════════

local HttpService        = game:GetService("HttpService")
local TweenService       = game:GetService("TweenService")
local TeleportService    = game:GetService("TeleportService")
local Players            = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService   = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

--// Multi-executor HTTP fallback
local function httpRequest(req)
    if syn and syn.request then return syn.request(req) end
    if http and http.request then return http.request(req) end
    if http_request then return http_request(req) end
    if fluxus and fluxus.request then return fluxus.request(req) end
    if request then return request(req) end
    local ok, body = pcall(function() return game:HttpGet(req.Url) end)
    if ok then return { Body = body } end
    return nil
end

local gameName = "Unknown Game"
pcall(function()
    gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name or gameName
end)

--// Instance helper
local function new(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    inst.Parent = parent
    return inst
end

--// Cleanup old copy
local old = LocalPlayer.PlayerGui:FindFirstChild("LowServerFinder")
if old then old:Destroy() end

--═══════════════ ROOT ═══════════════
local ScreenGui = new("ScreenGui", {
    Name           = "LowServerFinder",
    ResetOnSpawn   = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, LocalPlayer:WaitForChild("PlayerGui"))

--═══════════════ SIZE CONSTANTS ═══════════════
local TITLE_H     = 42
local STATUS_H    = 32
local NORMAL_SIZE = UDim2.new(0, 660, 0, 430)
local MAX_SIZE    = UDim2.new(1, -40, 1, -80)   -- near fullscreen
local CENTER      = UDim2.new(0.5, 0, 0.5, 0)

--═══════════════ MAIN FRAME (centered, proper proportions) ═══════════════
local MainFrame = new("Frame", {
    AnchorPoint      = Vector2.new(0.5, 0.5),
    Position         = CENTER,
    Size             = NORMAL_SIZE,
    BackgroundColor3 = Color3.fromRGB(38, 38, 44),
    BorderSizePixel  = 0,
    Active           = true,
}, ScreenGui)
new("UICorner",  { CornerRadius = UDim.new(0, 12) }, MainFrame)
new("UIStroke",  { Color = Color3.fromRGB(95, 95, 110), Thickness = 1.5 }, MainFrame)
new("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(55, 55, 62)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 28, 33)),
    }),
}, MainFrame)

--═══════════════ TITLE BAR (drag handle) ═══════════════
local TitleBar = new("Frame", {
    Size             = UDim2.new(1, 0, 0, TITLE_H),
    BackgroundColor3 = Color3.fromRGB(26, 26, 31),
    BorderSizePixel  = 0,
    Active           = true,
}, MainFrame)
new("UICorner", { CornerRadius = UDim.new(0, 12) }, TitleBar)
new("Frame", { -- square off bar's bottom corners
    Size             = UDim2.new(1, 0, 0.5, 0),
    Position         = UDim2.new(0, 0, 0.5, 0),
    BackgroundColor3 = Color3.fromRGB(26, 26, 31),
    BorderSizePixel  = 0,
}, TitleBar)

new("TextLabel", {
    Size             = UDim2.new(1, -150, 1, 0),
    Position         = UDim2.new(0, 14, 0, 0),
    BackgroundTransparency = 1,
    Font             = Enum.Font.GothamBold,
    Text             = "🖥️  Server Finder — " .. gameName,
    TextColor3       = Color3.fromRGB(255, 255, 255),
    TextSize         = 15,
    TextXAlignment   = Enum.TextXAlignment.Left,
    TextTruncate     = Enum.TextTruncate.AtEnd,
}, TitleBar)

--═══════════════ WINDOW BUTTONS (min / max / close) ═══════════════
local WinBtns = new("Frame", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position    = UDim2.new(1, -10, 0.5, 0),
    Size        = UDim2.new(0, 120, 1, -12),
    BackgroundTransparency = 1,
}, TitleBar)
new("UIListLayout", {
    FillDirection      = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment  = Enum.VerticalAlignment.Center,
    Padding            = UDim.new(0, 6),
}, WinBtns)

local function windowButton(text, order, baseColor)
    local btn = new("TextButton", {
        Size             = UDim2.new(0, 30, 0, 26),
        BackgroundColor3 = baseColor,
        Text             = text,
        TextColor3       = Color3.fromRGB(235, 235, 235),
        Font             = Enum.Font.GothamBold,
        TextSize         = 13,
        BorderSizePixel  = 0,
        AutoButtonColor  = false,
        LayoutOrder      = order,
    }, WinBtns)
    new("UICorner", { CornerRadius = UDim.new(0, 7) }, btn)
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = baseColor:Lerp(Color3.new(1, 1, 1), 0.2)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = baseColor
    end)
    return btn
end

local MinBtn   = windowButton("—", 1, Color3.fromRGB(70, 70, 80))
local MaxBtn   = windowButton("▢", 2, Color3.fromRGB(70, 70, 80))
local CloseBtn = windowButton("✕", 3, Color3.fromRGB(190, 55, 55))

--═══════════════ SERVER LIST ═══════════════
local ListFrame = new("ScrollingFrame", {
    Position             = UDim2.new(0, 12, 0, TITLE_H + 8),
    Size                 = UDim2.new(1, -24, 1, -(TITLE_H + STATUS_H + 26)),
    BackgroundColor3     = Color3.fromRGB(46, 46, 53),
    BorderSizePixel      = 0,
    ScrollBarThickness   = 5,
    ScrollBarImageColor3 = Color3.fromRGB(120, 120, 135),
    CanvasSize           = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize  = Enum.AutomaticSize.Y,
}, MainFrame)
new("UICorner", { CornerRadius = UDim.new(0, 10) }, ListFrame)
new("UIListLayout", {
    Padding   = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, ListFrame)
new("UIPadding", {
    PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
    PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 10),
}, ListFrame)

--═══════════════ STATUS BAR ═══════════════
local StatusBar = new("Frame", {
    AnchorPoint = Vector2.new(0, 1),
    Position    = UDim2.new(0, 12, 1, -10),
    Size        = UDim2.new(1, -24, 0, STATUS_H),
    BackgroundTransparency = 1,
}, MainFrame)

local StatusLabel = new("TextLabel", {
    Size             = UDim2.new(1, -120, 1, 0),
    BackgroundTransparency = 1,
    Font             = Enum.Font.Gotham,
    Text             = "⏳ Scanning servers...",
    TextColor3       = Color3.fromRGB(190, 190, 200),
    TextSize         = 13,
    TextXAlignment   = Enum.TextXAlignment.Left,
    TextTruncate     = Enum.TextTruncate.AtEnd,
}, StatusBar)

local RefreshBtn = new("TextButton", {
    AnchorPoint      = Vector2.new(1, 0.5),
    Position         = UDim2.new(1, 0, 0.5, 0),
    Size             = UDim2.new(0, 110, 0, 26),
    BackgroundColor3 = Color3.fromRGB(60, 130, 70),
    Font             = Enum.Font.GothamBold,
    Text             = "🔄 Refresh",
    TextColor3       = Color3.fromRGB(255, 255, 255),
    TextSize         = 13,
    BorderSizePixel  = 0,
}, StatusBar)
new("UICorner", { CornerRadius = UDim.new(0, 7) }, RefreshBtn)

--═══════════════ SIDE HIDE PILL ═══════════════
local HideShow = new("TextButton", {
    Position         = UDim2.new(0, 0, 0.5, -18),
    Size             = UDim2.new(0, 42, 0, 36),
    BackgroundColor3 = Color3.fromRGB(40, 160, 70),
    Font             = Enum.Font.GothamBold,
    Text             = "◀",
    TextColor3       = Color3.fromRGB(255, 255, 255),
    TextSize         = 14,
    BorderSizePixel  = 0,
}, ScreenGui)
new("UICorner", { CornerRadius = UDim.new(0, 8) }, HideShow)

HideShow.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    HideShow.Text = MainFrame.Visible and "◀" or "▶"
end)

--═══════════════ MIN / MAX / CLOSE LOGIC ═══════════════
local isMinimized, isMaximized = false, false
local savedSize, savedPos = NORMAL_SIZE, CENTER

local function tweenTo(size, pos)
    return TweenService:Create(MainFrame,
        TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = size, Position = pos }
    )
end

MinBtn.MouseButton1Click:Connect(function()
    if isMinimized then
        -- restore to whatever it was before (normal or maximized)
        isMinimized = false
        MinBtn.Text = "—"
        local size = isMaximized and MAX_SIZE or savedSize
        local pos  = isMaximized and CENTER   or savedPos
        local t = tweenTo(size, pos)
        t:Play()
        t.Completed:Connect(function()
            ListFrame.Visible = true
            StatusBar.Visible = true
        end)
    else
        isMinimized = true
        if not isMaximized then
            savedSize, savedPos = MainFrame.Size, MainFrame.Position
        end
        MinBtn.Text = "+"
        ListFrame.Visible = false
        StatusBar.Visible = false
        local cur = MainFrame.Size
        -- collapse to title bar only, keep same width
        tweenTo(UDim2.new(cur.X.Scale, cur.X.Offset, 0, TITLE_H), MainFrame.Position):Play()
    end
end)

MaxBtn.MouseButton1Click:Connect(function()
    if isMinimized then return end
    if not isMaximized then
        isMaximized = true
        savedSize, savedPos = MainFrame.Size, MainFrame.Position
        MaxBtn.Text = "❐"
        tweenTo(MAX_SIZE, CENTER):Play()
    else
        isMaximized = false
        MaxBtn.Text = "▢"
        tweenTo(savedSize, savedPos):Play()
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

--═══════════════ DRAGGING (title bar only, clean version) ═══════════════
local dragging = false
local dragStart, startPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        dragging  = true
        dragStart = input.Position
        startPos  = MainFrame.Position
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
       or input.UserInputType == Enum.UserInputType.Touch) then
        local delta  = input.Position - dragStart
        local newPos = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
        MainFrame.Position = newPos
        if not isMaximized then savedPos = newPos end
    end
end)

--═══════════════ SERVER FETCH + RENDER ═══════════════
local scanning = false

local function fetchServers(cursor)
    local url = string.format(
        "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100",
        game.PlaceId
    )
    if cursor then url = url .. "&cursor=" .. cursor end

    local res = httpRequest({ Url = url, Method = "GET" })
    if res and res.Body then
        local ok, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
        if ok then return data end
    end
end

local function createServerEntry(server, index)
    local isTop = index <= 3 -- highlight the emptiest 3
    local entry = new("Frame", {
        Size             = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = isTop and Color3.fromRGB(52, 66, 52) or Color3.fromRGB(60, 60, 68),
        BorderSizePixel  = 0,
        LayoutOrder      = index,
    }, ListFrame)
    new("UICorner", { CornerRadius = UDim.new(0, 8) }, entry)
    if isTop then
        new("UIStroke", {
            Color = Color3.fromRGB(90, 180, 95),
            Thickness = 1, Transparency = 0.4,
        }, entry)
    end

    new("TextLabel", {
        Position         = UDim2.new(0, 12, 0, 0),
        Size             = UDim2.new(1, -140, 1, 0),
        BackgroundTransparency = 1,
        Font             = Enum.Font.Gotham,
        Text             = string.format("#%d   👥 %d / %d   •   ID: %s…",
            index, server.playing, server.maxPlayers, string.sub(server.id, 1, 8)),
        TextColor3       = isTop and Color3.fromRGB(200, 255, 205) or Color3.fromRGB(235, 235, 240),
        TextSize         = 14,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextTruncate     = Enum.TextTruncate.AtEnd,
    }, entry)

    local joinBtn = new("TextButton", {
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -8, 0.5, 0),
        Size             = UDim2.new(0, 104, 0, 30),
        BackgroundColor3 = Color3.fromRGB(70, 90, 220),
        Font             = Enum.Font.GothamBold,
        Text             = "Join 🚀",
        TextColor3       = Color3.fromRGB(255, 255, 255),
        TextSize         = 14,
        BorderSizePixel  = 0,
    }, entry)
    new("UICorner", { CornerRadius = UDim.new(0, 7) }, joinBtn)

    joinBtn.MouseButton1Click:Connect(function()
        joinBtn.Text = "..."
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
        end)
        joinBtn.Text = "Join 🚀"
    end)
end

local function scan()
    if scanning then return end
    scanning = true
    StatusLabel.Text = "⏳ Scanning servers..."

    for _, child in ipairs(ListFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    task.spawn(function()
        local servers, cursor = {}, nil
        repeat
            local data = fetchServers(cursor)
            if data and data.data then
                for _, s in ipairs(data.data) do table.insert(servers, s) end
                StatusLabel.Text = ("⏳ Scanning... %d found"):format(#servers)
                cursor = data.nextPageCursor
            else
                cursor = nil
            end
        until not cursor

        table.sort(servers, function(a, b) return a.playing < b.playing end)

        local shown = 0
        for _, server in ipairs(servers) do
            if server.playing < server.maxPlayers then
                shown += 1
                createServerEntry(server, shown)
            end
        end

        if shown > 0 then
            StatusLabel.Text = string.format(
                "✅ %d servers scanned  •  emptiest visible: %d/%d  •  click 🔄 to rescan",
                #servers, servers[1].playing, servers[1].maxPlayers
            )
        else
            StatusLabel.Text = "❌ No joinable servers found"
        end
        scanning = false
    end)
end

RefreshBtn.MouseButton1Click:Connect(scan)

--═══════════════ BOOT ═══════════════
print("💻 Server Finder v2 loaded!")
scan()
