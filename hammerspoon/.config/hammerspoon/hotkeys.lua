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
hs.hotkey.bind({ "shift" }, "pageup", hs.reload)
hs.hotkey.bind({ "shift" }, "pagedown", function()
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

local sparkHotkeys = {}

-- Define hotkeys but DO NOT enable them yet
sparkHotkeys.archive = hs.hotkey.new({ "ctrl" }, "j", nil, function()
	hs.eventtap.keyStroke({ "cmd", "ctrl" }, "a", 0)
end)
sparkHotkeys.delete = hs.hotkey.new({ "ctrl" }, "d", nil, function()
	hs.eventtap.keyStroke({ "cmd" }, "delete", 0)
end)
sparkHotkeys.forward = hs.hotkey.new({ "ctrl" }, "f", nil, function()
	hs.eventtap.keyStroke({ "cmd", "shift" }, "f", 0)
end)
sparkHotkeys.move = hs.hotkey.new({ "ctrl" }, "m", nil, function()
	hs.eventtap.keyStroke({ "cmd", "shift" }, "m", 0)
end)
sparkHotkeys.pin = hs.hotkey.new({ "ctrl" }, "p", nil, function()
	hs.eventtap.keyStroke({ "cmd", "shift" }, "p", 0)
end)
sparkHotkeys.spam = hs.hotkey.new({ "ctrl" }, "s", function()
	hs.eventtap.keyStroke({ "cmd", "shift" }, "j", 0)
end)

local function enableSparkHotkeys()
	for _, hk in pairs(sparkHotkeys) do
		hk:enable()
	end
end

-- Function to disable Spark hotkeys
local function disableSparkHotkeys()
	for _, hk in pairs(sparkHotkeys) do
		hk:disable()
	end
end

-- hs.hotkey.bind({ "cmd" }, "k", function()
-- 	local app = hs.application.frontmostapplication()
-- 	if app:name() == apps.googlemaps then
-- 		hs.eventtap.keystroke({}, "/")
-- 	end
-- end)
-- Watch for app focus changes
local appWatcher = hs.application.watcher.new(function(appName, event, app)
	if event == hs.application.watcher.activated then
		if app:name() == Apps.spark then
			enableSparkHotkeys()
		else
			disableSparkHotkeys()
		end
	end
end)

appWatcher:start()
disableSparkHotkeys()

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
hs.hotkey.bind(hyper, "p", function()
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

-- Audio hotkeys moved below after script_runner is loaded

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

-- keep chooser alive (avoid garbage collection)
local ankiChooser = nil

local function ankiRequest(action, params)
	local payload = hs.json.encode({
		action = action,
		version = 6,
		params = params or {},
	})

	local status, body, _ = hs.http.post("http://localhost:8765", payload, {
		["Content-Type"] = "application/json",
	})

	if status ~= 200 or not body then
		return nil, ("HTTP error from AnkiConnect: %s"):format(tostring(status))
	end

	local decoded = hs.json.decode(body)
	if not decoded then
		return nil, "Failed to decode AnkiConnect JSON"
	end

	if decoded.error then
		return nil, ("AnkiConnect error: %s"):format(tostring(decoded.error))
	end

	return decoded.result, nil
end

hs.hotkey.bind(hyper, "4", function()
	local button, query =
		hs.dialog.textPrompt("Search Anki", "Enter Anki search (e.g. foo, deck:Korean foo):", "", "Search", "Cancel")
	if button ~= "Search" or not query or query == "" then
		return
	end

	local cardIds, err = ankiRequest("findCards", { query = query })
	if err then
		hs.alert.show(err)
		return
	end
	if not cardIds or #cardIds == 0 then
		hs.alert.show("No cards found")
		return
	end

	-- Optional: cap results so chooser stays snappy
	if #cardIds > 200 then
		local trimmed = {}
		for i = 1, 200 do
			trimmed[i] = cardIds[i]
		end
		cardIds = trimmed
	end

	local cards, err2 = ankiRequest("cardsInfo", { cards = cardIds })
	if err2 then
		hs.alert.show(err2)
		return
	end
	if not cards then
		hs.alert.show("No card info returned")
		return
	end

	local choices = {}
	for _, card in ipairs(cards) do
		-- Try common field names; fall back gracefully
		local fields = card.fields or {}
		local front = (fields.Front and fields.Front.value)
			or (fields["Front"] and fields["Front"].value)
			or (fields.Question and fields.Question.value)
			or (fields.Expression and fields.Expression.value)
			or "(no Front field)"

		-- strip basic HTML tags for readability
		front = front:gsub("<.->", ""):gsub("&nbsp;", " "):gsub("%s+", " "):sub(1, 180)

		table.insert(choices, {
			text = front,
			subText = ("%s  •  %s"):format(card.deckName or "", card.noteType or ""),
			cardId = card.cardId,
		})
	end

	if ankiChooser then
		ankiChooser:hide()
	end
	ankiChooser = hs.chooser.new(function(choice)
		if not choice then
			return
		end
		-- Browse to the card, then focus Anki
		local _, err3 = ankiRequest("guiBrowse", { query = "cid:" .. tostring(choice.cardId) })
		if err3 then
			hs.alert.show(err3)
			return
		end
		hs.application.launchOrFocus("Anki")
	end)

	ankiChooser:choices(choices)
	ankiChooser:placeholderText("Select a card…")
	ankiChooser:show()
end)

-- Script Runner modal (Hyper+S)
local script_runner = require("script_runner")

-- Initialize the script runner (starts window watcher)
script_runner.init()

local scriptMode = hs.hotkey.modal.new(hyper, "s")

function scriptMode:entered()
	hs.alert.show("Script Runner Mode", 0.5)
	-- auto-exit after 2s idle
	self._timer = hs.timer.doAfter(2, function()
		scriptMode:exit()
	end)
end

function scriptMode:exited()
	if self._timer then
		self._timer:stop()
		self._timer = nil
	end
end

local function resetScriptTimer()
	if scriptMode._timer then
		scriptMode._timer:stop()
		scriptMode._timer = hs.timer.doAfter(2, function()
			scriptMode:exit()
		end)
	end
end

-- Load script directory mappings from config
local scriptConfig = script_runner.loadConfig()

-- Dynamically bind keys from config
for key, config in pairs(scriptConfig) do
	scriptMode:bind("", key, function()
		script_runner.launchScriptRunner(config.path, config.name, config.description)
		scriptMode:exit()
	end)
end

-- Escape to exit
scriptMode:bind("", "escape", function()
	resetScriptTimer()
	scriptMode:exit()
end)

-- Audio device selectors using fzf (now that script_runner is loaded)
hs.hotkey.bind(hyper, "i", function()
	script_runner.launchAudioInputSelector()
end)

hs.hotkey.bind(hyper, "o", function()
	script_runner.launchAudioOutputSelector()
end)
