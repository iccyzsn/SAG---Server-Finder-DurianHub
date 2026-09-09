local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- 1. HTTP REQUEST DETECTION
-- ==========================================
local requestFunc = syn and syn.request
    or http and http.request
    or http_request
    or fluxus and fluxus.request
    or request

if not requestFunc then
    error("No supported HTTP request function found! Please use a supported executor. 😢")
end

-- ==========================================
-- 2. UI HELPER FUNCTION (HTML-like declarative style)
-- ==========================================
local function New(class, properties, children)
    local obj = Instance.new(class)
    for prop, val in pairs(properties or {}) do
        obj[prop] = val
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = obj
        end
    end
    return obj
end

-- ==========================================
-- 3. COLOR PALETTE (Modern Dark Theme)
-- ==========================================
local Colors = {
    Background = Color3.fromRGB(30, 30, 35),
    Surface = Color3.fromRGB(45, 45, 55),
    SurfaceHover = Color3.fromRGB(55, 55, 65),
    Accent = Color3.fromRGB(99, 110, 250),      -- Indigo
    AccentHover = Color3.fromRGB(120, 130, 255),
    Success = Color3.fromRGB(34, 197, 94),       -- Green
    SuccessHover = Color3.fromRGB(50, 210, 110),
    Danger = Color3.fromRGB(239, 68, 68),        -- Red
    DangerHover = Color3.fromRGB(250, 90, 90),
    Text = Color3.fromRGB(220, 220, 230),
    TextMuted = Color3.fromRGB(160, 160, 170),
    Stroke = Color3.fromRGB(255, 255, 255, 0.08)
}

-- ==========================================
-- 4. GAME INFO
-- ==========================================
local gameName = "Unknown Game"
pcall(function()
    local info = MarketplaceService:GetProductInfo(game.PlaceId)
    gameName = info.Name or gameName
end)

-- ==========================================
-- 5. BUILD UI
-- ==========================================
local LowServerFinder = New("ScreenGui", {
    Name = "LowServerFinder",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, {
    New("Frame", { -- Main Frame
        Name = "MainFrame",
        BackgroundColor3 = Colors.Background,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, -375, 0.5, -225), -- Centered (750x450)
        Size = UDim2.new(0, 750, 0, 450),
    }, {
        New("UICorner", { CornerRadius = UDim.new(0, 16) }),
        New("UIStroke", { Thickness = 1, Color = Colors.Stroke }),
        New("UIGradient", { 
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 40)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 30))
            }) 
        }),
        
        -- Title Bar (Draggable Area)
        New("Frame", {
            Name = "TitleBar",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 45),
        }, {
            New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 20, 0, 0),
                Size = UDim2.new(1, -60, 1, 0),
                Font = Enum.Font.BuilderSans,
                FontWeight = Enum.FontWeight.Bold,
                Text = "🖥️  Low Server Finder",
                TextColor3 = Colors.Text,
                TextSize = 18,
                TextXAlignment = Enum.TextXAlignment.Left,
            }),
            New("TextButton", { -- Close Button
                Name = "CloseBtn",
                BackgroundColor3 = Colors.Danger,
                BorderSizePixel = 0,
                Position = UDim2.new(1, -55, 0, 8),
                Size = UDim2.new(0, 36, 0, 30),
                Text = "✕",
                Font = Enum.Font.BuilderSans,
                FontWeight = Enum.FontWeight.Bold,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 16,
            }, {
                New("UICorner", { CornerRadius = UDim.new(0, 8) }),
            }),
        }),

        -- Server List
        New("ScrollingFrame", {
            Name = "ServerListFrame",
            Active = true,
            BackgroundColor3 = Colors.Surface,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 15, 0, 55),
            Size = UDim2.new(1, -30, 1, -70),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 6,
            ScrollBarImageColor3 = Colors.Accent,
            BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
        }, {
            New("UICorner", { CornerRadius = UDim.new(0, 12) }),
            New("UIListLayout", { 
                SortOrder = Enum.SortOrder.LayoutOrder, 
                Padding = UDim.new(0, 8) 
            }),
            New("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
            
            -- Loading Label
            New("TextLabel", {
                Name = "LoadingLabel",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 40),
                Font = Enum.Font.BuilderSans,
                Text = "🔍 Searching for low population servers...",
                TextColor3 = Colors.TextMuted,
                TextSize = 16,
            }),

            -- Server Template (Hidden)
            New("Frame", {
                Name = "ServerTemplate",
                BackgroundColor3 = Colors.Background,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 50),
                Visible = false,
            }, {
                New("UICorner", { CornerRadius = UDim.new(0, 10) }),
                New("UIStroke", { Name = "HoverStroke", Thickness = 1, Color = Colors.Stroke, Transparency = 1 }),
                
                New("TextLabel", {
                    Name = "ServerInfo",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 16, 0, 0),
                    Size = UDim2.new(1, -140, 1, 0),
                    Font = Enum.Font.BuilderSans,
                    Text = "Server ID: N/A | Players: 0 / 0",
                    TextColor3 = Colors.Text,
                    TextSize = 15,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }),
                
                New("TextButton", {
                    Name = "JoinBtn",
                    BackgroundColor3 = Colors.Success,
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -110, 0, 8),
                    Size = UDim2.new(0, 90, 0, 34),
                    Text = "Join 🚀",
                    Font = Enum.Font.BuilderSans,
                    FontWeight = Enum.FontWeight.Bold,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 15,
                }, {
                    New("UICorner", { CornerRadius = UDim.new(0, 8) }),
                })
            })
        }),
    }),
    
    -- Hide/Show Toggle Button (Outside Main Frame)
    New("TextButton", {
        Name = "HideShowBtn",
        BackgroundColor3 = Colors.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 15, 0.5, -25),
        Size = UDim2.new(0, 40, 0, 50),
        Text = "<",
        Font = Enum.Font.BuilderSans,
        FontWeight = Enum.FontWeight.Bold,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 20,
    }, {
        New("UICorner", { CornerRadius = UDim.new(0, 10) }),
        New("UIStroke", { Thickness = 1, Color = Colors.Stroke }),
    })
})

LowServerFinder.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- ==========================================
-- 6. INTERACTIVITY & ANIMATIONS
-- ==========================================
local MainFrame = LowServerFinder.MainFrame
local TitleBar = MainFrame.TitleBar
local CloseBtn = TitleBar.CloseBtn
local ServerListFrame = MainFrame.ServerListFrame
local LoadingLabel = ServerListFrame.LoadingLabel
local ServerTemplate = ServerListFrame.ServerTemplate
local HideShowBtn = LowServerFinder.HideShowBtn

-- Hover Effect Helper
local function AddHoverEffect(button, defaultColor, hoverColor)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = hoverColor
        }):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = defaultColor
        }):Play()
    end)
end

AddHoverEffect(CloseBtn, Colors.Danger, Colors.DangerHover)
AddHoverEffect(HideShowBtn, Colors.Accent, Colors.AccentHover)

-- Improved Dragging (Only via TitleBar)
local function MakeDraggable(dragFrame, targetFrame)
    local dragging, dragStart, startPos
    dragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = targetFrame.Position
        end
    end)
    dragFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            targetFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

MakeDraggable(TitleBar, MainFrame)
MakeDraggable(HideShowBtn, HideShowBtn)

-- Hide/Show Logic
local isHidden = false
HideShowBtn.MouseButton1Click:Connect(function()
    isHidden = not isHidden
    if isHidden then
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1,
            Position = MainFrame.Position + UDim2.new(0, -20, 0, 0)
        }):Play()
        MainFrame.Visible = false
        HideShowBtn.Text = ">"
    else
        MainFrame.Visible = true
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0,
            Position = MainFrame.Position + UDim2.new(0, 20, 0, 0)
        }):Play()
        HideShowBtn.Text = "<"
    end
end)

-- Close Logic
CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        BackgroundTransparency = 1,
        Position = MainFrame.Position + UDim2.new(0, 0, 0, 20)
    }):Play()
    task.delay(0.25, function()
        LowServerFinder:Destroy()
    end)
end)

-- Dynamic Canvas Size
ServerListFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ServerListFrame.CanvasSize = UDim2.new(0, 0, 0, ServerListFrame.UIListLayout.AbsoluteContentSize.Y + 16)
end)

-- ==========================================
-- 7. SERVER FETCHING LOGIC
-- ==========================================
local function createServerEntry(serverData)
    local clone = ServerTemplate:Clone()
    clone.Name = "Server_" .. serverData.id
    clone.Visible = true
    clone.Parent = ServerListFrame

    local serverInfoLabel = clone.ServerInfo
    serverInfoLabel.Text = string.format("🆔 %s  |  👥 %d / %d Players", 
        tostring(serverData.id):sub(1, 20) .. "...", serverData.playing, serverData.maxPlayers)

    local joinButton = clone.JoinBtn
    AddHoverEffect(joinButton, Colors.Success, Colors.SuccessHover)
    
    -- Hover stroke effect for the whole card
    clone.MouseEnter:Connect(function()
        TweenService:Create(clone.HoverStroke, TweenInfo.new(0.15), { Transparency = 0, Color = Colors.Accent }):Play()
        TweenService:Create(clone, TweenInfo.new(0.15), { BackgroundColor3 = Colors.SurfaceHover }):Play()
    end)
    clone.MouseLeave:Connect(function()
        TweenService:Create(clone.HoverStroke, TweenInfo.new(0.15), { Transparency = 1 }):Play()
        TweenService:Create(clone, TweenInfo.new(0.15), { BackgroundColor3 = Colors.Background }):Play()
    end)

    joinButton.MouseButton1Click:Connect(function()
        joinButton.Text = "Joining..."
        joinButton.Interactable = false
        local success, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, serverData.id, LocalPlayer)
        end)
        if not success then
            joinButton.Text = "Failed"
            joinButton.BackgroundColor3 = Colors.Danger
            task.wait(2)
            joinButton.Text = "Join 🚀"
            joinButton.BackgroundColor3 = Colors.Success
            joinButton.Interactable = true
        end
    end)
end

task.spawn(function()
    local servers = {}
    local cursor = nil
    local maxPages = 5 -- Prevent infinite loops or massive lag
    
    for i = 1, maxPages do
        local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)
        if cursor then url = url .. "&cursor=" .. cursor end

        local success, response = pcall(function()
            return requestFunc({ Url = url, Method = "GET" })
        end)

        if success and response and response.Body then
            local data = HttpService:JSONDecode(response.Body)
            if data and data.data then
                for _, server in ipairs(data.data) do
                    if server.playing < server.maxPlayers then
                        table.insert(servers, server)
                    end
                end
                cursor = data.nextPageCursor
                if not cursor then break end
            else
                break
            end
        else
            warn("Failed to fetch servers:", response)
            break
        end
    end

    -- Sort by lowest player count
    table.sort(servers, function(a, b)
        return a.playing < b.playing
    end)

    LoadingLabel:Destroy()

    if #servers == 0 then
        local noServers = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 40),
            Font = Enum.Font.BuilderSans,
            Text = "😕 No low-population servers found.",
            TextColor3 = Colors.TextMuted,
            TextSize = 16,
        }, {
            Parent = ServerListFrame
        })
    else
        for _, server in ipairs(servers) do
            createServerEntry(server)
        end
    end
end)
