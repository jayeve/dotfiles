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
		-- For cloudflare projects (HOME/cloudflare/<team>/<project>.git), derive
		-- session name as "team|project" to match gitlab_project_picker convention.
		-- All other projects keep the JSON name with underscores replaced by dashes.
		local session_name
		local cf_team, cf_proj = path:match(home:gsub("%-", "%%-") .. "/cloudflare/([^/]+)/([^/]+)%.git$")
		if cf_team and cf_proj then
			session_name = cf_team .. "|" .. cf_proj
		else
			session_name = value.name:gsub("_", "-")
		end
		projects[value.name] = {
			value.name,
			path,
			session_name = session_name,
		}
	end
	return projects
end

return M
