-- ~/.config/hammerspoon/hotkeys.lua
local audio = require("audio")
local window_manager = require("window_manager")
local tmux = require("tmux")
local home = os.getenv("HOME")
local dotfiles_repo = home .. "/dotfiles.git"

-- configured at https://github.com/jayeve/dotfiles/blob/2b1de320aeb019aad64f98fbb3f3863361efb9b3/.config/karabiner/karabiner.json#L9
local hyper = { "ctrl", "alt", "shift", "cmd" }

-- replaces Rectangle
hs.hotkey.bind({ "ctrl", "alt" }, "h", function()
	window_manager.snapLeft()
end)

hs.hotkey.bind({ "ctrl", "alt" }, "l", function()
	window_manager.snapRight()
end)

hs.hotkey.bind({ "ctrl", "alt" }, "j", function()
	window_manager.snapBottom()
end)

hs.hotkey.bind({ "ctrl", "alt" }, "k", function()
	window_manager.snapTop()
end)

hs.hotkey.bind({ "ctrl", "alt" }, "u", window_manager.snapTopLeft)
hs.hotkey.bind({ "ctrl", "alt" }, "i", window_manager.snapTopRight)
hs.hotkey.bind({ "ctrl", "alt" }, "n", window_manager.snapBottomLeft)
hs.hotkey.bind({ "ctrl", "alt" }, "m", window_manager.snapBottomRight)

hs.hotkey.bind({ "ctrl", "alt" }, "return", function()
	local win = hs.window.focusedWindow()
	if not win then
		return
	end

	local f = win:screen():frame()
	win:setFrame(f, 0) -- 0 = no animation
end)

hs.hotkey.bind({}, "pagedown", function()
	hs.eventtap.keyStroke({ "cmd", "ctrl" }, "q", 0)
end)
hs.hotkey.bind(hyper, "l", function()
	hs.application.launchOrFocus(Apps.localsend)
end)
hs.hotkey.bind(hyper, "h", function()
	hs.application.launchOrFocus(Apps.googlemeet)
end)
hs.hotkey.bind(hyper, "e", function()
	hs.application.launchOrFocus(Apps.spark)
end)
hs.hotkey.bind(hyper, "r", function()
	hs.application.launchOrFocus(Apps.anki)
end)
hs.hotkey.bind(hyper, "w", function()
	hs.application.launchOrFocus(Apps.whatsapp)
end)
hs.hotkey.bind(hyper, "1", function()
	hs.application.launchOrFocus(Apps.onepassword)
end)
hs.hotkey.bind(hyper, "c", function()
	hs.application.launchOrFocus(Apps.chatgpt)
end)
hs.hotkey.bind(hyper, "a", function()
	hs.application.launchOrFocus(Apps.alacritty)
end)
hs.hotkey.bind(hyper, "g", function()
	hs.application.launchOrFocus(Apps.chrome)
end)
hs.hotkey.bind(hyper, "m", function()
	hs.application.launchOrFocusByBundleID(PWA_Aps.google_messages)
end)
hs.hotkey.bind(hyper, "k", function()
	hs.application.launchOrFocus(Apps.googlechat)
end)
hs.hotkey.bind(hyper, "q", function()
	hs.application.launchOrFocus(Apps.quicktime)
end)
hs.hotkey.bind(hyper, "s", function()
	hs.application.launchOrFocus(Apps.spotify)
end)
hs.hotkey.bind(hyper, "d", function()
	hs.application.launchOrFocus(Apps.discord)
end)
hs.hotkey.bind(hyper, "t", function()
	hs.application.launchOrFocus(Apps.teams)
end)
hs.hotkey.bind(hyper, "x", function()
	hs.application.launchOrFocus(Apps.googlemaps)
end)
hs.hotkey.bind(hyper, "z", function()
	local url = "https://gitdash.cfdata.org/"

	-- Open URL specifically in Google Chrome
	hs.urlevent.openURLWithBundle(url, "com.google.Chrome")
end)

hs.hotkey.bind(hyper, "2", function()
	local button, text =
		hs.dialog.textPrompt("Translate to Korean", "Enter text to translate:", "", "Translate", "Cancel")

	if button ~= "Translate" or text == "" then
		return
	end

	-- URL encode input
	local encoded = hs.http.encodeForQuery(text)

	local url = string.format("https://translate.google.com/?sl=en&tl=ko&text=%s&op=translate", encoded)

	hs.urlevent.openURL(url)
end)

hs.hotkey.bind(hyper, "3", function()
	local button, text = hs.dialog.textPrompt(
		"Translate to English (from korean)",
		"Enter text to translate:",
		"",
		"Translate",
		"Cancel"
	)

	if button ~= "Translate" or text == "" then
		return
	end

	-- URL encode input
	local encoded = hs.http.encodeForQuery(text)

	local url = string.format("https://translate.google.com/?sl=ko&tl=en&text=%s&op=translate", encoded)

	hs.urlevent.openURL(url)
end)

-- Audio hotkeys
hs.hotkey.bind(hyper, "i", audio.pickInputDevice)

-- Audio output modal
-- Hyper+O enters an "audio output" layer; next key chooses an output device.
local outputMode = hs.hotkey.modal.new(hyper, "o")

function outputMode:entered()
	-- auto-exit after 2s idle
	self._timer = hs.timer.doAfter(2, function()
		outputMode:exit()
	end)
end

function outputMode:exited()
	if self._timer then
		self._timer:stop()
		self._timer = nil
	end
end

local function resetOutputTimer()
	if outputMode._timer then
		outputMode._timer:stop()
		outputMode._timer = hs.timer.doAfter(2, function()
			outputMode:exit()
		end)
	end
end

-- Example output device mappings (customize these with your actual device names)
outputMode:bind("", "h", function()
	local dev = hs.audiodevice.findOutputByName("output_screen_recording_plugged_headphones")
	if dev then
		dev:setDefaultOutputDevice()
		hs.alert.show("🔊 Blackhole + Headphones", 0.8)
	else
		hs.alert.show("❌ Headphones not found", 1.0)
	end
	outputMode:exit()
end)
outputMode:bind("", "j", function()
	local dev = hs.audiodevice.findOutputByName("External Headphones")
	if dev then
		dev:setDefaultOutputDevice()
		hs.alert.show("🔊 External Headphones", 0.8)
	else
		hs.alert.show("❌ Headphones not found", 1.0)
	end
	outputMode:exit()
end)
outputMode:bind("", "s", function()
	-- Example: Switch to built-in speakers
	-- Replace with your actual speaker device name
	local dev = hs.audiodevice.findOutputByName("MacBook Pro Speakers")
	if dev then
		dev:setDefaultOutputDevice()
		hs.alert.show("🔊 Speakers", 0.8)
	else
		hs.alert.show("❌ Speakers not found", 1.0)
	end
	outputMode:exit()
end)
outputMode:bind("", "tab", function()
	-- Open the full chooser list
	audio.pickOutputDevice()
	outputMode:exit()
end)
outputMode:bind("", "escape", function()
	resetOutputTimer()
	outputMode:exit()
end)

-- Hotkey to toggle Accessibility (Virtual) Keyboard using existing AppleScript
local scriptPath = home .. "/.config/scripts/ToggleAccessibilityKeyboard.scpt"

hs.hotkey.bind(hyper, "v", function()
	local cmd = string.format('osascript "%s"', scriptPath)
	local ok, _, _, rc = hs.execute(cmd)

	if not ok or rc ~= 0 then
		hs.alert.show("Failed to toggle virtual keyboard", 1.2)
	end
end)

-- profiles

-- Tmux hotkeys
-- Hyper+T enters a "tmux sessions" layer; next key chooses a session.
-- projects located at /Users/jevans/.config/project-hotkeys.json
local tmuxMode = hs.hotkey.modal.new(hyper, "f")

function tmuxMode:entered()
	-- auto-exit after 2s idle (optional)
	self._timer = hs.timer.doAfter(2, function()
		tmuxMode:exit()
	end)
end

function tmuxMode:exited()
	if self._timer then
		self._timer:stop()
		self._timer = nil
	end
end

local function resetTimer()
	if tmuxMode._timer then
		tmuxMode._timer:stop()
		tmuxMode._timer = hs.timer.doAfter(2, function()
			tmuxMode:exit()
		end)
	end
end

-- Load locations from config file
local locations_module = require("locations")
local Locations = locations_module.load(home .. "/.config/project-hotkeys.json")

-- Helper function to safely access location and show error if missing
local function targetLocation(locationName)
	local location = Locations[locationName]
	if not location then
		hs.alert.show("Error: Location '" .. locationName .. "' not found in config", 2)
		return
	end
	-- Replace underscores with dashes in session name
	local sessionName = location[1]:gsub("_", "-")
	tmux.target_session(sessionName, location[2])
end

tmuxMode:bind("", "e", function()
	targetLocation("extractor")
	tmuxMode:exit()
end)
tmuxMode:bind("", "n", function()
	targetLocation("weekly_notes")
	tmuxMode:exit()
end)
tmuxMode:bind("", "m", function()
	targetLocation("personal_notes")
	tmuxMode:exit()
end)
tmuxMode:bind("", "f", function()
	targetLocation("fl2")
	tmuxMode:exit()
end)
tmuxMode:bind("", "x", function()
	targetLocation("scratch")
	tmuxMode:exit()
end)
tmuxMode:bind("", "o", function()
	targetLocation("opencode")
	tmuxMode:exit()
end)
tmuxMode:bind("", "c", function()
	targetLocation("cache_indexer")
	tmuxMode:exit()
end)
tmuxMode:bind("", "s", function()
	targetLocation("ssl_detector")
	tmuxMode:exit()
end)
tmuxMode:bind("", "d", function()
	targetLocation("dotfiles")
	tmuxMode:exit()
end)
tmuxMode:bind("", "p", function()
	targetLocation("pingora_origin")
	tmuxMode:exit()
end)
tmuxMode:bind("", "r", function()
	targetLocation("resources")
	tmuxMode:exit()
end)
tmuxMode:bind("", "escape", function()
	resetTimer()
	tmuxMode:exit()
end)

hs.hotkey.bind(hyper, "5", function()
	targetLocation("dotfiles")
end)
hs.hotkey.bind(hyper, "tab", function()
	tmux.fzf_tmux_sessions("dotfiles", dotfiles_repo)
end)
