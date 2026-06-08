# Roblox Studio Lite Co-Pilot & Sync System (MCP + GitHub) — v2.3.0

This project turns your Roblox Studio Lite (mobile studio or PC Studio) into an interactive AI-assisted game development environment. It combines **GitHub Auto-Sync** and **In-game Gemini AI Co-pilot Chat** with advanced vector-drawn UI animations.

---

## 🌟 Features

### 1. In-game Gemini Co-pilot (Chat)
*   Type commands (e.g. `"make a green neon stairs"` or `"workspace'e bir araba yerleştir"`) directly into the in-game console.
*   The system sends your prompt to Google's Gemini models, returns raw Lua code, and instantly runs it in-game.

### 2. Supported Google Gemini Models
Easily select the model provider in the Settings grid:
*   **Gemini 2.5 Flash** (Default, very fast and accurate)
*   **Gemini 2.5 Pro** (Excellent reasoning for complex coding)
*   **Gemini 2.0 Flash**
*   **Gemini 2.0 Pro**
*   **Gemini 1.5 Flash**
*   **Custom Model**: Provide a custom model override text name (e.g., `gemini-1.5-pro-latest` or experimental models).

### 3. Dynamic GitHub Sync
*   Write code in `src/main.lua` of this repository, commit/push, and the script instantly runs in your active Roblox game playtest without restarts.

### 4. Advanced Smooth UI (Client/Server Hybrid)
*   **Programmatic Vector UI**: Removed emojis. The header renders a clean vector representation of the official Lua logo. The tabs render crisp vector shapes: Speech Bubble (Chat), Linked Rings (Sync), Gear Wheel (Settings), and Document Sheet (Logs).
*   **Tactile Hover & Clicks**: Buttons smoothly scale up and glow when hovered, shrinking slightly on click.
*   **Elastic Panel Open/Close**: Clicking the ⚡ button triggers an elastic scaling transition.
*   **Tabs Transition**: Seamlessly switch between Chat, Sync, Settings, and Logs.
*   **Unified State Bridge**: Multi-developer sync allows everyone in the game to see logs and configurations updated in real-time.

### 5. Changelog / Log Viewer
*   A dedicated **Logs (📜)** tab listing version updates, changes, and historical updates.

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
2. Copy the entire contents of [loader.lua](file:///data/data/com.termux/files/home/roblox-studio-lite-sync/loader.lua) and paste it into the script.
3. Start the game (Play/Test).

---

## 🚀 How to Use

### 1. Configure the API Key
1. When you join, click the **⚡ button** in the bottom-right corner.
2. Navigate to the **Config (⚙️)** tab.
3. Paste your Google Gemini API key (Get a free one at [Google AI Studio](https://aistudio.google.com/)).
4. Select one of the **Gemini 2.5/2.0/1.5** models or select **Custom** and type a specific model ID.
5. Click **Save Config**.

### 2. Auto-Sync Setup
*   Your loader automatically polls the raw URL for `src/main.lua`. You can change the URL in the Settings config to match your custom repository if you fork this project.
*   Toggle auto-sync on/off directly from the settings interface.
