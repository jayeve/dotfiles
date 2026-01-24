-- ~/.config/hammerspoon/hotkeys.lua
local sound = require("sound")
local profiles = require("profiles")

-- configured at https://github.com/jayeve/dotfiles/blob/2b1de320aeb019aad64f98fbb3f3863361efb9b3/.config/karabiner/karabiner.json#L9
local hyper = { "ctrl", "alt", "shift", "cmd" }

hs.hotkey.bind(hyper, "a", function()
	hs.application.launchOrFocus(Apps.alacritty)
end)
-- hs.hotkey.bind(hyper, "k", function()
-- 	hs.application.launchOrFocusByBundleID(PWA_Aps.google_messages)
-- end)
hs.hotkey.bind(hyper, "k", function()
	hs.application.launchOrFocus(Apps.googlechat)

	-- small delay so the app is actually frontmost before typing
	hs.timer.doAfter(0.12, function()
		hs.eventtap.keyStroke({ "cmd", "shift" }, "k", 0)
	end)
end)
hs.hotkey.bind(hyper, "s", function()
	hs.application.launchOrFocus(Apps.spotify)
end)

-- Hotkey: Hyper + I
hs.hotkey.bind(hyper, "i", sound.pickInputDevice)
-- Bind to Hyper+O
hs.hotkey.bind(hyper, "o", sound.pickOutputDevice)

-- Hotkey to toggle Accessibility (Virtual) Keyboard using existing AppleScript

local home = os.getenv("HOME")
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
hs.hotkey.bind(hyper, "1", function()
	profiles.applyProfile("work")
end)
-- Hotkey: Hyper + 2 -> study
hs.hotkey.bind(hyper, "2", function()
	profiles.applyProfile("study")
end)
-- Hotkey: Hyper + 3 -> play
hs.hotkey.bind(hyper, "3", function()
	profiles.applyProfile("play")
end)
