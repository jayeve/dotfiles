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

function M.createTempConfig()
	local tempConfigPath = "/tmp/alacritty-script-runner.toml"
	local mainConfigPath = home .. "/.config/alacritty/alacritty.toml"

	-- Build TOML config content
	local configContent = string.format(
		[[
        # Temporary Alacritty config for script runner
        # Import main config to inherit all settings
        import = ["%s"]

        [window.padding]
        x = 2
        y = 2
        [window]
        opacity = 0.8
        blur = true
    ]],
		mainConfigPath
	)

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

-- Watch for script-runner window to appear and position it
function M.watchForWindow()
	-- Only create watcher once, reuse it for subsequent calls
	if windowWatcher then
		return -- Already watching
	end

	-- Create window filter for Alacritty windows with "Script Runner" title
	local filter = hs.window.filter.new(false)
	filter:setAppFilter("Alacritty", { allowTitles = "^Script Runner" })
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

	local tempConfig = M.createTempConfig()
	if not tempConfig then
		return
	end

	-- Build Alacritty launch command using temp config
	local cmd = string.format(
		"open -na Alacritty --args --config-file %s -T %s -e %s %s %s %s &",
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

	-- Create temp config with position and dimensions
	local tempConfig = M.createTempConfig()
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

	-- Create temp config with position and dimensions
	local tempConfig = M.createTempConfig()
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
