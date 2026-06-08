--[[
	Studio Lite AI Co-Pilot & GitHub Sync Loader
	Place this inside a Script in ServerScriptService.
	Make sure HttpService and LoadstringEnabled are active!
--]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Configuration & State
local config = {
	API_Key = "",
	GitHub_URL = "https://raw.githubusercontent.com/Baran3575/roblox-studio-lite-sync/main/src/main.lua",
	Sync_Enabled = true,
	Sync_Interval = 3
}

-- Try to load configuration from DataStore
local configStore
pcall(function()
	configStore = DataStoreService:GetDataStore("StudioLiteAIConfig_v2")
	local saved = configStore:GetAsync("Config")
	if saved then
		for k, v in pairs(saved) do
			config[k] = v
		end
	end
end)

local lastGitHubCode = ""

-- Safe save configuration function
local function saveConfig()
	pcall(function()
		if configStore then
			configStore:SetAsync("Config", config)
		end
	end)
end

-- Retrieve Game Info
local placeId = game.PlaceId
local gameId = game.GameId
local placeName = "Local Studio Playtest"
pcall(function()
	if placeId > 0 then
		placeName = MarketplaceService:GetProductInfo(placeId).Name
	end
end)

-- Clean markdown codeblocks from AI output
local function cleanLuaCode(text)
	text = text:gsub("^%s*```lua%s*", "")
	text = text:gsub("^%s*```%s*", "")
	text = text:gsub("%s*```%s*$", "")
	return text
end

-- Talk to Gemini API
local function askGemini(prompt)
	if not config.API_Key or config.API_Key == "" then
		return false, "API Key is missing! Set it in Settings."
	end

	local url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=" .. config.API_Key
	
	local systemPrompt = [[
You are an expert Roblox Lua developer. The user wants to write a script for their Roblox game.
Generate ONLY the executable Lua code. Do not wrap the output in markdown code blocks like ```lua. Return the raw script text.
Do not provide text explanations, only Lua code with comments if necessary.
Make sure to use modern Roblox practices (e.g. task.wait, task.spawn) and directly interact with game/workspace.
User Request: 
]]

	local payload = {
		contents = {
			{
				parts = {
					{ text = systemPrompt .. prompt }
				}
			}
		}
	}

	local success, response = pcall(function()
		return HttpService:PostAsync(
			url,
			HttpService:JSONEncode(payload),
			Enum.HttpContentType.ApplicationJson
		)
	end)

	if not success then
		return false, "HTTP Error: " .. tostring(response)
	end

	local dataSuccess, decoded = pcall(function()
		return HttpService:JSONDecode(response)
	end)

	if not dataSuccess or not decoded then
		return false, "Failed to decode response."
	end

	local generatedText = decoded.candidates
		and decoded.candidates[1]
		and decoded.candidates[1].content
		and decoded.candidates[1].content.parts
		and decoded.candidates[1].content.parts[1]
		and decoded.candidates[1].content.parts[1].text

	if not generatedText then
		return false, "Empty response from AI model."
	end

	return true, cleanLuaCode(generatedText)
end

-- Helper: Create UI elements programmatically
local function createUI(player)
	-- Clean up existing UI if any
	local existing = player:WaitForChild("PlayerGui"):FindFirstChild("StudioLiteSyncUI")
	if existing then existing:Destroy() end

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "StudioLiteSyncUI"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.Parent = player:WaitForChild("PlayerGui")

	-- Toggle Button
	local ToggleBtn = Instance.new("TextButton")
	ToggleBtn.Name = "ToggleBtn"
	ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
	ToggleBtn.Position = UDim2.new(0.95, -50, 0.9, -50)
	ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	ToggleBtn.BorderSizePixel = 0
	ToggleBtn.Text = "⚡"
	ToggleBtn.TextColor3 = Color3.fromRGB(0, 200, 255)
	ToggleBtn.TextSize = 24
	ToggleBtn.Parent = ScreenGui

	local ToggleCorner = Instance.new("UICorner")
	ToggleCorner.CornerRadius = UDim.new(0, 25)
	ToggleCorner.Parent = ToggleBtn

	local ToggleGlow = Instance.new("UIStroke")
	ToggleGlow.Color = Color3.fromRGB(0, 150, 255)
	ToggleGlow.Width = 2
	ToggleGlow.Parent = ToggleBtn

	-- Main Panel
	local MainPanel = Instance.new("Frame")
	MainPanel.Name = "MainPanel"
	MainPanel.Size = UDim2.new(0, 420, 0, 500)
	MainPanel.Position = UDim2.new(0.5, -210, 0.5, -250)
	MainPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	MainPanel.BackgroundTransparency = 0.05
	MainPanel.BorderSizePixel = 0
	MainPanel.Visible = true
	MainPanel.Parent = ScreenGui

	local PanelCorner = Instance.new("UICorner")
	PanelCorner.CornerRadius = UDim.new(0, 12)
	PanelCorner.Parent = MainPanel

	local PanelStroke = Instance.new("UIStroke")
	PanelStroke.Color = Color3.fromRGB(45, 45, 55)
	PanelStroke.Width = 1.5
	PanelStroke.Parent = MainPanel

	-- Title
	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, 0, 0, 40)
	Title.BackgroundTransparency = 1
	Title.Text = " STUDIO LITE CO-PILOT"
	Title.TextColor3 = Color3.fromRGB(240, 240, 250)
	Title.TextSize = 16
	Title.Font = Enum.Font.GothamBold
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = MainPanel

	local TitlePadding = Instance.new("UIPadding")
	TitlePadding.PaddingLeft = UDim.new(0, 15)
	TitlePadding.Parent = Title

	-- Tabs Layout
	local TabContainer = Instance.new("Frame")
	TabContainer.Size = UDim2.new(1, 0, 0, 35)
	TabContainer.Position = UDim2.new(0, 0, 0, 40)
	TabContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	TabContainer.BorderSizePixel = 0
	TabContainer.Parent = MainPanel

	local function makeTabButton(name, text, posX)
		local btn = Instance.new("TextButton")
		btn.Name = name .. "TabBtn"
		btn.Size = UDim2.new(0.33, 0, 1, 0)
		btn.Position = UDim2.new(posX, 0, 0, 0)
		btn.BackgroundTransparency = 1
		btn.Text = text
		btn.TextColor3 = Color3.fromRGB(150, 150, 160)
		btn.TextSize = 12
		btn.Font = Enum.Font.GothamSemibold
		btn.Parent = TabContainer
		return btn
	end

	local ChatTabBtn = makeTabButton("Chat", "💬 AI Chat", 0)
	local SyncTabBtn = makeTabButton("Sync", "🔗 GitHub Sync", 0.33)
	local SettingsTabBtn = makeTabButton("Settings", "⚙️ Settings", 0.66)

	-- Active Indicator
	local ActiveBar = Instance.new("Frame")
	ActiveBar.Size = UDim2.new(0.33, 0, 0, 2)
	ActiveBar.Position = UDim2.new(0, 0, 1, -2)
	ActiveBar.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
	ActiveBar.BorderSizePixel = 0
	ActiveBar.Parent = TabContainer

	-- Content Frames
	local ContentFrame = Instance.new("Frame")
	ContentFrame.Size = UDim2.new(1, 0, 1, -75)
	ContentFrame.Position = UDim2.new(0, 0, 0, 75)
	ContentFrame.BackgroundTransparency = 1
	ContentFrame.Parent = MainPanel

	-- 1. Chat Tab Panel
	local ChatPanel = Instance.new("Frame")
	ChatPanel.Size = UDim2.new(1, 0, 1, 0)
	ChatPanel.BackgroundTransparency = 1
	ChatPanel.Visible = true
	ChatPanel.Parent = ContentFrame

	local LogBox = Instance.new("ScrollingFrame")
	LogBox.Size = UDim2.new(1, -20, 1, -60)
	LogBox.Position = UDim2.new(0, 10, 0, 10)
	LogBox.BackgroundTransparency = 1
	LogBox.CanvasSize = UDim2.new(0, 0, 0, 0)
	LogBox.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
	LogBox.Parent = ChatPanel

	local LogLayout = Instance.new("UIListLayout")
	LogLayout.SortOrder = Enum.SortOrder.LayoutOrder
	LogLayout.Padding = UDim.new(0, 8)
	LogLayout.Parent = LogBox

	local ChatInput = Instance.new("TextBox")
	ChatInput.Size = UDim2.new(1, -90, 0, 35)
	ChatInput.Position = UDim2.new(0, 10, 1, -45)
	ChatInput.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
	ChatInput.PlaceholderText = "Ask AI to generate and run code..."
	ChatInput.Text = ""
	ChatInput.TextColor3 = Color3.fromRGB(240, 240, 250)
	ChatInput.TextSize = 13
	ChatInput.Font = Enum.Font.Gotham
	ChatInput.ClearTextOnFocus = false
	ChatInput.Parent = ChatPanel

	local InputCorner = Instance.new("UICorner")
	InputCorner.CornerRadius = UDim.new(0, 6)
	InputCorner.Parent = ChatInput
	
	local InputPadding = Instance.new("UIPadding")
	InputPadding.PaddingLeft = UDim.new(0, 8)
	InputPadding.Parent = ChatInput

	local SendBtn = Instance.new("TextButton")
	SendBtn.Size = UDim2.new(0, 70, 0, 35)
	SendBtn.Position = UDim2.new(1, -80, 1, -45)
	SendBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
	SendBtn.Text = "Send"
	SendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	SendBtn.Font = Enum.Font.GothamBold
	SendBtn.TextSize = 13
	SendBtn.Parent = ChatPanel

	local SendCorner = Instance.new("UICorner")
	SendCorner.CornerRadius = UDim.new(0, 6)
	SendCorner.Parent = SendBtn

	-- Function to append a log message
	local function appendLog(text, color)
		local log = Instance.new("TextLabel")
		log.Size = UDim2.new(1, 0, 0, 0)
		log.AutomaticSize = Enum.AutomaticSize.Y
		log.BackgroundTransparency = 1
		log.Text = text
		log.TextColor3 = color or Color3.fromRGB(200, 200, 200)
		log.TextSize = 12
		log.Font = Enum.Font.Gotham
		log.TextWrapped = true
		log.TextXAlignment = Enum.TextXAlignment.Left
		log.Parent = LogBox
	end

	-- 2. Sync Tab Panel
	local SyncPanel = Instance.new("Frame")
	SyncPanel.Size = UDim2.new(1, 0, 1, 0)
	SyncPanel.BackgroundTransparency = 1
	SyncPanel.Visible = false
	SyncPanel.Parent = ContentFrame

	local SyncList = Instance.new("Frame")
	SyncList.Size = UDim2.new(1, -20, 1, -20)
	SyncList.Position = UDim2.new(0, 10, 0, 10)
	SyncList.BackgroundTransparency = 1
	SyncList.Parent = SyncPanel

	local SyncLayout = Instance.new("UIListLayout")
	SyncLayout.Padding = UDim.new(0, 10)
	SyncLayout.Parent = SyncList

	local function makeInfoLabel(title, value)
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 0, 40)
		frame.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
		frame.BorderSizePixel = 0
		frame.Parent = SyncList

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = frame

		local lblTitle = Instance.new("TextLabel")
		lblTitle.Size = UDim2.new(0.4, 0, 1, 0)
		lblTitle.BackgroundTransparency = 1
		lblTitle.Text = title
		lblTitle.TextColor3 = Color3.fromRGB(150, 150, 160)
		lblTitle.TextSize = 12
		lblTitle.Font = Enum.Font.GothamBold
		lblTitle.TextXAlignment = Enum.TextXAlignment.Left
		lblTitle.Parent = frame
		
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 10)
		pad.Parent = lblTitle

		local lblVal = Instance.new("TextLabel")
		lblVal.Size = UDim2.new(0.6, 0, 1, 0)
		lblVal.Position = UDim2.new(0.4, 0, 0, 0)
		lblVal.BackgroundTransparency = 1
		lblVal.Text = tostring(value)
		lblVal.TextColor3 = Color3.fromRGB(220, 220, 230)
		lblVal.TextSize = 12
		lblVal.Font = Enum.Font.Gotham
		lblVal.TextXAlignment = Enum.TextXAlignment.Left
		lblVal.Parent = frame
		
		return lblVal
	end

	local valPlaceName = makeInfoLabel("Place Name:", placeName)
	local valPlaceId = makeInfoLabel("Place ID:", placeId)
	local valGameId = makeInfoLabel("Game ID:", gameId)
	
	local valSyncStatus = makeInfoLabel("Sync Status:", "Idle")
	local valLastSync = makeInfoLabel("Last Synced:", "Never")

	local ForceSyncBtn = Instance.new("TextButton")
	ForceSyncBtn.Size = UDim2.new(1, 0, 0, 40)
	ForceSyncBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 120)
	ForceSyncBtn.Text = "🔄 Force Git Sync Now"
	ForceSyncBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	ForceSyncBtn.Font = Enum.Font.GothamBold
	ForceSyncBtn.TextSize = 14
	ForceSyncBtn.Parent = SyncList

	local ForceSyncCorner = Instance.new("UICorner")
	ForceSyncCorner.CornerRadius = UDim.new(0, 6)
	ForceSyncCorner.Parent = ForceSyncBtn

	-- 3. Settings Tab Panel
	local SettingsPanel = Instance.new("Frame")
	SettingsPanel.Size = UDim2.new(1, 0, 1, 0)
	SettingsPanel.BackgroundTransparency = 1
	SettingsPanel.Visible = false
	SettingsPanel.Parent = ContentFrame

	local SettingsList = Instance.new("Frame")
	SettingsList.Size = UDim2.new(1, -20, 1, -20)
	SettingsList.Position = UDim2.new(0, 10, 0, 10)
	SettingsList.BackgroundTransparency = 1
	SettingsList.Parent = SettingsPanel

	local SettingsLayout = Instance.new("UIListLayout")
	SettingsLayout.Padding = UDim.new(0, 12)
	SettingsLayout.Parent = SettingsList

	local function makeInputBlock(title, placeholder, defaultValue, isPassword)
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 0, 15)
		lbl.BackgroundTransparency = 1
		lbl.Text = title
		lbl.TextColor3 = Color3.fromRGB(180, 180, 190)
		lbl.TextSize = 12
		lbl.Font = Enum.Font.GothamBold
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = SettingsList

		local tb = Instance.new("TextBox")
		tb.Size = UDim2.new(1, 0, 0, 35)
		tb.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
		tb.PlaceholderText = placeholder
		tb.Text = defaultValue
		tb.TextColor3 = Color3.fromRGB(240, 240, 250)
		tb.TextSize = 12
		tb.Font = Enum.Font.Gotham
		tb.ClearTextOnFocus = false
		if isPassword then
			-- Simplified hidden display
			if defaultValue ~= "" then
				tb.PlaceholderText = "••••••••••••••••"
				tb.Text = defaultValue
			end
		end
		tb.Parent = SettingsList

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = tb

		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 8)
		pad.Parent = tb

		return tb
	end

	local apiKeyInput = makeInputBlock("Gemini API Key:", "AI API key (gemini-2.5-flash)...", config.API_Key, true)
	local githubUrlInput = makeInputBlock("GitHub Raw Code URL:", "https://raw.githubusercontent.com/...", config.GitHub_URL, false)

	-- Sync Toggle
	local SyncToggleBtn = Instance.new("TextButton")
	SyncToggleBtn.Size = UDim2.new(1, 0, 0, 40)
	SyncToggleBtn.BackgroundColor3 = config.Sync_Enabled and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(60, 60, 70)
	SyncToggleBtn.Text = config.Sync_Enabled and "Auto-Sync: ENABLED" or "Auto-Sync: DISABLED"
	SyncToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	SyncToggleBtn.Font = Enum.Font.GothamBold
	SyncToggleBtn.TextSize = 13
	SyncToggleBtn.Parent = SettingsList

	local SyncToggleCorner = Instance.new("UICorner")
	SyncToggleCorner.CornerRadius = UDim.new(0, 6)
	SyncToggleCorner.Parent = SyncToggleBtn

	local SaveBtn = Instance.new("TextButton")
	SaveBtn.Size = UDim2.new(1, 0, 0, 40)
	SaveBtn.BackgroundColor3 = Color3.fromRGB(220, 160, 0)
	SaveBtn.Text = "Save Config"
	SaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	SaveBtn.Font = Enum.Font.GothamBold
	SaveBtn.TextSize = 14
	SaveBtn.Parent = SettingsList

	local SaveCorner = Instance.new("UICorner")
	SaveCorner.CornerRadius = UDim.new(0, 6)
	SaveCorner.Parent = SaveBtn

	-- Event Connections
	
	-- Panel Show/Hide
	ToggleBtn.Activated:Connect(function()
		MainPanel.Visible = not MainPanel.Visible
	end)

	-- Navigation Tabs
	local function setTab(activeName)
		ChatPanel.Visible = (activeName == "Chat")
		SyncPanel.Visible = (activeName == "Sync")
		SettingsPanel.Visible = (activeName == "Settings")

		ChatTabBtn.TextColor3 = Color3.fromRGB(150, 150, 160)
		SyncTabBtn.TextColor3 = Color3.fromRGB(150, 150, 160)
		SettingsTabBtn.TextColor3 = Color3.fromRGB(150, 150, 160)

		if activeName == "Chat" then
			ChatTabBtn.TextColor3 = Color3.fromRGB(240, 240, 250)
			ActiveBar:TweenPosition(UDim2.new(0, 0, 1, -2), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.2, true)
		elseif activeName == "Sync" then
			SyncTabBtn.TextColor3 = Color3.fromRGB(240, 240, 250)
			ActiveBar:TweenPosition(UDim2.new(0.33, 0, 1, -2), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.2, true)
		elseif activeName == "Settings" then
			SettingsTabBtn.TextColor3 = Color3.fromRGB(240, 240, 250)
			ActiveBar:TweenPosition(UDim2.new(0.66, 0, 1, -2), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.2, true)
		end
	end

	ChatTabBtn.Activated:Connect(function() setTab("Chat") end)
	SyncTabBtn.Activated:Connect(function() setTab("Sync") end)
	SettingsTabBtn.Activated:Connect(function() setTab("Settings") end)

	-- Chat Execution Logic
	local processingChat = false
	local function sendChatMsg()
		local prompt = ChatInput.Text
		if prompt == "" or processingChat then return end
		processingChat = true
		ChatInput.Text = ""

		appendLog("You: " .. prompt, Color3.fromRGB(150, 220, 255))
		appendLog("AI Co-pilot is writing code...", Color3.fromRGB(200, 180, 100))

		task.spawn(function()
			local success, result = askGemini(prompt)
			if success then
				appendLog("Executing Code...", Color3.fromRGB(100, 220, 150))
				
				local runSuccess, runError = pcall(function()
					local func = loadstring(result)
					if func then
						task.spawn(func)
					else
						error("Syntax error in generated Lua code.")
					end
				end)

				if runSuccess then
					appendLog("Code executed successfully!", Color3.fromRGB(0, 255, 120))
				else
					appendLog("Execution Error: " .. tostring(runError), Color3.fromRGB(255, 100, 100))
				end
			else
				appendLog("AI Error: " .. result, Color3.fromRGB(255, 100, 100))
			end
			processingChat = false
		end)
	end

	SendBtn.Activated:Connect(sendChatMsg)
	ChatInput.FocusLost:Connect(function(enterPressed)
		if enterPressed then sendChatMsg() end
	end)

	-- Settings Toggle Auto-Sync
	SyncToggleBtn.Activated:Connect(function()
		config.Sync_Enabled = not config.Sync_Enabled
		saveConfig()
		SyncToggleBtn.BackgroundColor3 = config.Sync_Enabled and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(60, 60, 70)
		SyncToggleBtn.Text = config.Sync_Enabled and "Auto-Sync: ENABLED" or "Auto-Sync: DISABLED"
	end)

	-- Save Configuration
	SaveBtn.Activated:Connect(function()
		config.API_Key = apiKeyInput.Text
		config.GitHub_URL = githubUrlInput.Text
		saveConfig()
		appendLog("Settings updated and saved!", Color3.fromRGB(100, 255, 100))
	end)

	-- Global loop updater hook for showing states on UI
	task.spawn(function()
		while ScreenGui.Parent do
			valSyncStatus.Text = config.Sync_Enabled and "Syncing..." or "Disabled"
			valSyncStatus.TextColor3 = config.Sync_Enabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(200, 80, 80)
			
			if lastGitHubCode ~= "" then
				valLastSync.Text = os.date("%H:%M:%S")
			end
			task.wait(1)
		end
	end)

	-- Initial Welcome Msg
	appendLog("Welcome to Studio Lite Co-Pilot!", Color3.fromRGB(0, 200, 255))
	if not config.API_Key or config.API_Key == "" then
		appendLog("⚠️ Please go to Settings tab and set your Gemini API Key.", Color3.fromRGB(255, 150, 0))
	else
		appendLog("System ready! Ask me anything.", Color3.fromRGB(100, 255, 150))
	end
end

-- Initialize UI on Player Join
Players.PlayerAdded:Connect(createUI)
for _, p in ipairs(Players:GetPlayers()) do
	createUI(p)
end

-- GitHub Auto-Sync Loop
task.spawn(function()
	print("[Sync] GitHub Auto-Sync background service initialized.")
	while true do
		if config.Sync_Enabled and config.GitHub_URL and config.GitHub_URL ~= "" then
			local success, response = pcall(function()
				return HttpService:GetAsync(config.GitHub_URL .. "?t=" .. tostring(os.time()))
			end)

			if success and response then
				if response ~= lastGitHubCode then
					lastGitHubCode = response
					print("[Sync] New code fetched from GitHub! Executing...")

					local runSuccess, runError = pcall(function()
						local func = loadstring(response)
						if func then
							task.spawn(func)
						else
							error("Syntax error in downloaded GitHub script.")
						end
					end)

					if not runSuccess then
						warn("[Sync] Error running GitHub code: " .. tostring(runError))
					else
						print("[Sync] GitHub code executed successfully!")
					end
				end
			else
				warn("[Sync] GitHub Fetch Error: " .. tostring(response))
			end
		end
		task.wait(config.Sync_Interval)
	end
end)
