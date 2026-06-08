# Roblox Studio Lite Sync System

This repository dynamically syncs Lua script updates written here directly to your Roblox Studio Lite game.

## Configuration & Usage

### 1. Enable HttpService and Loadstring in Roblox Studio
For this system to work, you must enable these settings in your Roblox game:
*   **HttpService**: Run this command in your Roblox Studio command bar:
    ```lua
    game:GetService("HttpService").HttpEnabled = true
    ```
    *(Or turn on "Allow HTTP Requests" in Game Settings > Security)*
*   **Loadstring**: Select `ServerScriptService` in the Explorer, and in the Properties window, make sure **`LoadstringEnabled`** is checked (`true`).

### 2. Add the Loader Script
1. In Roblox Studio, add a new `Script` inside `ServerScriptService`.
2. Paste the contents of `loader.lua` into this script.
3. Start the game (Play Solo).

### 3. How to Update Code
1. Edit the file `src/main.lua` in this folder.
2. Commit and push the changes to GitHub.
3. The loader inside Roblox Studio Lite will automatically detect the changes within 3 seconds, fetch the new code, and run it instantly without you having to restart the game!
