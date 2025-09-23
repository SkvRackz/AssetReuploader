--!nocheck

--[[
	Asset Reuploader Plugin
	
	This plugin creates a sleek UI in Roblox Studio with a port input and a
	working "Start" button. When clicked, it automatically reuploads all
	animations in your game by sending requests to a local server.
--]]

local toolbar = plugin:CreateToolbar("Asset Reuploader")
local btn = toolbar:CreateButton("Reuploader", "Auto-reuploads assets for you!", "rbxassetid://15220671607")

-- Create the plugin UI widget
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	true,
	250,
	350
)
local widget = plugin:CreateDockWidgetPluginGui("AssetReuploader", widgetInfo)
widget.Title = "Asset Reuploader"

-- Create the main UI frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.new(0.18, 0.18, 0.18)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = widget

-- Use a vertical list layout for clean spacing
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Padding = UDim.new(0, 10)
layout.Parent = mainFrame

-- Title Label
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, -20, 0, 30)
titleLabel.Text = "Asset Reuploader"
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.TextSize = 20
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Parent = mainFrame

-- Port Section Frame
local portSection = Instance.new("Frame")
portSection.Name = "PortSection"
portSection.Size = UDim2.new(1, -20, 0, 60)
portSection.BackgroundColor3 = Color3.new(0.25, 0.25, 0.25)
portSection.Parent = mainFrame

local portLayout = Instance.new("UIListLayout")
portLayout.FillDirection = Enum.FillDirection.Vertical
portLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
portLayout.Padding = UDim.new(0, 5)
portLayout.Parent = portSection

local portTitle = Instance.new("TextLabel")
portTitle.Name = "PortTitle"
portTitle.Size = UDim2.new(1, -10, 0, 20)
portTitle.Text = "Port"
portTitle.BackgroundTransparency = 1
portTitle.TextColor3 = Color3.new(1, 1, 1)
portTitle.TextSize = 14
portTitle.Font = Enum.Font.SourceSansBold
portTitle.Parent = portSection

local portTextBox = Instance.new("TextBox")
portTextBox.Name = "PortTextBox"
portTextBox.Size = UDim2.new(1, -10, 0, 25)
portTextBox.PlaceholderText = "Enter port number (e.g., 4730)"
portTextBox.Text = "4730" -- Default port
portTextBox.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
portTextBox.TextColor3 = Color3.new(1, 1, 1)
portTextBox.TextSize = 14
portTextBox.Font = Enum.Font.SourceSans
portTextBox.Parent = portSection

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Text = "Status: Idle"
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.new(1, 1, 1)
statusLabel.TextSize = 14
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = mainFrame

-- Start/Stop Button
local actionBtn = Instance.new("TextButton")
actionBtn.Name = "ActionButton"
actionBtn.Size = UDim2.new(1, -20, 0, 35)
actionBtn.Text = "Start Auto-Reuploader"
actionBtn.BackgroundColor3 = Color3.new(0.1, 0.5, 0.9)
actionBtn.TextColor3 = Color3.new(1, 1, 1)
actionBtn.TextSize = 16
actionBtn.Font = Enum.Font.SourceSansBold
actionBtn.Parent = mainFrame

-- Description Label
local descriptionLabel = Instance.new("TextLabel")
descriptionLabel.Size = UDim2.new(1, -20, 0, 50)
descriptionLabel.Text = "Auto-reuploads all animations in your game. Requires an external server."
descriptionLabel.BackgroundTransparency = 1
descriptionLabel.TextColor3 = Color3.new(0.6, 0.6, 0.6)
descriptionLabel.TextSize = 12
descriptionLabel.TextWrapped = true
descriptionLabel.Parent = mainFrame

-------------------------------------------------------------------------------
-- Logic
-------------------------------------------------------------------------------

local HttpService = game:GetService("HttpService")
local isRunning = false

local function setStatus(text, color)
	statusLabel.Text = "Status: " .. text
	if color then
		statusLabel.TextColor3 = color
	else
		statusLabel.TextColor3 = Color3.new(1, 1, 1)
	end
end

local function stopReuploader()
	isRunning = false
	actionBtn.Text = "Start Auto-Reuploader"
	actionBtn.BackgroundColor3 = Color3.new(0.1, 0.5, 0.9)
	setStatus("Idle", Color3.new(1, 1, 1))
	print("Reuploader stopped by user.")
end

local function startReuploader()
	if isRunning then
		stopReuploader()
		return
	end
	
	isRunning = true
	actionBtn.Text = "Stop Auto-Reuploader"
	actionBtn.BackgroundColor3 = Color3.new(0.9, 0.3, 0.3)
	
	local port = tonumber(portTextBox.Text)
	if not port then
		setStatus("Error: Invalid port number!", Color3.new(1, 0, 0))
		stopReuploader()
		return
	end
	
	setStatus("Scanning for animations...", Color3.new(0.8, 0.8, 0))
	
	local animations = {}
	for _, descendant in pairs(game:GetDescendants()) do
		if descendant:IsA("Animation") then
			table.insert(animations, descendant)
		end
	end

	if #animations == 0 then
		setStatus("No animations found!", Color3.new(1, 0, 0))
		stopReuploader()
		return
	end
	
	print("Found " .. #animations .. " animations to reupload on port " .. port .. ".")
	
	-- Create the full data object to send to the server
	local data = { animations = {} }
	for _, animation in ipairs(animations) do
		-- Extract only the numerical ID from the AnimationId string
		local animationId = string.match(animation.AnimationId, "%d+")
		
		-- Only add valid animations to the list
		if animationId then
			table.insert(data.animations, {
				AnimationId = tonumber(animationId),
				DisplayName = animation.Name
			})
		end
	end
	
	-- Check if any valid animations were found to send
	if #data.animations == 0 then
		setStatus("No valid animations found!", Color3.new(1, 0, 0))
		stopReuploader()
		return
	end

	local url = "http://localhost:" .. port
	local jsonData = HttpService:JSONEncode(data) -- Encode the entire data table
	
	-- Use a separate thread to prevent freezing Studio
	coroutine.wrap(function()
		local success, response = pcall(function()
			-- Explicitly set the content type to application/json
			return HttpService:PostAsync(url, jsonData, Enum.HttpContentType.ApplicationJson)
		end)
		
		if success then
			print("Successfully sent request to server.")
			setStatus("Reupload process completed!", Color3.new(0, 1, 0))
		else
			warn("Failed to send request to server.")
			warn("Error: " .. response)
			setStatus("Error: " .. tostring(response), Color3.new(1, 0, 0))
		end
		
		stopReuploader()
	end)()
end

-- Event handling
actionBtn.MouseButton1Click:Connect(startReuploader)

btn.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)