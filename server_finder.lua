local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local placeId = game.PlaceId

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ServerFinder"
screenGui.ResetOnSpawn = false

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 400, 0, 500)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
title.BorderSizePixel = 0
title.Text = "Server Finder - Least Players"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -30, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.TextSize = 16
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = mainFrame

closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Place ID Label
local placeIdLabel = Instance.new("TextLabel")
placeIdLabel.Name = "PlaceIdLabel"
placeIdLabel.Size = UDim2.new(1, -20, 0, 25)
placeIdLabel.Position = UDim2.new(0, 10, 0, 50)
placeIdLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
placeIdLabel.BorderSizePixel = 0
placeIdLabel.Text = "Place ID: " .. tostring(placeId)
placeIdLabel.TextColor3 = Color3.new(1, 1, 1)
placeIdLabel.TextSize = 14
placeIdLabel.Font = Enum.Font.Gotham
placeIdLabel.TextXAlignment = Enum.TextXAlignment.Left
placeIdLabel.Parent = mainFrame

-- Search Button
local searchButton = Instance.new("TextButton")
searchButton.Name = "SearchButton"
searchButton.Size = UDim2.new(1, -20, 0, 35)
searchButton.Position = UDim2.new(0, 10, 0, 85)
searchButton.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
searchButton.BorderSizePixel = 0
searchButton.Text = "Find Server with Least Players"
searchButton.TextColor3 = Color3.new(1, 1, 1)
searchButton.TextSize = 14
searchButton.Font = Enum.Font.GothamBold
searchButton.Parent = mainFrame

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -20, 0, 25)
statusLabel.Position = UDim2.new(0, 10, 0, 130)
statusLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
statusLabel.BorderSizePixel = 0
statusLabel.Text = "Status: Ready"
statusLabel.TextColor3 = Color3.new(1, 1, 1)
statusLabel.TextSize = 13
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = mainFrame

-- Server List Frame
local listFrame = Instance.new("ScrollingFrame")
listFrame.Name = "ListFrame"
listFrame.Size = UDim2.new(1, -20, 1, -270)
listFrame.Position = UDim2.new(0, 10, 0, 165)
listFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 6
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.Parent = mainFrame

-- Auto-join toggle
local autoJoinLabel = Instance.new("TextLabel")
autoJoinLabel.Name = "AutoJoinLabel"
autoJoinLabel.Size = UDim2.new(0, 150, 0, 25)
autoJoinLabel.Position = UDim2.new(0, 10, 1, -35)
autoJoinLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
autoJoinLabel.BorderSizePixel = 0
autoJoinLabel.Text = "Auto-join lowest:"
autoJoinLabel.TextColor3 = Color3.new(1, 1, 1)
autoJoinLabel.TextSize = 13
autoJoinLabel.Font = Enum.Font.Gotham
autoJoinLabel.TextXAlignment = Enum.TextXAlignment.Left
autoJoinLabel.Parent = mainFrame

local autoJoinToggle = Instance.new("TextButton")
autoJoinToggle.Name = "AutoJoinToggle"
autoJoinToggle.Size = UDim2.new(0, 60, 0, 25)
autoJoinToggle.Position = UDim2.new(0, 165, 1, -35)
autoJoinToggle.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
autoJoinToggle.BorderSizePixel = 0
autoJoinToggle.Text = "ON"
autoJoinToggle.TextColor3 = Color3.new(1, 1, 1)
autoJoinToggle.TextSize = 13
autoJoinToggle.Font = Enum.Font.GothamBold
autoJoinToggle.Parent = mainFrame

local autoJoinEnabled = true

autoJoinToggle.MouseButton1Click:Connect(function()
    autoJoinEnabled = not autoJoinEnabled
    if autoJoinEnabled then
        autoJoinToggle.Text = "ON"
        autoJoinToggle.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    else
        autoJoinToggle.Text = "OFF"
        autoJoinToggle.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    end
end)

-- Function to get servers
local function getServers()
    if not HttpService.HttpEnabled then
        return nil, "HTTP Service not enabled"
    end
    
    local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", placeId)
    
    local success, response = pcall(function()
        return HttpService:GetAsync(url)
    end)
    
    if not success then
        return nil, "Failed to fetch servers"
    end
    
    local success, data = pcall(function()
        return HttpService:JSONDecode(response)
    end)
    
    if not success then
        return nil, "Failed to parse data"
    end
    
    return data, nil
end

-- Function to create server button
local function createServerButton(server, index)
    local btn = Instance.new("TextButton")
    btn.Name = "ServerBtn"
    btn.Size = UDim2.new(1, -10, 0, 40)
    btn.Position = UDim2.new(0, 5, 0, 5 + (index * 45))
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.Parent = listFrame
    
    -- Server info text
    local infoText = Instance.new("TextLabel")
    infoText.Size = UDim2.new(1, -10, 1, 0)
    infoText.Position = UDim2.new(0, 5, 0, 0)
    infoText.BackgroundColor3 = Color3.fromRGB(255, 255, 255, 0)
    infoText.BorderSizePixel = 0
    infoText.Text = string.format("Server %d | Players: %d/%d | JobId: %s", 
        index + 1, server.playing, server.maxPlayers, string.sub(server.id, 1, 8).."...")
    infoText.TextColor3 = Color3.new(1, 1, 1)
    infoText.TextSize = 12
    infoText.Font = Enum.Font.Gotham
    infoText.TextXAlignment = Enum.TextXAlignment.Left
    infoText.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        statusLabel.Text = "Status: Teleporting..."
        TeleportService:TeleportToPlaceInstance(placeId, server.id, player)
    end)
    
    return btn
end

-- Search button click
searchButton.MouseButton1Click:Connect(function()
    statusLabel.Text = "Status: Searching..."
    
    -- Clear previous list
    for _, child in ipairs(listFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    local data, error = getServers()
    
    if error then
        statusLabel.Text = "Status: Error - " .. error
        return
    end
    
    if not data.data or #data.data == 0 then
        statusLabel.Text = "Status: No servers found"
        return
    end
    
    -- Find server with least players
    local lowestServer = nil
    local lowestCount = math.huge
    
    for _, server in ipairs(data.data) do
        if server.playing < lowestCount and server.playing < server.maxPlayers then
            lowestCount = server.playing
            lowestServer = server
        end
    end
    
    if not lowestServer then
        statusLabel.Text = "Status: All servers full"
        return
    end
    
    -- Display servers
    local serverCount = 0
    for i, server in ipairs(data.data) do
        if server.playing < server.maxPlayers then
            local btn = createServerButton(server, serverCount)
            
            -- Highlight lowest server
            if server.id == lowestServer.id then
                btn.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
            end
            
            serverCount = serverCount + 1
        end
    end
    
    listFrame.CanvasSize = UDim2.new(0, 0, 0, 5 + (serverCount * 45))
    
    if autoJoinEnabled then
        statusLabel.Text = string.format("Status: Found server with %d players. Auto-joining...", lowestCount)
        wait(2)
        TeleportService:TeleportToPlaceInstance(placeId, lowestServer.id, player)
    else
        statusLabel.Text = string.format("Status: Found %d servers. Lowest: %d players", serverCount, lowestCount)
    end
end)

-- Add to player
screenGui.Parent = player:WaitForChild("PlayerGui")

print("Server Finder GUI loaded!")
