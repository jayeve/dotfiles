-- ~/.config/hammerspoon/hotkeys.lua
local sound = require("sound")
local profiles = require("profiles")
local tmux = require("tmux")
local home = os.getenv("HOME")

-- configured at https://github.com/jayeve/dotfiles/blob/2b1de320aeb019aad64f98fbb3f3863361efb9b3/.config/karabiner/karabiner.json#L9
local hyper = { "ctrl", "alt", "shift", "cmd" }

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

-- Hotkey: Hyper + I
hs.hotkey.bind(hyper, "i", sound.pickInputDevice)
-- Bind to Hyper+O
hs.hotkey.bind(hyper, "o", sound.pickOutputDevice)

-- Hotkey to toggle Accessibility (Virtual) Keyboard using existing AppleScript
local scriptPath = home .. "/.config/macos-automations/ToggleAccessibilityKeyboard.scpt"

hs.hotkey.bind(hyper, "v", function()
	local cmd = string.format('osascript "%s"', scriptPath)
	local ok, _, _, rc = hs.execute(cmd)

	if not ok or rc ~= 0 then
		hs.alert.show("Failed to toggle virtual keyboard", 1.2)
	end
end)

-- profiles

-- Hotkey: Hyper + 1 -> work
hs.hotkey.bind(hyper, "9", function()
	profiles.applyProfile("work")
end)
-- Hotkey: Hyper + 2 -> study
hs.hotkey.bind(hyper, "8", function()
	profiles.applyProfile("study")
end)
-- Hotkey: Hyper + 3 -> play
hs.hotkey.bind(hyper, "7", function()
	profiles.applyProfile("play")
end)

-- Tmux hotkeys

-- Hyper+T enters a "tmux sessions" layer; next key chooses a session.
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

tmuxMode:bind("", "f", function()
	tmux.target_session(Locations.fl2[1], Locations.fl2[2])
	tmuxMode:exit()
end)
tmuxMode:bind("", "x", function()
	tmux.target_session(Locations.scratch[1], Locations.scratch[2])
	tmuxMode:exit()
end)
tmuxMode:bind("", "o", function()
	tmux.target_session(Locations.opencode[1], Locations.opencode[2])
	tmuxMode:exit()
end)
tmuxMode:bind("", "c", function()
	tmux.target_session(Locations.cache_indexer[1], Locations.ssl_detector[2])
	tmuxMode:exit()
end)
tmuxMode:bind("", "s", function()
	tmux.target_session(Locations.ssl_detector[1], Locations.ssl_detector[2])
	tmuxMode:exit()
end)
tmuxMode:bind("", "d", function()
	tmux.target_session(Locations.dotfiles[1], Locations.dotfiles[2])
	tmuxMode:exit()
end)
tmuxMode:bind("", "p", function()
	tmux.target_session(Locations.pingora_origin[1], Locations.pingora_origin[2])
	tmuxMode:exit()
end)
tmuxMode:bind("", "escape", function()
	resetTimer()
	tmuxMode:exit()
end)

hs.hotkey.bind(hyper, "5", function()
	tmux.target_session(Locations.dotfiles[1], Locations.dotfiles[2])
end)
hs.hotkey.bind(hyper, "tab", function()
	tmux.fzf_tmux_sessions("dotfiles", (home .. "/dotfiles"))
end)
