-- ~/.config/hammerspoon/hotkeys.lua
local sound = require("sound")
local profiles = require("profiles")

-- configured at https://github.com/jayeve/dotfiles/blob/2b1de320aeb019aad64f98fbb3f3863361efb9b3/.config/karabiner/karabiner.json#L9
local hyper = { "ctrl", "alt", "shift", "cmd" }

hs.hotkey.bind(hyper, "j", function()
	hs.application.launchOrFocus(Apps.anki)
end)

hs.hotkey.bind(hyper, "p", function()
	hs.application.launchOrFocusByBundleID(PWA_Aps.google_messages)
end)

hs.hotkey.bind(hyper, "u", function()
	hs.application.launchOrFocus(Apps.spark)
end)

hs.hotkey.bind(hyper, "l", function()
	hs.application.launchOrFocus(Apps.slack)
end)

hs.hotkey.bind(hyper, "m", function()
	hs.application.launchOrFocus(Apps.meet)
end)

hs.hotkey.bind(hyper, "f", function()
	hs.application.launchOrFocus(Apps.chatgpt)
end)

hs.hotkey.bind(hyper, "c", function()
	hs.application.launchOrFocus(Apps.googlechat)
end)

hs.hotkey.bind(hyper, "d", function()
	hs.application.launchOrFocus(Apps.discord)
end)

hs.hotkey.bind(hyper, "q", function()
	hs.application.launchOrFocus(Apps.quicktime)
end)

hs.hotkey.bind(hyper, "a", function()
	hs.application.launchOrFocus(Apps.alacritty)
end)

hs.hotkey.bind(hyper, "g", function()
	hs.application.launchOrFocus(Apps.chrome)
end)

hs.hotkey.bind(hyper, "w", function()
	hs.application.launchOrFocus(Apps.whatsapp)
end)

hs.hotkey.bind(hyper, "s", function()
	hs.application.launchOrFocus(Apps.spotify)
end)

hs.hotkey.bind(hyper, "t", function()
	Translate.translateSelection("ko", "en")
end)

-- Hyper + 4 -> Google Translate selected text (KO->EN)
hs.hotkey.bind(hyper, "4", function()
	Translate.translateSelection("en", "ko")
end)

-- Hyper + 5 -> Google Translate selected text (AR->EN)
hs.hotkey.bind(hyper, "5", function()
	Translate.translateSelection("en", "ar")
end)

-- Hotkey: Hyper + I
hs.hotkey.bind(hyper, "i", sound.pickInputDevice)
-- Bind to Hyper+O
hs.hotkey.bind(hyper, "o", sound.pickOutputDevice)

-- Hotkey to toggle Accessibility (Virtual) Keyboard using existing AppleScript
local scriptPath = "/Users/jevans/.config/macos-automations/ToggleAccessibilityKeyboard.scpt"

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
