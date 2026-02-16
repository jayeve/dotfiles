require("git-worktree").setup({
	change_directory_command = "cd",
	update_on_change = true,
	update_on_change_command = "edit",
	clearjumps_on_change = true,
	autopush = false,
})

local Worktree = require("git-worktree")

-- op = Operations.Switch, Operations.Create, Operations.Delete
-- metadata = table of useful values (structure dependent on op)
--      Switch
--          path = path you switched to
--          prev_path = previous worktree path
--      Create
--          path = path where worktree created
--          branch = branch name
--          upstream = upstream remote name
--      Delete
--          path = path where worktree deleted

Worktree.on_tree_change(function(op, metadata)
	if op == Worktree.Operations.Switch then
		vim.notify(
			"Switched  " .. metadata.prev_path .. " → " .. metadata.path,
			vim.log.levels.INFO,
			{ title = "jayeve.plugins.git-worktree" }
		)
	end
end)
