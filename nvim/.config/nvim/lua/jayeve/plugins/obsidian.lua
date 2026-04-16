local status, obsidian = pcall(require, "obsidian")
if not status then
	local info = debug.getinfo(1, "S").short_src
	print(info, "failed to load")
	return
end

-- Check if vault directories exist before setting up
local workspaces = {
	{
		name = "personal",
		path = "~/vaults/personal",
	},
	{
		name = "work",
		path = "~/cloudflare/vaults/work",
	},
}

local missing_dirs = {}
for _, workspace in ipairs(workspaces) do
	local expanded_path = vim.fn.expand(workspace.path)
	if vim.fn.isdirectory(expanded_path) == 0 then
		table.insert(missing_dirs, workspace.path)
	end
end

if #missing_dirs > 0 then
	vim.notify(
		"Obsidian plugin not loaded. Missing vault director" .. (#missing_dirs > 1 and "ies" or "y") .. ": " .. table.concat(missing_dirs, ", "),
		vim.log.levels.WARN
	)
	return
end

obsidian.setup({
	workspaces = workspaces,
})
