-- Auto-reload Hammerspoon configuration when files change
-- Replacement for ReloadConfiguration Spoon

local reload = {}
local watchers = {}

-- Paths to watch for changes
local watch_paths = {
	hs.configdir,
	os.getenv("HOME") .. "/.config/hammerspoon",
}

-- Callback when files change
local function reload_config(files)
	local should_reload = false
	for _, file in pairs(files) do
		if file:sub(-4) == ".lua" then
			should_reload = true
			hs.printf("Config file changed: %s", file)
		end
	end
	
	if should_reload then
		-- Stop all watchers before reloading to prevent leaks
		reload.stop()
		hs.reload()
	end
end

-- Start watching paths
function reload.start()
	for _, path in ipairs(watch_paths) do
		local watcher = hs.pathwatcher.new(path, reload_config)
		watcher:start()
		table.insert(watchers, watcher)
		hs.printf("Watching for config changes: %s", path)
	end
end

-- Stop watching paths
function reload.stop()
	for _, watcher in ipairs(watchers) do
		watcher:stop()
	end
	watchers = {}
end

return reload
