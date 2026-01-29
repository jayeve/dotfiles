-- ~/.config/hammerspoon/locations.lua
-- Central place to define important locations on file system.

-- Default locations (fallback values)
local json = hs.json
local home = os.getenv("HOME")

local configPath = home .. "/.config/hammerspoon/projects.json"

local raw = json.read(configPath)
assert(raw, "Failed to read projects.json")

local projects = {}

for key, value in pairs(raw) do
	projects[key] = {
		value.name,
		home .. "/" .. value.path,
	}
end

Locations = projects
