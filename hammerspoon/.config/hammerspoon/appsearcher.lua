-- ~/.config/hammerspoon/appsearcher.lua
local M = {}
-- hotkeys.lua
-- Global: hyper + k -> pick app -> focus it -> wait until ready -> trigger search

local hyper = { "cmd", "alt", "ctrl", "shift" }

-- =========================
-- App search configuration
-- =========================
local SEARCH_APPS = {
	{
		label = "WhatsApp",
		appName = "WhatsApp",
		mods = { "cmd" },
		key = "f",
	},
	{
		label = "Google Chat",
		appName = "Google Chat",
		mods = { "cmd", "shift" },
		key = "k",
	},
	{
		label = "Google Messages",
		-- Replace if this ever changes on your system
		bundleID = "com.google.Chrome.app.hpfldicfbfomlpcikngkocigghgafkph",
		appName = "Google Messages",
		mods = { "cmd" },
		key = "k",
	},
	{
		label = "Signal",
		appName = "Signal",
		mods = { "cmd" },
		key = "f",
	},
	{
		label = "Discord",
		appName = "Discord",
		-- Cmd+K = Quick Switcher (DMs/servers/channels)
		-- Change to key="f" if you want in-chat search instead
		mods = { "cmd" },
		key = "k",
	},
}

-- =========================
-- Helpers
-- =========================
local function findApp(entry)
	if entry.bundleID then
		return hs.application.get(entry.bundleID)
	end
	if entry.appName then
		return hs.appfinder.appFromName(entry.appName)
	end
	return nil
end

local function launchOrFocus(entry)
	if entry.bundleID then
		hs.application.launchOrFocusByBundleID(entry.bundleID)
	elseif entry.appName then
		hs.application.launchOrFocus(entry.appName)
	end
end

local function hasStandardWindow(app)
	if not app then
		return false
	end
	for _, win in ipairs(app:allWindows() or {}) do
		if win:isStandard() and win:isVisible() then
			return true
		end
	end
	return false
end

-- Wait until app is frontmost AND has a window, then run fn(app)
local function whenAppReady(entry, fn)
	local timeout = 6.0
	local start = hs.timer.secondsSinceEpoch()

	local t
	t = hs.timer.doEvery(0.05, function()
		local app = findApp(entry)

		if app and app:isFrontmost() and hasStandardWindow(app) then
			t:stop()
			fn(app)
			return
		end

		if (hs.timer.secondsSinceEpoch() - start) > timeout then
			t:stop()
			hs.notify
				.new({
					title = "Hammerspoon",
					informativeText = "Timed out waiting for " .. (entry.label or entry.appName or "app"),
				})
				:send()
		end
	end)
end

local function focusThenSearch(entry)
	-- If already frontmost and ready, fire immediately
	local app = findApp(entry)
	if app and app:isFrontmost() and hasStandardWindow(app) then
		hs.eventtap.keyStroke(entry.mods or {}, entry.key, 0)
		return
	end

	-- Otherwise launch/focus and wait
	launchOrFocus(entry)
	whenAppReady(entry, function()
		hs.eventtap.keyStroke(entry.mods or {}, entry.key, 0)
	end)
end

-- =========================
-- Chooser
-- =========================
local chooser = hs.chooser.new(function(choice)
	if not choice then
		return
	end
	focusThenSearch(choice._entry)
end)

chooser:searchSubText(true)

function M.showSearchChooser()
	local choices = {}
	for _, entry in ipairs(SEARCH_APPS) do
		table.insert(choices, {
			text = entry.label,
			subText = table.concat(entry.mods or {}, "+")
				.. ((entry.mods and #entry.mods > 0) and "+" or "")
				.. string.upper(entry.key or ""),
			_entry = entry,
		})
	end
	chooser:choices(choices)
	chooser:show()
end

-- =========================
-- Hotkey
-- =========================
return M
