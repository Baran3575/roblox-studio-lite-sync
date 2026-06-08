# Roblox Studio Lite Co-Pilot & Sync System (MCP + GitHub) — v2.4.0

This project turns your Roblox Studio Lite (mobile studio or PC Studio) into an interactive AI-assisted game development environment. It combines **GitHub Auto-Sync** and **In-game Gemini AI Co-pilot Chat** with advanced vector-drawn UI animations and **Gemini Function Calling (Tools)** support.

---

## 🌟 Features

### 1. In-game Gemini Co-pilot with Tool Support (In-game MCP)
The AI now has direct access to interact with the Roblox hierarchy and environment. Instead of just sending you instructions or raw code blocks, it can directly execute functions in your game based on your request.
*   **Multi-Turn Agent Loop**: If a complex request requires multiple actions (e.g. creating a folder, then generating a part inside it, then writing a script), the AI will call multiple tools in sequence, execute them on the server, receive the result, and report back.

#### Available AI Tools:
1.  **`create_instance(className, name, parentPath, properties)`**: 
    *   Creates any instance (Part, Model, Folder, etc.) and parent it dynamically.
    *   Safely translates JSON properties to Roblox native types (`Vector3`, `Color3` from RGB arrays, `BrickColor`, and `Enum.Material`).
2.  **`delete_instance(path)`**:
    *   Destroys any object (Part, Folder, Script) at the given path (e.g., `Workspace/OldModel`).
3.  **`write_script(path, source)`**:
    *   Compiles and runs code immediately on the server.
    *   Bypasses Roblox runtime source code limits by spawning the thread in memory (`loadstring`) and storing a read-only script mirror containing the code in a `StringValue` inside the folder structure so it's fully visible and saved in your explorer.
4.  **`list_directory(path)`**:
    *   Lists all children and class names at a path so the AI knows what is currently inside your workspace or hierarchy.

---

### 2. Supported Google Gemini Models
Easily select the model provider in the Settings grid (2x2 Layout):
*   **Gemini 3.5 Flash** (Default, very fast and accurate)
*   **Gemini 3.1 Flash Lite**
*   **Gemini 3 Flash**
*   **Custom Model**: Provide a custom model override text name (e.g., `gemini-3.5-pro-exp` or experimental endpoints).

---

### 3. Dynamic GitHub Sync
*   Write code in `src/main.lua` of this repository, commit/push, and the script instantly runs in your active Roblox game playtest without restarts.

### 4. Advanced Smooth UI (Client/Server Hybrid)
*   **Programmatic Vector UI**: Emojis are replaced by crisp vector shapes: Speech Bubble (Chat), Linked Rings (Sync), Gear Wheel (Settings), and Document Sheet (Logs).
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
4. Select one of the **Gemini 3.5 / 3.1 / 3** models or select **Custom** and type a specific model ID.
5. Click **Save Config**.

### 2. Auto-Sync Setup
*   Your loader automatically polls the raw URL for `src/main.lua`. You can change the URL in the Settings config to match your custom repository if you fork this project.
*   Toggle auto-sync on/off directly from the settings interface.
