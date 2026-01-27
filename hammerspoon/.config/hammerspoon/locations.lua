-- ~/.config/hammerspoon/locations.lua
-- Central place to define important locations on file system.

-- Default locations (fallback values)
local home = os.getenv("HOME")
local defaultLocations = {
	dotfiles = { "dotfiles", home },
	extractor = { "extractor", home },
	personal_notes = { "personal-notes", home },
	weekly_notes = { "weekly-notes", home },
	opencode = { "opencode", home },
	scratch = { "scratch", home },
	-- work
	fl2 = { "fl2", home },
	pingora_origin = { "pingora-origin", home },
	salt = { "salt", home },
	pbr = { "pingora-backend-router", home },
	ssl_detector = { "ssl-detector", home },
	cache_indexer = { "cache-indexer", home },
}

-- Try to load private locations (not checked into git)
Locations = {}
local privateFile = hs.configdir .. "/locations.private.lua"

-- Check if private file exists and load it
local f = io.open(privateFile, "r")
if f then
	f:close()
	local ok, privateLocations = pcall(dofile, privateFile)
	if ok and type(privateLocations) == "table" then
		-- Merge private locations with defaults (private takes precedence)
		for key, value in pairs(defaultLocations) do
			Locations[key] = value
		end
		for key, value in pairs(privateLocations) do
			Locations[key] = value
		end
		hs.printf("Loaded private locations from: %s", privateFile)
	else
		-- Private file exists but couldn't be loaded, use defaults
		Locations = defaultLocations
		hs.printf("Warning: Could not load %s, using defaults", privateFile)
	end
else
	-- No private file, use defaults
	Locations = defaultLocations
	hs.printf("No private locations file found, using defaults")
end
