-- Roblox Studio Lite loader script
-- Place this inside a Script in ServerScriptService

local HttpService = game:GetService("HttpService")

local RAW_URL = "https://raw.githubusercontent.com/Baran3575/roblox-studio-lite-sync/main/src/main.lua"
local CHECK_INTERVAL = 3 -- Seconds between checks

local lastCode = ""

print("[Sync] Sync system started! Checking for updates every " .. tostring(CHECK_INTERVAL) .. " seconds...")

while true do
    local success, response = pcall(function()
        -- Append a random query parameter to prevent Roblox caching the request
        return HttpService:GetAsync(RAW_URL .. "?t=" .. tostring(os.time()))
    end)
    
    if success and response then
        if response ~= lastCode then
            lastCode = response
            print("[Sync] New code detected! Running update...")
            
            -- Make sure loadstring is enabled in ServerScriptService properties!
            local runSuccess, runError = pcall(function()
                local func = loadstring(response)
                if func then
                    task.spawn(func)
                else
                    error("Syntax error in downloaded code.")
                end
            end)
            
            if not runSuccess then
                warn("[Sync] Error running code: " .. tostring(runError))
            else
                print("[Sync] Code executed successfully!")
            end
        end
    else
        warn("[Sync] Failed to fetch code: " .. tostring(response))
    end
    
    task.wait(CHECK_INTERVAL)
end
