local M = {}

function M.check_lsp_client_active(name)
	local clients = vim.lsp.get_clients()
	for _, client in pairs(clients) do
		if client.name == name then
			return true
		end
	end
	return false
end

function M.define_augroups(definitions) -- {{{1
	-- Create autocommand groups based on the passed definitions
	--
	-- The key will be the name of the group, and each definition
	-- within the group should have:
	--    1. Trigger
	--    2. Pattern
	--    3. Text
	-- just like how they would normally be defined from Vim itself
	for group_name, definition in pairs(definitions) do
		vim.cmd("augroup " .. group_name)
		vim.cmd("autocmd!")

		for _, def in pairs(definition) do
			local command = table.concat(vim.iter({ "autocmd", def }):flatten():totable(), " ")
			vim.cmd(command)
		end

		vim.cmd("augroup END")
	end
end

M.define_augroups({
	_general_settings = {
		{ "TextYankPost", "*", "lua require('vim.hl').on_yank({higroup = 'Search', timeout = 200})" },
		{ "BufWinEnter", "*", "setlocal formatoptions-=c formatoptions-=r formatoptions-=o" },
		{ "BufRead", "*", "setlocal formatoptions-=c formatoptions-=r formatoptions-=o" },
		{ "BufNewFile", "*", "setlocal formatoptions-=c formatoptions-=r formatoptions-=o" },
		-- { "VimLeavePre", "*", "set title set titleold=" },
	},
	_markdown = { { "FileType", "markdown", "setlocal wrap" }, { "FileType", "markdown", "setlocal spell" } },
	_auto_resize = {
		-- will cause split windows to be resized evenly if main window is resized
		{ "VimResized", "*", "wincmd =" },
	},
	_qf = {
		-- will cause split windows to be resized evenly if main window is resized
		{ "FileType", "qf", "set nobuflisted" },
	},
})

vim.cmd([[
  function! QuickFixToggle()
    if empty(filter(getwininfo(), 'v:val.quickfix'))
      copen
    else
      cclose
    endif
endfunction
]])

function M.find_current_buffer_git_root()
	local dot_git_path = vim.fn.finddir(".git", ".;")
	local is_git_project = vim.fn.fnamemodify(dot_git_path, ":t") == ".git"
	return is_git_project and vim.fn.fnamemodify(vim.fn.fnamemodify(dot_git_path, ":p"), ":h:h") or nil
end

local function on_dir_changed()
	local cwd = vim.fn.getcwd()
	vim.notify("cwd changed to → " .. cwd, vim.log.levels.INFO, { title = "jayeve.utils" })
end

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	pattern = { ".tigrc" },
	callback = function(ev)
		vim.bo.filetype = "bash"
	end,
})
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	pattern = { "Brewfile" },
	callback = function(ev)
		vim.bo.filetype = "toml"
	end,
})

vim.api.nvim_create_autocmd({ "DirChanged" }, {
	callback = on_dir_changed,
})

function M.file_exists(name)
	local f = io.open(name, "r")
	if f ~= nil then
		io.close(f)
		return true
	else
		return false
	end
end

function M.find_current_buffer_git_worktree_root()
	-- For worktrees, .git is a file (not a directory) containing "gitdir: <path>"
	-- For normal repos, .git is a directory
	-- This function returns the worktree root directory in both cases
	local dot_git_path = vim.fn.findfile(".git", ".;")
	if dot_git_path == "" then
		dot_git_path = vim.fn.finddir(".git", ".;")
	end

	if dot_git_path == "" then
		return nil
	end

	-- Get the absolute path to .git
	local dot_git_abs = vim.fn.fnamemodify(dot_git_path, ":p")
	-- Remove trailing slash if present (for directories)
	dot_git_abs = dot_git_abs:gsub("/$", "")
	-- Get the parent directory
	local git_root = vim.fn.fnamemodify(dot_git_abs, ":h")
	return git_root
end

-- Universal version that works in both regular repos and worktrees
function M.cd_to_git_root_universal()
	local git_root = M.find_current_buffer_git_worktree_root()
	if git_root then
		vim.cmd.cd(git_root)
		vim.fn.setreg("+", git_root)
		vim.notify("cur dir → " .. git_root .. " copied to clipboard", vim.log.levels.INFO, {
			title = "jayeve.utils",
		})
	else
		vim.notify("Git root not found.", vim.log.levels.ERROR, { title = "jayeve.utils" })
	end
end

function M.show_cur_location()
	local current_buffer = vim.api.nvim_get_current_buf()
	local file_path = vim.api.nvim_buf_get_name(current_buffer)
	local empty_file = string.len(file_path) == 0
	local file_str = empty_file and "[Empty Buf]" or file_path
	local cur_dir = vim.loop.cwd()
	vim.notify("cur file → " .. file_str .. "\ncur dir → " .. cur_dir, vim.log.levels.INFO, {
		title = "jayeve.utils",
	})
end

local function open_or_create_file(filepath)
	-- Check if the file exists
	local file = io.open(filepath, "r")

	if file then
		vim.notify("Opening file: " .. filepath, vim.log.levels.INFO, {
			title = "jayeve.utils",
		})
		file:close() -- Close the file if it exists
	else
		-- Create template if file doesn't exist
		local weekdays = { "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" }
		local lines = {}

		for _, day in ipairs(weekdays) do
			table.insert(lines, "# " .. day)
			table.insert(lines, "")
		end

		vim.fn.writefile(lines, filepath)
		vim.cmd("edit " .. filepath)
		-- local new_file = io.open(filepath, "w")
		-- if new_file then
		-- 	new_file:close()
		-- else
		-- 	vim.notify("Error: unable to create file" .. filepath, vim.log.levels.INFO, {
		-- 		title = "jayeve.utils",
		-- 	})
		-- 	return
		-- end
	end

	-- Open the file in a vertical split
	vim.cmd("edit " .. vim.fn.fnameescape(filepath))
end

local function get_monday_date()
	-- Get current date
	local now = os.time()
	local current_date = os.date("*t", now)

	-- Determine how many days to subtract to get to Monday
	local days_to_monday = (current_date.wday - 2) % 7
	local monday_time = now - (days_to_monday * 86400)

	-- Format the date as YYYY.MM.DD
	return os.date("%Y.%m.%d", monday_time)
end

function M.open_personal_notes()
	-- Get the current buffer's file path
	local path = "/Users/jevans/vaults/personal/weekly-notes/week-of-" .. get_monday_date() .. ".md"
	open_or_create_file(path)
end

function M.open_notes()
	-- Get the current buffer's file path
	local path = "/Users/jevans/cloudflare/vaults/work/weekly-notes/week-of-" .. get_monday_date() .. ".md"
	open_or_create_file(path)
end

-- Parse week date from filename (week-of-YYYY.MM.DD.md)
-- Returns the date string (YYYY.MM.DD) or nil if not a weekly note
local function parse_week_from_filename(filepath)
	if not filepath then
		return nil
	end
	local pattern = "week%-of%-(%d%d%d%d%.%d%d%.%d%d)%.md"
	return filepath:match(pattern)
end

-- Get Monday date offset by N weeks from a given date string (YYYY.MM.DD)
-- If base_date is nil, uses current Monday
local function get_monday_offset(base_date, week_offset)
	local base_time
	
	if base_date then
		-- Parse YYYY.MM.DD format
		local year, month, day = base_date:match("(%d%d%d%d)%.(%d%d)%.(%d%d)")
		if year and month and day then
			base_time = os.time({ year = tonumber(year), month = tonumber(month), day = tonumber(day), hour = 12 })
		else
			-- Fallback to current Monday if parsing fails
			base_time = os.time()
			local current_date = os.date("*t", base_time)
			local days_to_monday = (current_date.wday - 2) % 7
			base_time = base_time - (days_to_monday * 86400)
		end
	else
		-- Use current Monday
		base_time = os.time()
		local current_date = os.date("*t", base_time)
		local days_to_monday = (current_date.wday - 2) % 7
		base_time = base_time - (days_to_monday * 86400)
	end
	
	-- Add/subtract weeks (7 days * week_offset)
	local target_time = base_time + (week_offset * 7 * 86400)
	
	return os.date("%Y.%m.%d", target_time)
end

-- Check if a week date (YYYY.MM.DD) is in the future
local function is_future_week(monday_date_string)
	-- Get current Monday
	local now = os.time()
	local current_date = os.date("*t", now)
	local days_to_monday = (current_date.wday - 2) % 7
	local current_monday = now - (days_to_monday * 86400)
	
	-- Parse the target date
	local year, month, day = monday_date_string:match("(%d%d%d%d)%.(%d%d)%.(%d%d)")
	if not year or not month or not day then
		return false
	end
	
	local target_time = os.time({ year = tonumber(year), month = tonumber(month), day = tonumber(day), hour = 12 })
	
	-- Compare (allow same week)
	return target_time > current_monday
end

-- Navigate to relative week note (work or personal)
-- direction: 1 for next, -1 for previous
-- note_type: "work" or "personal"
function M.navigate_to_week_note(direction, note_type)
	local current_buffer = vim.fn.expand("%:p")
	local base_date = parse_week_from_filename(current_buffer)
	
	-- If not currently in a weekly note, use today's week as reference
	if not base_date then
		base_date = get_monday_date()
	end
	
	-- Calculate target week
	local target_date = get_monday_offset(base_date, direction)
	
	-- Check if target is in the future
	if is_future_week(target_date) then
		vim.notify("Cannot create notes for future weeks", vim.log.levels.WARN, {
			title = "jayeve.utils",
		})
		return
	end
	
	-- Determine the path based on note type
	local path
	if note_type == "personal" then
		path = "/Users/jevans/vaults/personal/weekly-notes/week-of-" .. target_date .. ".md"
	else
		path = "/Users/jevans/cloudflare/vaults/work/weekly-notes/week-of-" .. target_date .. ".md"
	end
	
	open_or_create_file(path)
end

function M.cd_fzf(path)
	-- implement me
end

-- Define a function to copy the file path to the clipboard
function M.copy_file_path_to_clipboard(show_line_number, use_fully_qualified_name)
	-- Get the current buffer's file path
	local file_path
	if use_fully_qualified_name then
		file_path = vim.fn.expand("%:p") -- Full path
	else
		file_path = vim.fn.expand("%:t") -- Just filename
	end

	-- Optionally append line number
	if show_line_number then
		local line_number = vim.api.nvim_win_get_cursor(0)[1]
		file_path = file_path .. ":" .. line_number
	end

	-- Copy the file path to the system clipboard
	vim.fn.setreg("+", file_path)
	vim.notify("File path copied to clipboard: " .. file_path, vim.log.levels.INFO, {
		title = "jayeve.utils",
	})
end

-- Define a function to copy the directory of the current buffer to the clipboard
function M.copy_directory_to_clipboard()
	-- Get the current buffer's file path
	local file_path = vim.fn.expand("%:p")

	-- Extract the directory
	local directory = vim.fn.fnamemodify(file_path, ":h")

	-- Copy the directory to the system clipboard
	vim.fn.setreg("+", directory)
	vim.notify("Directory copied to clipboard: " .. directory, vim.log.levels.INFO, {
		title = "jayeve.utils",
	})
end

function M.cd_to_current_buf_directory()
	local bufname = vim.api.nvim_buf_get_name(0)
	local buffer_directory = bufname:match("^(.*)/[^/]-$")

	if buffer_directory then
		vim.cmd.cd(buffer_directory)
	else
		vim.notify(
			"Error: Unable to determine directory for current buffer.",
			vim.log.levels.ERROR,
			{ title = "jayeve.utils" }
		)
	end
end

-- Save as: lua/gitlab_blame_link.lua (or put in your config directly)
-- Provides :GitlabBlameLink to open the MR (or commit) for the current line.

local function syslist(cmd)
	-- Prefer vim.system if present (nvim 0.10+), otherwise fallback to systemlist
	if vim.system then
		local res = vim.system(cmd, { text = true }):wait()
		if res.code ~= 0 then
			return nil, res.stderr
		end
		local out = {}
		for line in string.gmatch(res.stdout or "", "([^\n]*)\n?") do
			if line ~= "" then
				table.insert(out, line)
			end
		end
		return out, nil
	else
		local out = vim.fn.systemlist(cmd)
		if vim.v.shell_error ~= 0 then
			return nil, table.concat(out or {}, "\n")
		end
		return out, nil
	end
end

local function git_remote_url(root)
	local out = syslist({ "git", "-C", root, "remote", "get-url", "origin" })
	return out and out[1] or nil
end

local function normalize_gitlab_base(remote)
	-- Convert git@host:group/repo.git -> https://host/group/repo
	-- Convert https://host/group/repo(.git)? -> https://host/group/repo
	if not remote then
		return nil
	end
	local host, path

	-- ssh form
	local ssh_host, ssh_path = remote:match("^git@([^:]+):(.+)$")
	if ssh_host then
		host, path = ssh_host, ssh_path
	else
		-- https form
		local prot, https_host, https_path = remote:match("^(https?://)([^/]+)/(.+)$")
		if https_host then
			host, path = https_host, https_path
		end
	end
	if not host or not path then
		return nil
	end
	path = path:gsub("%.git$", "")
	return ("https://%s/%s"):format(host, path)
end

local function detect_git_platform(base_url)
	-- Detect if the git hosting platform is GitHub or GitLab
	-- Returns: "github", "gitlab", or nil
	if not base_url then
		return nil
	end
	if base_url:match("github%.com") then
		return "github"
	elseif base_url:match("gitlab") then
		return "gitlab"
	end
	return nil
end

local function blame_commit_sha(absfile, lnum)
	local current_buf_git_root = M.find_current_buffer_git_root()
	-- Use porcelain blame so the commit is predictable to parse
	local out, err = syslist({
		"git",
		"-C",
		current_buf_git_root,
		"blame",
		"-L",
		("%d,%d"):format(lnum, lnum),
		"--porcelain",
		"--",
		absfile,
	})
	if not out then
		return nil, ("git blame failed: %s"):format(err or "unknown")
	end
	-- First line starts with "<sha> <orig-lineno> <lineno> <numlines>"
	local sha = out[1] and out[1]:match("^([0-9a-f]+) ")
	if sha == "0000000000000000000000000000000000000000" then
		return nil, "Line is not committed yet"
	end
	return sha, nil
end

local function blame_commit_sha_universal(absfile, lnum)
	local current_buf_git_root = M.find_current_buffer_git_worktree_root()
	-- Make file path relative to git root
	local relfile = absfile
	if current_buf_git_root and absfile:sub(1, #current_buf_git_root) == current_buf_git_root then
		relfile = absfile:sub(#current_buf_git_root + 2) -- +2 to skip the trailing slash
	end
	-- Use porcelain blame so the commit is predictable to parse
	local out, err = syslist({
		"git",
		"-C",
		current_buf_git_root,
		"blame",
		"-L",
		("%d,%d"):format(lnum, lnum),
		"--porcelain",
		"--",
		relfile,
	})
	if not out then
		return nil, ("git blame failed: %s"):format(err or "unknown")
	end
	-- First line starts with "<sha> <orig-lineno> <lineno> <numlines>"
	local sha = out[1] and out[1]:match("^([0-9a-f]+) ")
	if sha == "0000000000000000000000000000000000000000" then
		return nil, "Line is not committed yet"
	end
	return sha, nil
end

local function commit_body(sha)
	local out = syslist({ "git", "show", "-s", "--format=%B", sha })
	if not out then
		return ""
	end
	return table.concat(out, "\n")
end

local function open_url(url)
	-- Try nvim's opener; otherwise OS open
	if vim.ui and vim.ui.open then
		vim.ui.open(url)
	else
		local uname = syslist({ "uname" })
		if uname and uname[1] and uname[1]:match("Darwin") then
			syslist({ "open", url })
		else
			syslist({ "xdg-open", url })
		end
	end
end

function M.open_gitlab_link_for_current_line()
	-- Preconditions: inside a git repo, file tracked
	local root = M.find_current_buffer_git_root()
	if not root then
		vim.notify("Not inside a Git repository", vim.log.levels.ERROR, { title = "jayeve.utils" })
		return
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local file = vim.api.nvim_buf_get_name(bufnr)
	if file == "" then
		vim.notify("Buffer has no name", vim.log.levels.ERROR, { title = "jayeve.utils" })
		return
	end

	-- Get line number (1-based)
	local lnum = vim.api.nvim_win_get_cursor(0)[1]

	-- Find introducing commit
	local sha, err = blame_commit_sha(file, lnum)
	if not sha then
		vim.notify(err or "Failed to find blame commit", vim.log.levels.ERROR, { title = "jayeve.utils" })
		return
	end

	-- Build GitLab base URL from remote
	local remote = git_remote_url(M.find_current_buffer_git_root())
	local base = normalize_gitlab_base(remote)
	if not base or not base:match("gitlab") then
		-- Fallback: just echo the commit
		vim.notify(
			("Commit %s (remote not GitLab?): %s"):format(sha, remote or "nil"),
			vim.log.levels.WARN,
			{ title = "jayeve.utils" }
		)
		return
	end

	-- Try to detect MR number in commit body (e.g., "See merge request !123")
	local body = commit_body(sha)
	local mr = body:match("!([0-9]+)")
	vim.notify(body, vim.log.levels.INFO, { title = "jayeve.utils" })

	if mr then
		local mr_url = ("%s/-/merge_requests/%s"):format(base, mr)
		vim.notify(("Opening MR !%s (commit %s)"):format(mr, sha), vim.log.levels.INFO, { title = "jayeve.utils" })
		open_url(mr_url)
	else
		-- Open a search page scoped to merge requests for this SHA (works in many setups)
		local search_url = ("%s/-/commit/%s"):format(base, sha)
		vim.fn.setreg("+", search_url)
		-- optional: notify user
		vim.notify("Copied to clipboard: " .. search_url, vim.log.levels.INFO, { title = "jayeve.utils" })
		vim.notify(
			("Opening commit (no MR tag found). Commit: %s"):format(sha),
			vim.log.levels.INFO,
			{ title = "jayeve.utils" }
		)
		-- Prefer MR search; if your instance is private, at least commit URL is useful:
		open_url(search_url)
		-- Uncomment to also open the specific commit page:
		-- open_url(commit_url)
	end
end

-- Universal version that works in both regular repos and worktrees
function M.open_gitlab_link_for_current_line_universal()
	-- Preconditions: inside a git repo, file tracked
	local root = M.find_current_buffer_git_worktree_root()
	if not root then
		vim.notify("Not inside a Git repository", vim.log.levels.ERROR, { title = "jayeve.utils" })
		return
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local file = vim.api.nvim_buf_get_name(bufnr)
	if file == "" then
		vim.notify("Buffer has no name", vim.log.levels.ERROR, { title = "jayeve.utils" })
		return
	end

	-- Get line number (1-based)
	local lnum = vim.api.nvim_win_get_cursor(0)[1]

	-- Find introducing commit
	local sha, err = blame_commit_sha_universal(file, lnum)
	if not sha then
		vim.notify(err or "Failed to find blame commit", vim.log.levels.ERROR, { title = "jayeve.utils" })
		return
	end

	-- Build base URL from remote
	local remote = git_remote_url(root)
	local base = normalize_gitlab_base(remote)
	if not base then
		vim.notify(
			("Commit %s (failed to parse remote): %s"):format(sha, remote or "nil"),
			vim.log.levels.WARN,
			{ title = "jayeve.utils" }
		)
		return
	end

	-- Detect platform (GitHub or GitLab)
	local platform = detect_git_platform(base)
	if not platform then
		vim.notify(
			("Commit %s (unknown platform): %s"):format(sha, base),
			vim.log.levels.WARN,
			{ title = "jayeve.utils" }
		)
		return
	end

	-- Try to detect PR/MR number in commit body
	local body = commit_body(sha)
	local pr_or_mr = nil
	local pr_or_mr_url = nil
	local commit_url = nil

	if platform == "gitlab" then
		-- GitLab: look for "!123" pattern
		pr_or_mr = body:match("!([0-9]+)")
		if pr_or_mr then
			pr_or_mr_url = ("%s/-/merge_requests/%s"):format(base, pr_or_mr)
		end
		commit_url = ("%s/-/commit/%s"):format(base, sha)
	elseif platform == "github" then
		-- GitHub: look for "#123" or "Merge pull request #123" pattern
		pr_or_mr = body:match("Merge pull request #([0-9]+)") or body:match("#([0-9]+)")
		if pr_or_mr then
			pr_or_mr_url = ("%s/pull/%s"):format(base, pr_or_mr)
		end
		commit_url = ("%s/commit/%s"):format(base, sha)
	end

	vim.notify(body, vim.log.levels.INFO, { title = "jayeve.utils" })

	if pr_or_mr and pr_or_mr_url then
		local pr_mr_label = platform == "github" and "PR" or "MR"
		local pr_mr_prefix = platform == "github" and "#" or "!"
		vim.notify(
			("Opening %s %s%s (commit %s)"):format(pr_mr_label, pr_mr_prefix, pr_or_mr, sha),
			vim.log.levels.INFO,
			{ title = "jayeve.utils" }
		)
		open_url(pr_or_mr_url)
	else
		-- Open commit page directly
		vim.fn.setreg("+", commit_url)
		vim.notify("Copied to clipboard: " .. commit_url, vim.log.levels.INFO, { title = "jayeve.utils" })
		vim.notify(
			("Opening commit (no PR/MR tag found). Commit: %s"):format(sha),
			vim.log.levels.INFO,
			{ title = "jayeve.utils" }
		)
		open_url(commit_url)
	end
end

-- Telescope picker to fuzzy find and cd into directories
function M.telescope_find_directories(path)
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	-- Default to current directory if no path provided
	local search_path = path or vim.fn.getcwd()

	pickers
		.new({}, {
			prompt_title = "Find Directories",
			finder = finders.new_oneshot_job({ "fd", "--type", "d", "--hidden", "--exclude", ".git" }, {
				cwd = search_path,
			}),
			sorter = conf.generic_sorter({}),
			previewer = conf.file_previewer({}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					if selection then
						local dir = search_path .. "/" .. selection[1]
						vim.cmd.cd(dir)
						vim.notify("Changed directory to: " .. dir, vim.log.levels.INFO, { title = "jayeve.utils" })
					end
				end)
				return true
			end,
		})
		:find()
end

return M
