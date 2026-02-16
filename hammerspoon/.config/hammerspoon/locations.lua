-- ~/.config/hammerspoon/locations.lua
-- Central place to define important locations on file system.

local M = {}

function M.load(configPath)
	local json = hs.json
	local home = os.getenv("HOME")

	configPath = configPath or (home .. "/.config/project-hotkeys.json")

	local raw = json.read(configPath)
	if not raw then
		error("Failed to read " .. configPath)
	end
	local projects = {}
	for _, value in ipairs(raw) do
		-- Handle both absolute and relative paths
		local path = value.path
		if not path:match("^/") then
			-- Relative path, prepend HOME
			path = home .. "/" .. path
		end
		projects[value.name] = {
			value.name,
			path,
		}
	end
	return projects
end

return M
