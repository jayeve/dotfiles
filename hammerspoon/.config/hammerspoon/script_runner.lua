-- ~/.config/hammerspoon/script_runner.lua
-- Script runner module for launching floating terminal with fzf script selector

local M = {}
local home = os.getenv("HOME")
local windowWatcher = nil

-- Helper function to shell quote strings
local function shQuote(s)
	return "'" .. tostring(s):gsub("'", [['"'"']]) .. "'"
end

-- Load configuration from JSON file
function M.loadConfig()
	local configPath = home .. "/.config/script-runner-hotkeys.json"
	local file = io.open(configPath, "r")

	if not file then
		hs.alert.show("Script runner config not found: " .. configPath, 2)
		return {}
	end

	local content = file:read("*all")
	file:close()

	local success, config = pcall(hs.json.decode, content)
	if not success then
		hs.alert.show("Error parsing script runner config", 2)
		return {}
	end

	return config
end

-- Create temporary Alacritty config with position and dimensions
-- This prevents the window resize blip by telling Alacritty where to appear
function M.createTempConfig(x, y, cols, lines)
	local tempConfigPath = "/tmp/alacritty-script-runner.toml"
	local mainConfigPath = home .. "/.config/alacritty/alacritty.toml"
	
	-- Build TOML config content
	local configContent = string.format([[
# Temporary Alacritty config for script runner
# Import main config to inherit all settings
import = ["%s"]

# Override window position and dimensions for floating window
[window]
position = { x = %d, y = %d }
dimensions = { columns = %d, lines = %d }
]], mainConfigPath, x, y, cols, lines)
	
	-- Write to temp file
	local file = io.open(tempConfigPath, "w")
	if not file then
		hs.alert.show("Failed to create temp Alacritty config", 1.5)
		return nil
	end
	
	file:write(configContent)
	file:close()
	
	return tempConfigPath
end

-- Position and style the floating window
function M.positionWindow(win)
	if not win then
		return
	end

	-- Get main screen frame
	local screen = win:screen() or hs.screen.mainScreen()
	local frame = screen:frame()

	-- Calculate centered position (50% width, 60% height)
	local width = frame.w * 0.5
	local height = frame.h * 0.6
	local x = frame.x + (frame.w - width) / 2
	local y = frame.y + (frame.h - height) / 2

	-- Set window frame
	win:setFrame({ x = x, y = y, w = width, h = height }, 0)

	-- Focus the window
	win:focus()
end

-- Watch for script-runner window to appear and position it
function M.watchForWindow()
	-- Only create watcher once, reuse it for subsequent calls
	if windowWatcher then
		return -- Already watching
	end

	-- Create window filter for Alacritty windows with "Script Runner" title
	local filter = hs.window.filter.new(false)
	filter:setAppFilter("Alacritty", { allowTitles = "^Script Runner" })

	-- Watch for window creation
	windowWatcher = filter:subscribe(hs.window.filter.windowCreated, function(win, appName, event)
		-- Position immediately to avoid visible resize
		M.positionWindow(win)
	end)
end

-- Launch Alacritty with the script runner wrapper
function M.launchScriptRunner(directory, name, description)
	if not directory or directory == "" then
		hs.alert.show("Error: No directory specified", 1.5)
		return
	end

	-- Expand home directory if needed
	directory = directory:gsub("^~", home)
	name = name or "Scripts"
	description = description or ""

	-- Check if directory exists
	local dirCheck = io.open(directory .. "/.", "r")
	if not dirCheck then
		hs.alert.show("Directory not found: " .. directory, 2)
		return
	end
	dirCheck:close()

	-- Path to wrapper script
	local wrapperScript = home .. "/dotfiles.git/master/scripts/.config/scripts/script-runner-wrapper.sh"

	-- Calculate desired window dimensions and position (50% width, 60% height, centered)
	local screen = hs.screen.mainScreen()
	local frame = screen:frame()
	
	-- Font metrics for JetBrainsMono at 16pt
	local charWidth = 9.6  -- More accurate than 8px
	local lineHeight = 19.2  -- More accurate than 16px
	local windowPadding = 4  -- Alacritty adds padding around terminal grid
	
	-- Calculate dimensions in characters
	local cols = math.floor((frame.w * 0.5) / charWidth)
	local lines = math.floor((frame.h * 0.6) / lineHeight)
	
	-- Calculate actual window size in pixels (grid + padding)
	local actualWidth = (cols * charWidth) + (windowPadding * 2)
	local actualHeight = (lines * lineHeight) + (windowPadding * 2) + 28  -- +28 for title bar
	
	-- Calculate centered position in pixels using actual window size
	local x = math.floor(frame.x + (frame.w - actualWidth) / 2)
	local y = math.floor(frame.y + (frame.h - actualHeight) / 2)
	
	-- Create temp config with position and dimensions
	local tempConfig = M.createTempConfig(x, y, cols, lines)
	if not tempConfig then
		return
	end

	-- Build window title with name and description
	local windowTitle = name
	if description ~= "" then
		windowTitle = name .. " - " .. description
	end

	-- Build Alacritty launch command using temp config
	local cmd = string.format(
		'open -na Alacritty --args --config-file %s -T %s -e %s %s %s %s &',
		shQuote(tempConfig),
		shQuote(windowTitle),
		shQuote(wrapperScript),
		shQuote(directory),
		shQuote(name),
		shQuote(description)
	)

	-- Launch Alacritty (window will appear at correct position immediately)
	local ok, _, _, rc = hs.execute(cmd)
	if not ok or rc ~= 0 then
		hs.alert.show("Failed to launch script runner", 1.5)
	end
end

-- Launch audio output selector in floating window
function M.launchAudioOutputSelector()
	local wrapperScript = home .. "/dotfiles.git/master/scripts/.config/scripts/audio-output-selector.sh"

	-- Calculate desired window dimensions and position (40% width, 50% height, centered)
	local screen = hs.screen.mainScreen()
	local frame = screen:frame()
	
	-- Font metrics for JetBrainsMono at 16pt
	local charWidth = 9.6
	local lineHeight = 19.2
	local windowPadding = 4
	
	-- Calculate dimensions in characters
	local cols = math.floor((frame.w * 0.4) / charWidth)
	local lines = math.floor((frame.h * 0.5) / lineHeight)
	
	-- Calculate actual window size in pixels (grid + padding)
	local actualWidth = (cols * charWidth) + (windowPadding * 2)
	local actualHeight = (lines * lineHeight) + (windowPadding * 2) + 28
	
	-- Calculate centered position in pixels using actual window size
	local x = math.floor(frame.x + (frame.w - actualWidth) / 2)
	local y = math.floor(frame.y + (frame.h - actualHeight) / 2)
	
	-- Create temp config with position and dimensions
	local tempConfig = M.createTempConfig(x, y, cols, lines)
	if not tempConfig then
		return
	end

	-- Build Alacritty launch command using temp config
	local cmd = string.format(
		'open -na Alacritty --args --config-file %s -T "Script Runner" -e %s &',
		shQuote(tempConfig),
		shQuote(wrapperScript)
	)

	-- Launch Alacritty (window will appear at correct position immediately)
	local ok, _, _, rc = hs.execute(cmd)
	if not ok or rc ~= 0 then
		hs.alert.show("Failed to launch audio output selector", 1.5)
	end
end

-- Launch audio input selector in floating window
function M.launchAudioInputSelector()
	local wrapperScript = home .. "/dotfiles.git/master/scripts/.config/scripts/audio-input-selector.sh"

	-- Calculate desired window dimensions and position (40% width, 50% height, centered)
	local screen = hs.screen.mainScreen()
	local frame = screen:frame()
	
	-- Font metrics for JetBrainsMono at 16pt
	local charWidth = 9.6
	local lineHeight = 19.2
	local windowPadding = 4
	
	-- Calculate dimensions in characters
	local cols = math.floor((frame.w * 0.4) / charWidth)
	local lines = math.floor((frame.h * 0.5) / lineHeight)
	
	-- Calculate actual window size in pixels (grid + padding)
	local actualWidth = (cols * charWidth) + (windowPadding * 2)
	local actualHeight = (lines * lineHeight) + (windowPadding * 2) + 28
	
	-- Calculate centered position in pixels using actual window size
	local x = math.floor(frame.x + (frame.w - actualWidth) / 2)
	local y = math.floor(frame.y + (frame.h - actualHeight) / 2)
	
	-- Create temp config with position and dimensions
	local tempConfig = M.createTempConfig(x, y, cols, lines)
	if not tempConfig then
		return
	end

	-- Build Alacritty launch command using temp config
	local cmd = string.format(
		'open -na Alacritty --args --config-file %s -T "Script Runner" -e %s &',
		shQuote(tempConfig),
		shQuote(wrapperScript)
	)

	-- Launch Alacritty (window will appear at correct position immediately)
	local ok, _, _, rc = hs.execute(cmd)
	if not ok or rc ~= 0 then
		hs.alert.show("Failed to launch audio input selector", 1.5)
	end
end

-- Initialize the watcher when module loads
function M.init()
	M.watchForWindow()
end

return M
