-- ~/.config/hammerspoon/profiles.lua
local M = {}

-- =========================
-- Screens
-- =========================
local function screensLeftToRight()
	local screens = hs.screen.allScreens()
	table.sort(screens, function(a, b)
		return a:frame().x < b:frame().x
	end)
	return screens
end

local function leftScreen()
	return screensLeftToRight()[1]
end

local function rightScreen()
	local s = screensLeftToRight()
	return s[#s]
end

local function pickScreen(which)
	if which == "left" then
		return leftScreen()
	end
	if which == "right" then
		return rightScreen()
	end
	return hs.screen.mainScreen()
end

-- =========================
-- Splits
-- =========================
local SPLITS = {
	-- quarters
	tlq = { x = 0.00, y = 0.00, w = 0.50, h = 0.50 },
	trq = { x = 0.50, y = 0.00, w = 0.50, h = 0.50 },
	blq = { x = 0.00, y = 0.50, w = 0.50, h = 0.50 },
	brq = { x = 0.50, y = 0.50, w = 0.50, h = 0.50 },

	-- halves
	lh = { x = 0.00, y = 0.00, w = 0.50, h = 1.00 },
	rh = { x = 0.50, y = 0.00, w = 0.50, h = 1.00 },
	th = { x = 0.00, y = 0.00, w = 1.00, h = 0.50 },
	bh = { x = 0.00, y = 0.50, w = 1.00, h = 0.50 },

	-- full
	full = { x = 0.00, y = 0.00, w = 1.00, h = 1.00 },
}

local function splitToUnit(split)
	if not split or split == "full" then
		return SPLITS.full
	end
	local unit = SPLITS[split]
	if unit then
		return unit
	end
	-- fallback if typo
	return SPLITS.full
end

-- =========================
-- Windows
-- =========================
local function getMainWindow(app)
	if not app then
		return nil
	end
	return app:mainWindow() or app:focusedWindow()
end

local function place(win, screen, split)
	if not win or not screen then
		return false
	end

	-- Ensure NOT macOS fullscreen
	pcall(function()
		win:setFullScreen(false)
	end)

	win:moveToScreen(screen)
	win:moveToUnit(splitToUnit(split))
	return true
end

-- Launch/focus app and wait for a window, then run fn(app, win)
local function withWindow(appName, fn)
	hs.application.launchOrFocus(appName)

	local deadline = hs.timer.secondsSinceEpoch() + 6.0
	local t
	t = hs.timer.doEvery(0.1, function()
		local app = hs.appfinder.appFromName(appName)
		local win = getMainWindow(app)

		if win then
			t:stop()
			fn(app, win)
			return
		end

		if hs.timer.secondsSinceEpoch() > deadline then
			t:stop()
			hs.notify
				.new({
					title = "Hammerspoon",
					informativeText = "No window for: " .. appName,
				})
				:send()
		end
	end)
end

-- =========================
-- Profiles
-- split options: full, tlq, trq, blq, brq, lh, rh, th, bh
-- =========================
M.profiles = {
	-- work: google chat/meet/chrome/chatgpt on left (stacked), alacritty on right
	work = {
		{ name = "Google Chat", screen = "left", split = "full" },
		{ name = "Google Meet", screen = "left", split = "full" },
		{ name = "Google Chrome", screen = "left", split = "full" },
		{ name = "ChatGPT", screen = "left", split = "full" },
		{ name = "Alacritty", screen = "right", split = "full", focus = true },
	},

	-- study: original "anki profile" but now expressed as splits
	study = {
		{ name = "Alacritty", screen = "left", split = "lh" },
		{ name = "ChatGPT", screen = "left", split = "rh" },
		{ name = "Anki", screen = "right", split = "full", focus = true },
	},

	-- play: discord/spotify/chatgpt on left stacked, chrome on right
	play = {
		{ name = "Discord", screen = "left", split = "full" },
		{ name = "Spotify", screen = "left", split = "full" },
		{ name = "ChatGPT", screen = "left", split = "full" },
		{ name = "Google Chrome", screen = "right", split = "full", focus = true },
	},
}

-- =========================
-- Minimize others
-- =========================
local EXCLUDED_BUNDLE_IDS = {
	["org.hammerspoon.Hammerspoon"] = true,
	["com.apple.finder"] = true, -- feels safer; remove if you truly want Finder minimized
	["com.apple.dock"] = true,
	["com.apple.SystemUIServer"] = true,
	["com.apple.notificationcenterui"] = true,
}

local function buildWhitelist(profileSpec)
	local allowed = {}
	for _, entry in ipairs(profileSpec) do
		allowed[entry.name] = true
	end
	return allowed
end

local function minimizeOtherApps(allowedByName)
	local running = hs.application.runningApplications()

	for _, app in ipairs(running) do
		local name = app:name()
		local bid = app:bundleID()

		if not EXCLUDED_BUNDLE_IDS[bid] and not allowedByName[name] then
			-- Minimize only standard windows to avoid weird panels / menu bar stuff
			for _, win in ipairs(app:allWindows() or {}) do
				if win:isStandard() and win:isVisible() and not win:isMinimized() then
					pcall(function()
						win:minimize()
					end)
				end
			end
		end
	end
end

-- =========================
-- Apply profile
-- =========================
function M.applyProfile(profileName)
	local spec = M.profiles[profileName]
	if not spec then
		hs.notify.new({ title = "Hammerspoon", informativeText = "Unknown profile: " .. tostring(profileName) }):send()
		return
	end

	-- Minimize everything not in this profile (NEW)
	local allowed = buildWhitelist(spec)
	minimizeOtherApps(allowed)

	local focusTarget = nil

	-- order matters: later entries end up on top for overlapping windows
	for _, entry in ipairs(spec) do
		local targetScreen = pickScreen(entry.screen)
		local split = entry.split or "full"

		withWindow(entry.name, function(app, win)
			place(win, targetScreen, split)
			if entry.focus then
				focusTarget = entry.name
			end
		end)
	end

	hs.timer.doAfter(0.35, function()
		if focusTarget then
			local app = hs.appfinder.appFromName(focusTarget)
			if app then
				app:activate(true)
			end
		end
	end)
end

return M
