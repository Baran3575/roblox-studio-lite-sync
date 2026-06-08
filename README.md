# Roblox Studio Lite Co-Pilot & Sync System (MCP + GitHub)

This project turns your Roblox Studio Lite (mobile studio or PC Studio) into an interactive AI-assisted game development environment. It combines **GitHub Auto-Sync** and **In-game Gemini AI Co-pilot Chat**.

---

## 🌟 Features
1. **Dynamic GitHub Sync**: Write code in `src/main.lua` of this repository, commit/push, and the script instantly runs in your active Roblox game playtest without restarts.
2. **AI Co-pilot Chat UI**: A floating dark-mode UI in Roblox where you can chat with Gemini, ask it to write code, and it runs the code in your workspace instantly!
3. **DataStore Memory**: Your Gemini API Key and custom GitHub Raw URLs are saved using Roblox DataStore so they persist across game sessions.

---

## 🛠️ Setup Instructions for Roblox Studio Lite

### Step 1: Enable Necessary Security Settings
To allow communication between Roblox, Gemini, and GitHub, you must enable these settings:
*   **HttpService (Allow HTTP Requests)**: 
    *   Open your game settings (Game Settings > Security).
    *   Turn on **Allow HTTP Requests**.
    *   *(Alternatively, run `game:GetService("HttpService").HttpEnabled = true` in the Roblox Command Bar).*
*   **Loadstring (Execute Dynamic Code)**:
    *   In the Explorer, click on **ServerScriptService**.
    *   In the Properties window, check the box for **`LoadstringEnabled`** (`true`).

### Step 2: Install the Loader Script
1. In the Explorer, add a new **`Script`** inside **`ServerScriptService`**.
2. Copy the entire contents of [loader.lua](file:///data/data/com.termux/files/home/roblox-studio-lite-sync/loader.lua) (from this repository) and paste it into the script.
3. Start the game (Play/Test).

---

## 🚀 How to Use

### 1. In-Game AI Co-Pilot (Chat)
1. When you join the game, you will see a floating **⚡ button** in the bottom-right corner. Click it to open the panel.
2. Go to the **Settings (⚙️)** tab:
   *   Enter your **Gemini API Key**. (Get one for free at [Google AI Studio](https://aistudio.google.com/)).
   *   *(Optional)* Enter your GitHub raw URL if you are using a different repository.
   *   Click **Save Config**.
3. Go back to the **AI Chat (💬)** tab:
   *   Type a command (e.g., `"workspace'e 10 tane kırmızı dönen küre ekle"` or `"create a giant neon staircase in front of me"`).
   *   Press Enter or click **Send**.
   *   The Gemini AI will generate the Lua code, print a confirmation, and execute the code live in the game!

### 2. GitHub Syncing
*   Any code written in `src/main.lua` will be automatically executed in your Roblox game within 3 seconds of being pushed to the `main` branch of this repository.
*   You can toggle auto-sync on/off in the **Settings** tab.
