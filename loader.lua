--[[
	Studio Lite AI Co-Pilot & GitHub Sync Loader — v2.4.0
	Place this inside a Script in ServerScriptService.
	Make sure HttpService and LoadstringEnabled are active!
	
	Design Read: Roblox in-game development utility UI, with a dark-tech neon-accented 
	glassmorphic visual language, using vector-drawn UI elements instead of emoji slop.
--]]

local RunService = game:GetService("RunService")

if RunService:IsClient() then
	-- =========================================================================
	-- CLIENT-SIDE CONTROLLER (Smooth UI Tweens, Hover Effects, and Tab Handling)
	-- =========================================================================
	
	local TweenService = game:GetService("TweenService")
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	
	local player = Players.LocalPlayer
	local ScreenGui = script.Parent
	local MainPanel = ScreenGui:WaitForChild("MainPanel")
	local ToggleBtn = ScreenGui:WaitForChild("ToggleBtn")
	
	-- Content Panels
	local ContentFrame = MainPanel:WaitForChild("ContentFrame")
	local ChatPanel = ContentFrame:WaitForChild("ChatPanel")
	local SyncPanel = ContentFrame:WaitForChild("SyncPanel")
	local SettingsPanel = ContentFrame:WaitForChild("SettingsPanel")
	local ChangelogPanel = ContentFrame:WaitForChild("ChangelogPanel")
	
	-- Tabs
	local TabContainer = MainPanel:WaitForChild("TabContainer")
	local ActiveBar = TabContainer:WaitForChild("ActiveBar")
	
	-- Networking
	local SyncEvent = ReplicatedStorage:WaitForChild("StudioLiteSyncEvent")
	
	-- State
	local currentTab = "Chat"
	local panelOpen = true
	local apiConfig = {
		API_Key = "",
		GitHub_URL = "",
		Sync_Enabled = true,
		Model = "gemini-3.5-flash",
		Custom_Model = ""
	}

	-- Animation Helpers
	local function tween(object, info, propertyTable)
		local t = TweenService:Create(object, info, propertyTable)
		t:Play()
		return t
	end

	local fastInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local elasticInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	-- Tactile button hover/click animations
	local function addTactileFeedback(button, defaultColor, hoverColor)
		button.MouseEnter:Connect(function()
			tween(button, fastInfo, {
				BackgroundColor3 = hoverColor,
				Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset + 4, button.Size.Y.Scale, button.Size.Y.Offset + 2)
			})
		end)
		
		button.MouseLeave:Connect(function()
			tween(button, fastInfo, {
				BackgroundColor3 = defaultColor,
				Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset - 4, button.Size.Y.Scale, button.Size.Y.Offset - 2)
			})
		end)
		
		button.MouseButton1Down:Connect(function()
			tween(button, fastInfo, {
				Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset - 2, button.Size.Y.Scale, button.Size.Y.Offset - 2)
			})
		end)
	end

	addTactileFeedback(ToggleBtn, Color3.fromRGB(20, 20, 25), Color3.fromRGB(30, 30, 40))
	
	-- Panel Open/Close
	ToggleBtn.Activated:Connect(function()
		panelOpen = not panelOpen
		if panelOpen then
			MainPanel.Visible = true
			MainPanel.Size = UDim2.new(0, 0, 0, 0)
			MainPanel.BackgroundTransparency = 1
			tween(MainPanel, elasticInfo, {
				Size = UDim2.new(0, 440, 0, 520),
				BackgroundTransparency = 0.05
			})
		else
			local t = tween(MainPanel, fastInfo, {
				Size = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 1
			})
			t.Completed:Connect(function()
				if not panelOpen then MainPanel.Visible = false end
			end)
		end
	end)

	-- Tab Handler & Hover States for Tab Icons
	local function setTab(tabName)
		currentTab = tabName
		ChatPanel.Visible = (tabName == "Chat")
		SyncPanel.Visible = (tabName == "Sync")
		SettingsPanel.Visible = (tabName == "Settings")
		ChangelogPanel.Visible = (tabName == "Changelog")

		-- Animate Indicator Bar
		local positions = {
			Chat = UDim2.new(0, 0, 1, -2),
			Sync = UDim2.new(0.25, 0, 1, -2),
			Settings = UDim2.new(0.5, 0, 1, -2),
			Changelog = UDim2.new(0.75, 0, 1, -2)
		}
		tween(ActiveBar, fastInfo, {Position = positions[tabName]})
		
		-- Update Text & Icon Colors
		for _, name in ipairs({"Chat", "Sync", "Settings", "Changelog"}) do
			local btn = TabContainer:FindFirstChild(name .. "TabBtn")
			local icon = btn and btn:FindFirstChild("Icon")
			if btn then
				if name == tabName then
					btn.TextColor3 = Color3.fromRGB(240, 240, 250)
					if icon then
						for _, desc in ipairs(icon:GetDescendants()) do
							if desc:IsA("Frame") then
								desc.BackgroundColor3 = Color3.fromRGB(240, 240, 250)
							elseif desc:IsA("UIStroke") then
								desc.Color = Color3.fromRGB(240, 240, 250)
							end
						end
					end
				else
					btn.TextColor3 = Color3.fromRGB(130, 130, 140)
					if icon then
						for _, desc in ipairs(icon:GetDescendants()) do
							if desc:IsA("Frame") then
								desc.BackgroundColor3 = Color3.fromRGB(130, 130, 140)
							elseif desc:IsA("UIStroke") then
								desc.Color = Color3.fromRGB(130, 130, 140)
							end
						end
					end
				end
			end
		end
	end

	TabContainer.ChatTabBtn.Activated:Connect(function() setTab("Chat") end)
	TabContainer.SyncTabBtn.Activated:Connect(function() setTab("Sync") end)
	TabContainer.SettingsTabBtn.Activated:Connect(function() setTab("Settings") end)
	TabContainer.ChangelogTabBtn.Activated:Connect(function() setTab("Changelog") end)

	-- Model selection grid logic
	local modelGrid = SettingsPanel:WaitForChild("SettingsList"):WaitForChild("ModelGrid")
	local customModelBox = SettingsPanel.SettingsList:WaitForChild("CustomModelInput")
	
	local function updateModelSelectionUI(selectedModel)
		for _, child in ipairs(modelGrid:GetChildren()) do
			if child:IsA("TextButton") then
				if child.Name == selectedModel then
					child.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
					child.TextColor3 = Color3.fromRGB(255, 255, 255)
				else
					child.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
					child.TextColor3 = Color3.fromRGB(180, 180, 190)
				end
			end
		end
		
		if selectedModel == "custom" then
			customModelBox.Visible = true
		else
			customModelBox.Visible = false
		end
	end

	for _, child in ipairs(modelGrid:GetChildren()) do
		if child:IsA("TextButton") then
			child.Activated:Connect(function()
				apiConfig.Model = child.Name
				updateModelSelectionUI(child.Name)
			end)
		end
	end

	-- Send Message Logic
	local SendBtn = ChatPanel:WaitForChild("SendBtn")
	local ChatInput = ChatPanel:WaitForChild("ChatInput")
	local LogBox = ChatPanel:WaitForChild("LogBox")

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
		
		LogBox.CanvasPosition = Vector2.new(0, LogBox.AbsoluteCanvasSize.Y)
	end

	local function sendPrompt()
		local text = ChatInput.Text
		if text == "" then return end
		ChatInput.Text = ""
		SyncEvent:FireServer("SendChat", text)
	end

	SendBtn.Activated:Connect(sendPrompt)
	ChatInput.FocusLost:Connect(function(enterPressed)
		if enterPressed then sendPrompt() end
	end)

	-- Settings save logic
	local SaveBtn = SettingsPanel.SettingsList:WaitForChild("SaveBtn")
	local apiKeyInput = SettingsPanel.SettingsList:WaitForChild("ApiKeyInput")
	local githubUrlInput = SettingsPanel.SettingsList:WaitForChild("GithubUrlInput")
	local SyncToggleBtn = SettingsPanel.SettingsList:WaitForChild("SyncToggleBtn")

	SaveBtn.Activated:Connect(function()
		apiConfig.API_Key = apiKeyInput.Text
		apiConfig.GitHub_URL = githubUrlInput.Text
		apiConfig.Custom_Model = customModelBox.Text
		SyncEvent:FireServer("SaveConfig", apiConfig)
	end)

	SyncToggleBtn.Activated:Connect(function()
		apiConfig.Sync_Enabled = not apiConfig.Sync_Enabled
		SyncEvent:FireServer("ToggleSync", apiConfig.Sync_Enabled)
	end)

	-- Force Sync
	local ForceSyncBtn = SyncPanel:WaitForChild("SyncList"):WaitForChild("ForceSyncBtn")
	ForceSyncBtn.Activated:Connect(function()
		SyncEvent:FireServer("ForceSync")
	end)

	-- Server Sync Listener
	SyncEvent.OnClientEvent:Connect(function(action, data, extra)
		if action == "UpdateConfig" then
			apiConfig = data
			apiKeyInput.Text = apiConfig.API_Key
			githubUrlInput.Text = apiConfig.GitHub_URL
			customModelBox.Text = apiConfig.Custom_Model or ""
			
			SyncToggleBtn.BackgroundColor3 = apiConfig.Sync_Enabled and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(60, 60, 70)
			SyncToggleBtn.Text = apiConfig.Sync_Enabled and "Auto-Sync: ENABLED" or "Auto-Sync: DISABLED"
			
			updateModelSelectionUI(apiConfig.Model)
		elseif action == "Log" then
			appendLog(data, extra)
		elseif action == "UpdateSyncStats" then
			SyncPanel.SyncList.SyncStatusLabel.ValueLabel.Text = data.status
			SyncPanel.SyncList.SyncStatusLabel.ValueLabel.TextColor3 = data.color
			SyncPanel.SyncList.LastSyncLabel.ValueLabel.Text = data.lastSync
		end
	end)

	-- Initialize tab layout
	setTab("Chat")

else
	-- =========================================================================
	-- SERVER-SIDE SYSTEM (HttpService, Gemini API client, GitHub Sync, DataStores)
	-- =========================================================================
	
	local HttpService = game:GetService("HttpService")
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local DataStoreService = game:GetService("DataStoreService")
	local MarketplaceService = game:GetService("MarketplaceService")

	-- Initial Config Setup (Uses Gemini 3.5 Flash by default)
	local config = {
		API_Key = "",
		GitHub_URL = "https://raw.githubusercontent.com/Baran3575/roblox-studio-lite-sync/main/src/main.lua",
		Sync_Enabled = true,
		Sync_Interval = 3,
		Model = "gemini-3.5-flash",
		Custom_Model = ""
	}

	-- DataStore Configuration Persistence
	local configStore
	pcall(function()
		configStore = DataStoreService:GetDataStore("StudioLiteAIConfig_v5")
		local saved = configStore:GetAsync("Config")
		if saved then
			for k, v in pairs(saved) do
				config[k] = v
			end
		end
	end)

	local lastGitHubCode = ""
	local lastSyncTime = "Never"

	local SyncEvent = ReplicatedStorage:FindFirstChild("StudioLiteSyncEvent")
	if not SyncEvent then
		SyncEvent = Instance.new("RemoteEvent")
		SyncEvent.Name = "StudioLiteSyncEvent"
		SyncEvent.Parent = ReplicatedStorage
	end

	-- Clean markdown code blocks from Gemini outputs
	local function cleanLuaCode(text)
		text = text:gsub("^%s*```lua%s*", "")
		text = text:gsub("^%s*```%s*", "")
		text = text:gsub("%s*```%s*$", "")
		return text
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

	-- Talk to Gemini API
	local function askGemini(prompt)
		if not config.API_Key or config.API_Key == "" then
			return false, "API Key is missing! Add it in Settings."
		end

		local modelName = config.Model
		if modelName == "custom" then
			modelName = config.Custom_Model ~= "" and config.Custom_Model or "gemini-3.5-flash"
		end

		local url = "https://generativelanguage.googleapis.com/v1beta/models/" .. modelName .. ":generateContent?key=" .. config.API_Key
		
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

		local generatedText = decoded.contents
			and decoded.contents[1]
			and decoded.contents[1].parts
			and decoded.contents[1].parts[1]
			and decoded.contents[1].parts[1].text
			or (decoded.candidates and decoded.candidates[1] and decoded.candidates[1].content and decoded.candidates[1].content.parts and decoded.candidates[1].content.parts[1] and decoded.candidates[1].content.parts[1].text)

		if not generatedText then
			return false, "Empty response from AI model."
		end

		return true, cleanLuaCode(generatedText)
	end

	-- Programmatic Vector Graphic Helpers
	
	-- Draw Lua Logo (Official style)
	local function drawLuaLogo(parent, size, pos)
		local logo = Instance.new("Frame")
		logo.Name = "LuaLogo"
		logo.Size = size
		logo.Position = pos
		logo.BackgroundTransparency = 1
		logo.Parent = parent

		-- Earth Circle (Dark Blue Orbit Path)
		local orbit = Instance.new("Frame")
		orbit.Size = UDim2.new(0.85, 0, 0.85, 0)
		orbit.Position = UDim2.new(0.075, 0, 0.075, 0)
		orbit.BackgroundColor3 = Color3.fromRGB(0, 0, 128)
		orbit.BackgroundTransparency = 1
		orbit.Parent = logo
		
		local orbitCorner = Instance.new("UICorner")
		orbitCorner.CornerRadius = UDim.new(0.5, 0)
		orbitCorner.Parent = orbit
		
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(80, 110, 190)
		stroke.Width = 1.5
		stroke.Parent = orbit

		-- Main Planet Circle (Cyan-Blue Gradient)
		local planet = Instance.new("Frame")
		planet.Size = UDim2.new(0.64, 0, 0.64, 0)
		planet.Position = UDim2.new(0.18, 0, 0.18, 0)
		planet.BackgroundColor3 = Color3.fromRGB(0, 100, 220)
		planet.BorderSizePixel = 0
		planet.Parent = logo
		
		local planetCorner = Instance.new("UICorner")
		planetCorner.CornerRadius = UDim.new(0.5, 0)
		planetCorner.Parent = planet

		-- Satellite Moon
		local moon = Instance.new("Frame")
		moon.Size = UDim2.new(0.2, 0, 0.2, 0)
		moon.Position = UDim2.new(0.72, 0, 0.08, 0)
		moon.BackgroundColor3 = Color3.fromRGB(240, 240, 250)
		moon.BorderSizePixel = 0
		moon.Parent = logo
		
		local moonCorner = Instance.new("UICorner")
		moonCorner.CornerRadius = UDim.new(0.5, 0)
		moonCorner.Parent = moon

		-- Text label
		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(1, 0, 1, 0)
		text.BackgroundTransparency = 1
		text.Text = "Lua"
		text.TextColor3 = Color3.fromRGB(255, 255, 255)
		text.TextSize = 10
		text.Font = Enum.Font.GothamBold
		text.Parent = planet
	end

	-- Draw Lightning Bolt for Toggle (Vector representation of ⚡)
	local function drawLightningBolt(parent)
		local iconFrame = Instance.new("Frame")
		iconFrame.Name = "LightningIcon"
		iconFrame.Size = UDim2.new(0, 16, 0, 24)
		iconFrame.Position = UDim2.new(0.5, -8, 0.5, -12)
		iconFrame.BackgroundTransparency = 1
		iconFrame.Parent = parent

		-- Top Part
		local top = Instance.new("Frame")
		top.Size = UDim2.new(0.6, 0, 0.5, 0)
		top.Position = UDim2.new(0.3, 0, 0, 0)
		top.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
		top.BorderSizePixel = 0
		top.Rotation = -15
		top.Parent = iconFrame

		-- Bottom Part
		local bottom = Instance.new("Frame")
		bottom.Size = UDim2.new(0.5, 0, 0.55, 0)
		bottom.Position = UDim2.new(0.1, 0, 0.45, 0)
		bottom.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
		bottom.BorderSizePixel = 0
		bottom.Rotation = -15
		bottom.Parent = iconFrame
	end

	-- Vector Chat speech bubble
	local function drawChatIcon(parent)
		local icon = Instance.new("Frame")
		icon.Name = "Icon"
		icon.Size = UDim2.new(0, 15, 0, 12)
		icon.Position = UDim2.new(0.1, 0, 0.5, -6)
		icon.BackgroundColor3 = Color3.fromRGB(130, 130, 140)
		icon.BorderSizePixel = 0
		icon.Parent = parent
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 3)
		corner.Parent = icon
		
		local tail = Instance.new("Frame")
		tail.Size = UDim2.new(0, 5, 0, 5)
		tail.Position = UDim2.new(0.15, 0, 0.7, 0)
		tail.Rotation = 45
		tail.BackgroundColor3 = Color3.fromRGB(130, 130, 140)
		tail.BorderSizePixel = 0
		tail.Parent = icon
	end

	-- Vector Sync overlapping link circles
	local function drawSyncIcon(parent)
		local icon = Instance.new("Frame")
		icon.Name = "Icon"
		icon.Size = UDim2.new(0, 14, 0, 14)
		icon.Position = UDim2.new(0.1, 0, 0.5, -7)
		icon.BackgroundTransparency = 1
		icon.Parent = parent

		local r1 = Instance.new("Frame")
		r1.Size = UDim2.new(0.65, 0, 0.65, 0)
		r1.BackgroundTransparency = 1
		r1.Parent = icon
		
		local c1 = Instance.new("UICorner")
		c1.CornerRadius = UDim.new(0.5, 0)
		c1.Parent = r1
		
		local s1 = Instance.new("UIStroke")
		s1.Color = Color3.fromRGB(130, 130, 140)
		s1.Width = 1.5
		s1.Parent = r1

		local r2 = Instance.new("Frame")
		r2.Size = UDim2.new(0.65, 0, 0.65, 0)
		r2.Position = UDim2.new(0.35, 0, 0.35, 0)
		r2.BackgroundTransparency = 1
		r2.Parent = icon
		
		local c2 = Instance.new("UICorner")
		c2.CornerRadius = UDim.new(0.5, 0)
		c2.Parent = r2
		
		local s2 = Instance.new("UIStroke")
		s2.Color = Color3.fromRGB(130, 130, 140)
		s2.Width = 1.5
		s2.Parent = r2
	end

	-- Vector Settings Gear Wheel
	local function drawSettingsIcon(parent)
		local icon = Instance.new("Frame")
		icon.Name = "Icon"
		icon.Size = UDim2.new(0, 14, 0, 14)
		icon.Position = UDim2.new(0.1, 0, 0.5, -7)
		icon.BackgroundTransparency = 1
		icon.Parent = parent

		local body = Instance.new("Frame")
		body.Size = UDim2.new(0.7, 0, 0.7, 0)
		body.Position = UDim2.new(0.15, 0, 0.15, 0)
		body.BackgroundTransparency = 1
		body.Parent = icon
		
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.5, 0)
		c.Parent = body
		
		local s = Instance.new("UIStroke")
		s.Color = Color3.fromRGB(130, 130, 140)
		s.Width = 2
		s.Parent = body

		for i = 1, 4 do
			local bar = Instance.new("Frame")
			bar.Size = UDim2.new(0.18, 0, 1, 0)
			bar.Position = UDim2.new(0.41, 0, 0, 0)
			bar.BackgroundColor3 = Color3.fromRGB(130, 130, 140)
			bar.BorderSizePixel = 0
			bar.Rotation = (i - 1) * 45
			bar.Parent = icon
		end
	end

	-- Vector Document Changelog Icon
	local function drawLogsIcon(parent)
		local icon = Instance.new("Frame")
		icon.Name = "Icon"
		icon.Size = UDim2.new(0, 12, 0, 14)
		icon.Position = UDim2.new(0.12, 0, 0.5, -7)
		icon.BackgroundTransparency = 1
		icon.Parent = parent

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(130, 130, 140)
		stroke.Width = 1.5
		stroke.Parent = icon

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 2)
		corner.Parent = icon

		for i = 1, 3 do
			local line = Instance.new("Frame")
			line.Size = UDim2.new(0.6, 0, 0, 1)
			line.Position = UDim2.new(0.2, 0, 0.25 * i + 0.1, 0)
			line.BackgroundColor3 = Color3.fromRGB(130, 130, 140)
			line.BorderSizePixel = 0
			line.Parent = icon
		end
	end

	-- Static UI builder runs on Server
	local function buildUI(player)
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
		ToggleBtn.Text = "" 
		ToggleBtn.Parent = ScreenGui

		local ToggleCorner = Instance.new("UICorner")
		ToggleCorner.CornerRadius = UDim.new(0, 25)
		ToggleCorner.Parent = ToggleBtn

		local ToggleGlow = Instance.new("UIStroke")
		ToggleGlow.Color = Color3.fromRGB(0, 150, 255)
		ToggleGlow.Width = 2
		ToggleGlow.Parent = ToggleBtn

		drawLightningBolt(ToggleBtn)

		-- Main Panel
		local MainPanel = Instance.new("Frame")
		MainPanel.Name = "MainPanel"
		MainPanel.Size = UDim2.new(0, 440, 0, 520)
		MainPanel.Position = UDim2.new(0.5, -220, 0.5, -260)
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
		Title.Size = UDim2.new(1, -40, 0, 45)
		Title.Position = UDim2.new(0, 40, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Text = "Studio Lite Co-Pilot  v2.4.0"
		Title.TextColor3 = Color3.fromRGB(240, 240, 250)
		Title.TextSize = 14
		Title.Font = Enum.Font.GothamBold
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = MainPanel
		
		drawLuaLogo(MainPanel, UDim2.new(0, 24, 0, 24), UDim2.new(0, 12, 0, 10))

		-- Tab Container
		local TabContainer = Instance.new("Frame")
		TabContainer.Name = "TabContainer"
		TabContainer.Size = UDim2.new(1, 0, 0, 35)
		TabContainer.Position = UDim2.new(0, 0, 0, 45)
		TabContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
		TabContainer.BorderSizePixel = 0
		TabContainer.Parent = MainPanel

		local function makeTabButton(name, text, posX, drawIconCallback)
			local btn = Instance.new("TextButton")
			btn.Name = name .. "TabBtn"
			btn.Size = UDim2.new(0.25, 0, 1, 0)
			btn.Position = UDim2.new(posX, 0, 0, 0)
			btn.BackgroundTransparency = 1
			btn.Text = text
			btn.TextColor3 = Color3.fromRGB(130, 130, 140)
			btn.TextSize = 11
			btn.Font = Enum.Font.GothamSemibold
			btn.Parent = TabContainer
			
			drawIconCallback(btn)
			return btn
		end

		local ChatTabBtn = makeTabButton("Chat", "      Chat", 0, drawChatIcon)
		local SyncTabBtn = makeTabButton("Sync", "      Sync", 0.25, drawSyncIcon)
		local SettingsTabBtn = makeTabButton("Settings", "      Config", 0.50, drawSettingsIcon)
		local ChangelogTabBtn = makeTabButton("Changelog", "      Logs", 0.75, drawLogsIcon)

		-- Active Indicator Bar
		local ActiveBar = Instance.new("Frame")
		ActiveBar.Name = "ActiveBar"
		ActiveBar.Size = UDim2.new(0.25, 0, 0, 2)
		ActiveBar.Position = UDim2.new(0, 0, 1, -2)
		ActiveBar.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
		ActiveBar.BorderSizePixel = 0
		ActiveBar.Parent = TabContainer

		-- Content Panel
		local ContentFrame = Instance.new("Frame")
		ContentFrame.Name = "ContentFrame"
		ContentFrame.Size = UDim2.new(1, 0, 1, -80)
		ContentFrame.Position = UDim2.new(0, 0, 0, 80)
		ContentFrame.BackgroundTransparency = 1
		ContentFrame.Parent = MainPanel

		-- 1. Chat Tab Panel
		local ChatPanel = Instance.new("Frame")
		ChatPanel.Name = "ChatPanel"
		ChatPanel.Size = UDim2.new(1, 0, 1, 0)
		ChatPanel.BackgroundTransparency = 1
		ChatPanel.Visible = true
		ChatPanel.Parent = ContentFrame

		local LogBox = Instance.new("ScrollingFrame")
		LogBox.Name = "LogBox"
		LogBox.Size = UDim2.new(1, -20, 1, -65)
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
		ChatInput.Name = "ChatInput"
		ChatInput.Size = UDim2.new(1, -95, 0, 38)
		ChatInput.Position = UDim2.new(0, 10, 1, -48)
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
		SendBtn.Name = "SendBtn"
		SendBtn.Size = UDim2.new(0, 75, 0, 38)
		SendBtn.Position = UDim2.new(1, -85, 1, -48)
		SendBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
		SendBtn.Text = "Send"
		SendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		SendBtn.Font = Enum.Font.GothamBold
		SendBtn.TextSize = 13
		SendBtn.Parent = ChatPanel

		local SendCorner = Instance.new("UICorner")
		SendCorner.CornerRadius = UDim.new(0, 6)
		SendCorner.Parent = SendBtn

		-- 2. Sync Tab Panel
		local SyncPanel = Instance.new("Frame")
		SyncPanel.Name = "SyncPanel"
		SyncPanel.Size = UDim2.new(1, 0, 1, 0)
		SyncPanel.BackgroundTransparency = 1
		SyncPanel.Visible = false
		SyncPanel.Parent = ContentFrame

		local SyncList = Instance.new("Frame")
		SyncList.Name = "SyncList"
		SyncList.Size = UDim2.new(1, -20, 1, -20)
		SyncList.Position = UDim2.new(0, 10, 0, 10)
		SyncList.BackgroundTransparency = 1
		SyncList.Parent = SyncPanel

		local SyncLayout = Instance.new("UIListLayout")
		SyncLayout.Padding = UDim.new(0, 10)
		SyncLayout.Parent = SyncList

		local function makeInfoLabel(name, title, value)
			local frame = Instance.new("Frame")
			frame.Name = name .. "Label"
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
			lblVal.Name = "ValueLabel"
			lblVal.Size = UDim2.new(0.6, 0, 1, 0)
			lblVal.Position = UDim2.new(0.4, 0, 0, 0)
			lblVal.BackgroundTransparency = 1
			lblVal.Text = tostring(value)
			lblVal.TextColor3 = Color3.fromRGB(220, 220, 230)
			lblVal.TextSize = 12
			lblVal.Font = Enum.Font.Gotham
			lblVal.TextXAlignment = Enum.TextXAlignment.Left
			lblVal.Parent = frame
			
			return frame
		end

		makeInfoLabel("PlaceName", "Place Name:", placeName)
		makeInfoLabel("PlaceId", "Place ID:", placeId)
		makeInfoLabel("GameId", "Game ID:", gameId)
		makeInfoLabel("SyncStatus", "Sync Status:", "Idle")
		makeInfoLabel("LastSync", "Last Synced:", lastSyncTime)

		local ForceSyncBtn = Instance.new("TextButton")
		ForceSyncBtn.Name = "ForceSyncBtn"
		ForceSyncBtn.Size = UDim2.new(1, 0, 0, 42)
		ForceSyncBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 120)
		ForceSyncBtn.Text = "Force Git Sync Now"
		ForceSyncBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		ForceSyncBtn.Font = Enum.Font.GothamBold
		ForceSyncBtn.TextSize = 14
		ForceSyncBtn.Parent = SyncList

		local ForceSyncCorner = Instance.new("UICorner")
		ForceSyncCorner.CornerRadius = UDim.new(0, 6)
		ForceSyncCorner.Parent = ForceSyncBtn

		-- 3. Settings Tab Panel
		local SettingsPanel = Instance.new("Frame")
		SettingsPanel.Name = "SettingsPanel"
		SettingsPanel.Size = UDim2.new(1, 0, 1, 0)
		SettingsPanel.BackgroundTransparency = 1
		SettingsPanel.Visible = false
		SettingsPanel.Parent = ContentFrame

		local SettingsList = Instance.new("Frame")
		SettingsList.Name = "SettingsList"
		SettingsList.Size = UDim2.new(1, -20, 1, -20)
		SettingsList.Position = UDim2.new(0, 10, 0, 10)
		SettingsList.BackgroundTransparency = 1
		SettingsList.Parent = SettingsPanel

		local SettingsLayout = Instance.new("UIListLayout")
		SettingsLayout.Padding = UDim.new(0, 10)
		SettingsLayout.Parent = SettingsList

		local function makeInputBlock(name, title, placeholder, defaultValue)
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
			tb.Name = name
			tb.Size = UDim2.new(1, 0, 0, 32)
			tb.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
			tb.PlaceholderText = placeholder
			tb.Text = defaultValue
			tb.TextColor3 = Color3.fromRGB(240, 240, 250)
			tb.TextSize = 12
			tb.Font = Enum.Font.Gotham
			tb.ClearTextOnFocus = false
			tb.Parent = SettingsList

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = tb

			local pad = Instance.new("UIPadding")
			pad.PaddingLeft = UDim.new(0, 8)
			pad.Parent = tb

			return tb
		end

		makeInputBlock("ApiKeyInput", "Google Gemini API Key:", "AI API key...", config.API_Key)
		makeInputBlock("GithubUrlInput", "GitHub Raw Code URL:", "https://raw.githubusercontent.com/...", config.GitHub_URL)

		local modelLbl = Instance.new("TextLabel")
		modelLbl.Size = UDim2.new(1, 0, 0, 15)
		modelLbl.BackgroundTransparency = 1
		modelLbl.Text = "Gemini Model Provider:"
		modelLbl.TextColor3 = Color3.fromRGB(180, 180, 190)
		modelLbl.TextSize = 12
		modelLbl.Font = Enum.Font.GothamBold
		modelLbl.TextXAlignment = Enum.TextXAlignment.Left
		modelLbl.Parent = SettingsList

		-- Models Grid
		local ModelGrid = Instance.new("Frame")
		ModelGrid.Name = "ModelGrid"
		ModelGrid.Size = UDim2.new(1, 0, 0, 72)
		ModelGrid.BackgroundTransparency = 1
		ModelGrid.Parent = SettingsList

		local gridLayout = Instance.new("UIGridLayout")
		gridLayout.CellSize = UDim2.new(0.31, 0, 0, 32)
		gridLayout.CellSpacing = UDim2.new(0.035, 0, 0, 8)
		gridLayout.Parent = ModelGrid

		local function makeModelSelectBtn(modelId, displayName)
			local btn = Instance.new("TextButton")
			btn.Name = modelId
			btn.Text = displayName
			btn.TextColor3 = Color3.fromRGB(180, 180, 190)
			btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
			btn.Font = Enum.Font.GothamBold
			btn.TextSize = 11
			btn.Parent = ModelGrid
			
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = btn
		end

		-- Valid Gemini 3.x Models Selection Grid
		makeModelSelectBtn("gemini-3.5-flash", "3.5 Flash")
		makeModelSelectBtn("gemini-3.1-flash-lite", "3.1 Lite")
		makeModelSelectBtn("gemini-3-flash", "3 Flash")
		makeModelSelectBtn("gemini-3-flash-preview", "3 Preview")
		makeModelSelectBtn("custom", "✏️ Custom")

		local customModelInput = Instance.new("TextBox")
		customModelInput.Name = "CustomModelInput"
		customModelInput.Size = UDim2.new(1, 0, 0, 32)
		customModelInput.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
		customModelInput.PlaceholderText = "e.g., gemini-3.5-pro-exp"
		customModelInput.Text = config.Custom_Model or ""
		customModelInput.TextColor3 = Color3.fromRGB(240, 240, 250)
		customModelInput.TextSize = 12
		customModelInput.Font = Enum.Font.Gotham
		customModelInput.ClearTextOnFocus = false
		customModelInput.Visible = false
		customModelInput.Parent = SettingsList

		local customCorner = Instance.new("UICorner")
		customCorner.CornerRadius = UDim.new(0, 6)
		customCorner.Parent = customModelInput
		
		local customPad = Instance.new("UIPadding")
		customPad.PaddingLeft = UDim.new(0, 8)
		customPad.Parent = customModelInput

		-- Auto Sync Toggle Button
		local SyncToggleBtn = Instance.new("TextButton")
		SyncToggleBtn.Name = "SyncToggleBtn"
		SyncToggleBtn.Size = UDim2.new(1, 0, 0, 35)
		SyncToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
		SyncToggleBtn.Text = "Auto-Sync: ENABLED"
		SyncToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		SyncToggleBtn.Font = Enum.Font.GothamBold
		SyncToggleBtn.TextSize = 13
		SyncToggleBtn.Parent = SettingsList

		local SyncToggleCorner = Instance.new("UICorner")
		SyncToggleCorner.CornerRadius = UDim.new(0, 6)
		SyncToggleCorner.Parent = SyncToggleBtn

		-- Save Button
		local SaveBtn = Instance.new("TextButton")
		SaveBtn.Name = "SaveBtn"
		SaveBtn.Size = UDim2.new(1, 0, 0, 35)
		SaveBtn.BackgroundColor3 = Color3.fromRGB(220, 150, 0)
		SaveBtn.Text = "Save Config"
		SaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		SaveBtn.Font = Enum.Font.GothamBold
		SaveBtn.TextSize = 13
		SaveBtn.Parent = SettingsList

		local SaveCorner = Instance.new("UICorner")
		SaveCorner.CornerRadius = UDim.new(0, 6)
		SaveCorner.Parent = SaveBtn

		-- 4. Changelog Tab Panel
		local ChangelogPanel = Instance.new("Frame")
		ChangelogPanel.Name = "ChangelogPanel"
		ChangelogPanel.Size = UDim2.new(1, 0, 1, 0)
		ChangelogPanel.BackgroundTransparency = 1
		ChangelogPanel.Visible = false
		ChangelogPanel.Parent = ContentFrame

		local ChangelogScroll = Instance.new("ScrollingFrame")
		ChangelogScroll.Size = UDim2.new(1, -20, 1, -20)
		ChangelogScroll.Position = UDim2.new(0, 10, 0, 10)
		ChangelogScroll.BackgroundTransparency = 1
		ChangelogScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		ChangelogScroll.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
		ChangelogScroll.Parent = ChangelogPanel

		local ChangelogLayout = Instance.new("UIListLayout")
		ChangelogLayout.Padding = UDim.new(0, 12)
		ChangelogLayout.Parent = ChangelogScroll

		local function makeChangelogEntry(versionStr, changesList)
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(1, 0, 0, 0)
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
			frame.BorderSizePixel = 0
			frame.Parent = ChangelogScroll

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = frame

			local vlbl = Instance.new("TextLabel")
			vlbl.Size = UDim2.new(1, -10, 0, 20)
			vlbl.Position = UDim2.new(0, 10, 0, 5)
			vlbl.BackgroundTransparency = 1
			vlbl.Text = versionStr
			vlbl.TextColor3 = Color3.fromRGB(0, 200, 255)
			vlbl.TextSize = 13
			vlbl.Font = Enum.Font.GothamBold
			vlbl.TextXAlignment = Enum.TextXAlignment.Left
			vlbl.Parent = frame

			local changesStr = ""
			for _, item in ipairs(changesList) do
				changesStr = changesStr .. "• " .. item .. "\n"
			end

			local textlbl = Instance.new("TextLabel")
			textlbl.Size = UDim2.new(1, -20, 0, 0)
			textlbl.Position = UDim2.new(0, 10, 0, 28)
			textlbl.AutomaticSize = Enum.AutomaticSize.Y
			textlbl.BackgroundTransparency = 1
			textlbl.Text = changesStr
			textlbl.TextColor3 = Color3.fromRGB(200, 200, 210)
			textlbl.TextSize = 11
			textlbl.Font = Enum.Font.Gotham
			textlbl.TextXAlignment = Enum.TextXAlignment.Left
			textlbl.TextWrapped = true
			textlbl.Parent = frame
			
			local pad = Instance.new("UIPadding")
			pad.PaddingBottom = UDim.new(0, 8)
			pad.Parent = frame
		end

		makeChangelogEntry("v2.4.0 - Corrected 3.x Models", {
			"Removed 1.0, 1.5, 2.0, 2.5 API versions completely.",
			"Added Gemini 3.5 Flash, 3.1 Flash Lite, 3 Flash, and 3 Flash Preview.",
			"Maintained vector Lua graphics and sleek dark UI."
		})
		makeChangelogEntry("v2.3.0 - Vector Graphics & Production Models", {
			"Removed emojis and replaced them with crisp programmatic Lua vector designs.",
			"Implemented an official vector-drawn Lua orbit logo.",
			"Created vector-drawn tab icons (bubble, links, gear, doc) and lightning bolt toggle."
		})
		makeChangelogEntry("v2.2.0 - Client/Server Architecture", {
			"Split server logic and client Tweens completely.",
			"Added responsive animated hover and tactile press states.",
			"Created animated opening and closing transitions."
		})
		makeChangelogEntry("v2.1.0 - Interactive AI & Memory", {
			"Created floating dark-mode UI overlay panel.",
			"Added in-game Gemini AI code generator console.",
			"Added persistence layer saving API keys using DataStores."
		})
		makeChangelogEntry("v1.0.0 - Basic Sync Client", {
			"Implemented basic background GitHub polling sync."
		})

		-- Inject Client-Side Controller (Cloning this script)
		local clientScript = script:Clone()
		clientScript.Enabled = false
		clientScript.Name = "ClientController"
		clientScript.RunContext = Enum.RunContext.Client
		clientScript.Parent = ScreenGui
		clientScript.Enabled = true

		-- Send Initial Configuration
		task.defer(function()
			SyncEvent:FireClient(player, "UpdateConfig", config)
			SyncEvent:FireClient(player, "UpdateSyncStats", {
				status = config.Sync_Enabled and "Syncing..." or "Disabled",
				color = config.Sync_Enabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 80, 80),
				lastSync = lastSyncTime
			})
		end)
	end

	-- Bind to Player Joins
	Players.PlayerAdded:Connect(buildUI)
	for _, p in ipairs(Players:GetPlayers()) do
		buildUI(p)
	end

	-- Send Log Updates to All Clients
	local function logToClients(msg, color)
		SyncEvent:FireAllClients("Log", msg, color)
	end

	-- Network Message Listener
	SyncEvent.OnServerEvent:Connect(function(player, action, data)
		if action == "SaveConfig" then
			config.API_Key = data.API_Key
			config.GitHub_URL = data.GitHub_URL
			config.Model = data.Model
			config.Custom_Model = data.Custom_Model
			
			pcall(function()
				if configStore then
					configStore:SetAsync("Config", config)
				end
			end)
			
			logToClients("[System] Settings configuration updated.", Color3.fromRGB(240, 200, 50))
			SyncEvent:FireAllClients("UpdateConfig", config)
		elseif action == "ToggleSync" then
			config.Sync_Enabled = data
			pcall(function()
				if configStore then
					configStore:SetAsync("Config", config)
				end
			end)
			
			logToClients("[System] Auto-Sync toggled: " .. (config.Sync_Enabled and "ENABLED" or "DISABLED"), Color3.fromRGB(240, 200, 50))
			SyncEvent:FireAllClients("UpdateSyncStats", {
				status = config.Sync_Enabled and "Syncing..." or "Disabled",
				color = config.Sync_Enabled and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 80, 80),
				lastSync = lastSyncTime
			})
		elseif action == "SendChat" then
			logToClients(player.Name .. ": " .. data, Color3.fromRGB(150, 220, 255))
			logToClients("AI Co-pilot: Generating Lua script...", Color3.fromRGB(200, 180, 100))

			task.spawn(function()
				local success, result = askGemini(data)
				if success then
					logToClients("AI Co-pilot: Executing code...", Color3.fromRGB(100, 220, 150))
					
					local runSuccess, runError = pcall(function()
						local func = loadstring(result)
						if func then
							task.spawn(func)
						else
							error("Syntax error in generated Lua code.")
						end
					end)

					if runSuccess then
						logToClients("AI Co-pilot: Code executed successfully!", Color3.fromRGB(0, 255, 120))
					else
						logToClients("Execution Error: " .. tostring(runError), Color3.fromRGB(255, 100, 100))
					end
				else
					logToClients("AI Error: " .. result, Color3.fromRGB(255, 100, 100))
				end
			end)
		elseif action == "ForceSync" then
			logToClients("[System] Force git sync triggered.", Color3.fromRGB(0, 200, 255))
			lastGitHubCode = ""
		end
	end)

	-- GitHub Auto-Sync Loop
	task.spawn(function()
		while true do
			if config.Sync_Enabled and config.GitHub_URL and config.GitHub_URL ~= "" then
				local success, response = pcall(function()
					return HttpService:GetAsync(config.GitHub_URL .. "?t=" .. tostring(os.time()))
				end)

				if success and response then
					if response ~= lastGitHubCode then
						lastGitHubCode = response
						lastSyncTime = os.date("%H:%M:%S")
						
						logToClients("[Sync] New code fetched from GitHub! Running...", Color3.fromRGB(130, 80, 255))

						local runSuccess, runError = pcall(function()
							local func = loadstring(response)
							if func then
								task.spawn(func)
							else
								error("Syntax error in downloaded GitHub script.")
							end
						end)

						if not runSuccess then
							logToClients("[Sync Error] Failed execution: " .. tostring(runError), Color3.fromRGB(255, 80, 80))
						else
							logToClients("[Sync Success] GitHub code ran successfully!", Color3.fromRGB(0, 255, 120))
						end
						
						SyncEvent:FireAllClients("UpdateSyncStats", {
							status = "Synced",
							color = Color3.fromRGB(0, 255, 120),
							lastSync = lastSyncTime
						})
					end
				else
					SyncEvent:FireAllClients("UpdateSyncStats", {
						status = "Fetch Error",
						color = Color3.fromRGB(255, 80, 80),
						lastSync = lastSyncTime
					})
				end
			end
			task.wait(config.Sync_Interval)
		end
	end)
end
