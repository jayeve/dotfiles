local telescope = require("telescope")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local Job = require("plenary.job")
-- local previewers = require("telescope.previewers")

local M = {}

local function contains(table, value)
	for _, v in ipairs(table) do
		if v == value then
			return true
		end
	end
	return false
end

local function get_tmux_sessions()
	local sessions = {}
	local handle = io.popen("tmux list-sessions -F '#S'")

	if handle then
		for session in handle:lines() do
			table.insert(sessions, session)
		end
		handle:close()
	end

	return sessions
end

local function prj_helper(team, project)
	local starting_dir = vim.fn.getcwd()

	local base = os.getenv("HOME") .. "/cloudflare"
	if vim.fn.isdirectory(base) == 0 then
		print("creating " .. base)
		vim.fn.mkdir(base, "p")
	end

	local team_dir = base .. "/" .. team
	local project_dir = team_dir .. "/" .. project

	if vim.fn.isdirectory(project_dir) == 0 then
		-- check if project exists on bitbucket
		local gitlab_url = "git@gitlab.cfdata.org:cloudflare/" .. team .. "/" .. project .. ".git"

		-- Try cloning the repository from gitlab
		local gitlab_ls_remote = "git ls-remote " .. gitlab_url .. " > /dev/null 2>&1"
		local gitlab_success = os.execute(gitlab_ls_remote)

		if gitlab_success then
			print("INFO: checking gitlab for " .. team_dir)
			if vim.fn.isdirectory(team_dir) == 0 then
				print("INFO: creating directory " .. team_dir)
				vim.fn.mkdir(team_dir, "p")
			end

			print("INFO: cloning " .. gitlab_url .. " into " .. project_dir)
			os.execute("git clone " .. gitlab_url .. " " .. project_dir)
		else
			local bitbucket_url = "ssh://git@bitbucket.cfdata.org:7999/" .. team .. "/" .. project .. ".git"
			print("Cloning from Gitlab failed. Falling back to bitbucket")
			local bitbucket_success = "git ls-remote " .. bitbucket_url .. " > /dev/null 2>&1"
			if bitbucket_success then
				print("INFO: checking gitlab for " .. team_dir)
				if vim.fn.isdirectory(team_dir) == 0 then
					print("INFO: creating directory " .. team_dir)
					vim.fn.mkdir(team_dir, "p")
				end

				print("INFO: cloning " .. bitbucket_url .. " into " .. project_dir)
				os.execute("git clone " .. bitbucket_url .. " " .. project_dir)
			else
				print("ERROR: project " .. bitbucket_url .. " does not exist in bitbucket")
				return 1
			end
		end
	end

	-- Check if tmux is running
	local tmux_running = os.execute("pgrep tmux > /dev/null 2>&1")
	if vim.env.TMUX == nil and tmux_running ~= 0 then
		os.execute("tmux new-session -s " .. project .. " -c " .. project_dir)
		return
	end

	-- Check if tmux session exists
	local session_exists = os.execute("tmux has-session -t=" .. project .. " 2>/dev/null")
	if session_exists ~= 0 then
		print("creating session " .. project .. " with root dir at " .. vim.fn.getcwd())
		os.execute("tmux new-session -d -s " .. project .. " -c " .. project_dir)
	end

	if vim.env.TMUX == nil then
		-- Attach to the new session
		os.execute("tmux attach-session -t " .. project .. " -c " .. project_dir)
	else
		-- Switch to the new session
		os.execute("tmux switch-client -t " .. project)
	end

	-- Check if the function failed
	if session_exists ~= 0 then
		vim.cmd("cd " .. starting_dir)
		return 1
	end
end

local function prj(team, project)
	if not team or not project then
		print("Usage: prj <team> <project>")
		print(
			"This attempts to open a work project. If the project is not present, it will clone and open in a tmux session."
		)
	else
		prj_helper(team, project)
	end
end

local function list_git_dirs(root_dir)
	local results = {}
	Job:new({
		command = "find",
		args = { root_dir, "-mindepth", "3", "-maxdepth", "3", "-type", "d", "-name", ".git" },
		on_exit = function(j)
			for _, dir in ipairs(j:result()) do
				-- remove the trailing "/.git" from the path
				local git_dir = string.gsub(dir, "/%.git$", "")
				-- Extract the last two parts of the path
				local parts = vim.split(git_dir, "/")
				local tuple = { parts[#parts - 1], parts[#parts] }
				table.insert(results, tuple)
			end
		end,
	}):sync()
	return results
end

local function split_input_on_whitespace(input)
	local result = {}
	for word in string.gmatch(input, "%S+") do
		table.insert(result, word)
	end
	return result
end

local function attach_to_tmux_session(session)
	if vim.env.TMUX == nil then
		-- Attach to the new session
		os.execute("tmux attach-session -t " .. session)
	else
		-- Switch to the new session
		os.execute("tmux switch-client -t " .. session)
	end
end

function M.tmux_session_picker()
	pickers
		.new({}, {
			prompt_title = "TMUX session picker",
			finder = finders.new_table({
				results = get_tmux_sessions(),
				-- entry_maker = function(entry)
				-- 	local display_name = table.concat(entry, "  ")
				-- 	if contains(tmux_sessions, entry[2]) then
				-- 		display_name = table.concat(entry, "  ") .. " ●"
				-- 	end
				-- 	return {
				-- 		value = entry,
				-- 		display = display_name,
				-- 		ordinal = table.concat(entry, "/"),
				-- 	}
				-- end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(_, _)
				actions.select_default:replace(function(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					attach_to_tmux_session(selection[1])
				end)
				return true
			end,
		})
		:find()
end

function M.git_dir_picker(root_dir)
	local tmux_sessions = get_tmux_sessions()
	pickers
		.new({}, {
			prompt_title = "Local CF Git Repositories",
			finder = finders.new_table({
				results = list_git_dirs(root_dir),
				entry_maker = function(entry)
					local display_name = table.concat(entry, "  ")
					if contains(tmux_sessions, entry[2]) then
						display_name = table.concat(entry, "  ") .. " ●"
					end
					return {
						value = entry,
						display = display_name,
						ordinal = table.concat(entry, "/"),
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(_, map)
				actions.select_default:replace(function(prompt_bufnr)
					local input = action_state.get_current_line()
					local selection = action_state.get_selected_entry()

					actions.close(prompt_bufnr)
					if selection then
						-- vim.notify(
						-- 	"Project → " .. selection.value[1] .. " Repo → " .. selection.value[2],
						-- 	vim.log.levels.INFO,
						-- 	{ title = "prj.lua" }
						-- )
						prj(selection.value[1], selection.value[2])
					else
						local split = split_input_on_whitespace(input)
						if #split == 2 then
							-- vim.notify(
							-- 	"Input: " .. split[1] .. " " .. split[2],
							-- 	vim.log.levels.INFO,
							-- 	{ title = "prj.lua" }
							-- )
							prj(split[1], split[2])
						end
					end
				end)
				return true
			end,
		})
		:find()
end

local function read_gitlab_cache()
	local cache_file = os.getenv("HOME") .. "/.gitlab-projects-cache"
	local projects = {}
	local file = io.open(cache_file, "r")

	if not file then
		print("Error: GitLab cache not found at " .. cache_file)
		print("Run 'glprj-refresh' in your shell first")
		return projects
	end

	for line in file:lines() do
		if line and line ~= "" then
			table.insert(projects, line)
		end
	end
	file:close()

	return projects
end

local function gitlab_prj_helper(full_path)
	local starting_dir = vim.fn.getcwd()
	local base = os.getenv("HOME") .. "/cloudflare"

	-- Strip cloudflare/ prefix if present
	local relative_path = full_path
	if vim.startswith(full_path, "cloudflare/") then
		relative_path = string.sub(full_path, 12) -- Remove "cloudflare/"
	end

	local bare_dir = base .. "/" .. relative_path .. ".git"
	local project = vim.fn.fnamemodify(relative_path, ":t")

	-- Clone as bare if doesn't exist
	if vim.fn.isdirectory(bare_dir) == 0 then
		vim.fn.mkdir(vim.fn.fnamemodify(bare_dir, ":h"), "p")
		print("Cloning git@gitlab.cfdata.org:" .. full_path .. ".git as bare repo")
		os.execute("git clone --bare git@gitlab.cfdata.org:" .. full_path .. ".git " .. vim.fn.shellescape(bare_dir))

		-- Configure fetch refspec for remote tracking (needed for @{u} to work in worktrees)
		os.execute(
			"cd "
				.. vim.fn.shellescape(bare_dir)
				.. " && git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'"
		)

		print("Bare repo created at: " .. bare_dir)
	end

	-- Check if there are any worktrees
	local worktrees_cmd = "cd "
		.. vim.fn.shellescape(bare_dir)
		.. " && git worktree list --porcelain 2>/dev/null | grep '^worktree ' | sed 's/^worktree //'"
	local handle = io.popen(worktrees_cmd)
	local worktrees = handle:read("*a")
	handle:close()

	local target_dir

	if worktrees == "" or worktrees == nil then
		-- No worktrees exist, create default one from main/master branch
		local default_branch_cmd = "cd "
			.. vim.fn.shellescape(bare_dir)
			.. " && git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'"
		local branch_handle = io.popen(default_branch_cmd)
		local default_branch = branch_handle:read("*l")
		branch_handle:close()

		if default_branch == "" or default_branch == nil then
			-- Fallback: try main, then master
			local main_exists =
				os.execute("cd " .. vim.fn.shellescape(bare_dir) .. " && git show-ref --verify --quiet refs/heads/main")
			if main_exists == 0 then
				default_branch = "main"
			else
				local master_exists = os.execute(
					"cd " .. vim.fn.shellescape(bare_dir) .. " && git show-ref --verify --quiet refs/heads/master"
				)
				if master_exists == 0 then
					default_branch = "master"
				else
					default_branch = "main" -- Default fallback
				end
			end
		end

		target_dir = base .. "/" .. relative_path .. "/" .. default_branch
		vim.fn.mkdir(vim.fn.fnamemodify(target_dir, ":h"), "p")
		print("Creating default worktree for branch: " .. default_branch)
		os.execute(
			"cd "
				.. vim.fn.shellescape(bare_dir)
				.. " && git worktree add "
				.. vim.fn.shellescape(target_dir)
				.. " "
				.. default_branch
		)
	else
		-- Use the first worktree (or could prompt user to select)
		target_dir = vim.split(worktrees, "\n")[1]
	end

	-- Session name: use project name, if exists add parent directory prefix
	local session_name = project
	local session_check = os.execute("tmux has-session -t=" .. vim.fn.shellescape(session_name) .. " 2>/dev/null")
	if session_check == 0 then
		-- Session exists, use parent directory as prefix
		local parent_dir = vim.fn.fnamemodify(relative_path, ":h")
		if parent_dir ~= "." then
			session_name = vim.fn.fnamemodify(parent_dir, ":t") .. "_" .. project
		end
	end

	-- Check if tmux is running
	local tmux_running = os.execute("pgrep tmux > /dev/null 2>&1")
	if vim.env.TMUX == nil and tmux_running ~= 0 then
		os.execute(
			"tmux new-session -s " .. vim.fn.shellescape(session_name) .. " -c " .. vim.fn.shellescape(target_dir)
		)
		return
	end

	-- Check if tmux session exists
	local session_exists = os.execute("tmux has-session -t=" .. vim.fn.shellescape(session_name) .. " 2>/dev/null")
	if session_exists ~= 0 then
		print("creating session " .. session_name .. " at " .. target_dir)
		os.execute(
			"tmux new-session -d -s " .. vim.fn.shellescape(session_name) .. " -c " .. vim.fn.shellescape(target_dir)
		)
	end

	if vim.env.TMUX == nil then
		os.execute(
			"tmux attach-session -t " .. vim.fn.shellescape(session_name) .. " -c " .. vim.fn.shellescape(target_dir)
		)
	else
		os.execute("tmux switch-client -t " .. vim.fn.shellescape(session_name))
	end

	if session_exists ~= 0 then
		vim.cmd("cd " .. starting_dir)
		return 1
	end
end

function M.gitlab_project_picker()
	local tmux_sessions = get_tmux_sessions()
	local base = os.getenv("HOME") .. "/cloudflare"

	pickers
		.new({}, {
			prompt_title = "GitLab Projects (9,072 repos)",
			finder = finders.new_table({
				results = read_gitlab_cache(),
				entry_maker = function(entry)
					-- Check if project exists locally (as bare repo)
					local check_path = entry
					if vim.startswith(entry, "cloudflare/") then
						check_path = string.sub(entry, 12)
					end

					local bare_dir = base .. "/" .. check_path .. ".git"
					local project_name = vim.fn.fnamemodify(check_path, ":t")
					local is_local = vim.fn.isdirectory(bare_dir) == 1
					local has_session = contains(tmux_sessions, project_name)

					local display = entry
					if is_local then
						display = "LOCAL  " .. entry
					else
						display = "REMOTE " .. entry
					end

					if has_session then
						display = display .. " ●"
					end

					return {
						value = entry,
						display = display,
						ordinal = entry,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(_, map)
				actions.select_default:replace(function(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)

					if selection then
						gitlab_prj_helper(selection.value)
					end
				end)
				return true
			end,
		})
		:find()
end

-- TODO export as a telescope extension
return M
