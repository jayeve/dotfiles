local M = {}

-- Import telescope modules
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

-- Helper: Check if glab CLI is available
local function check_glab_available()
	local glab_check = vim.fn.system("which glab 2>/dev/null"):gsub("\n", "")
	if glab_check == "" then
		vim.notify("glab CLI tool is required. Install via: brew install glab", vim.log.levels.WARN)
		return false
	end
	return true
end

-- Helper: URL encode for GitLab API paths
local function urlencode(str)
	if str == nil then
		return nil
	end
	-- Encode characters for URL (especially slashes for GitLab API)
	str = string.gsub(str, "([^%w%-%.%_%~])", function(c)
		return string.format("%%%02X", string.byte(c))
	end)
	return str
end

-- Helper: Get current GitLab project path from git remote
local function get_current_gitlab_project()
	-- Get git remote URL
	local remote = vim.fn.system("git config --get remote.origin.url 2>/dev/null"):gsub("\n", "")

	if remote == "" then
		return nil
	end

	-- Parse GitLab URLs (both SSH and HTTPS formats)
	-- SSH: git@gitlab.cfdata.org:cloudflare/cache/myproject.git
	-- HTTPS: https://gitlab.cfdata.org/cloudflare/cache/myproject.git
	local project_path = remote:match("gitlab%.cfdata%.org[:/](.+)%.git$")
		or remote:match("gitlab%.cfdata%.org[:/](.+)$")

	return project_path
end

-- Helper: Execute glab api command and return parsed JSON
local function glab_api_json(endpoint, fields)
	fields = fields or {}

	-- Check if jq is available
	local jq_check = vim.fn.system("which jq"):gsub("\n", "")
	if jq_check == "" then
		vim.notify("jq is required. Install via: brew install jq", vim.log.levels.ERROR)
		return nil
	end

	-- Build glab api command
	local cmd_parts = { "glab", "api", "--paginate", "-X", "GET" }

	-- Add query parameters to endpoint
	local query_params = {}
	for k, v in pairs(fields) do
		table.insert(query_params, string.format("%s=%s", k, v))
	end

	local full_endpoint = endpoint
	if #query_params > 0 then
		full_endpoint = endpoint .. "?" .. table.concat(query_params, "&")
	end

	-- Quote the endpoint to preserve URL encoding (%)
	table.insert(cmd_parts, "'" .. full_endpoint .. "'")

	-- Execute command and pipe through jq to combine paginated results
	-- glab --paginate outputs multiple JSON arrays (one per page)
	-- jq -s 'add' collects all arrays and concatenates them into a single array
	-- Note: glab api outputs to stderr, so we need 2>&1 to capture it
	local glab_cmd = table.concat(cmd_parts, " ")
	local full_cmd = string.format("/bin/bash -c %q", glab_cmd .. [[ 2>&1 | jq -s 'add']])

	local output = vim.fn.system(full_cmd)

	-- Check for errors
	if vim.v.shell_error ~= 0 then
		vim.notify("GitLab API error (exit code: " .. vim.v.shell_error .. ")", vim.log.levels.ERROR)
		return nil
	end

	-- Trim whitespace
	output = output:gsub("^%s+", ""):gsub("%s+$", "")

	-- Check if output is empty
	if output == "" then
		vim.notify("GitLab API returned empty response", vim.log.levels.ERROR)
		return nil
	end

	-- Parse JSON
	local ok, results = pcall(vim.json.decode, output)
	if not ok then
		vim.notify(
			"Failed to parse GitLab API response. Output preview: " .. output:sub(1, 200),
			vim.log.levels.ERROR
		)
		return nil
	end

	return results
end

-- Helper: Format MR entry for display
local function format_mr_display(entry)
	-- State icon
	local state_icon = "🔴" -- default for closed/merged
	if entry.state == "opened" then
		state_icon = "🟢"
	end

	-- Draft marker
	local draft_marker = ""
	if entry.draft then
		draft_marker = " [DRAFT]"
	end

	-- Author (truncate if too long)
	local author = entry.author and entry.author.username or "unknown"
	author = string.format("%-12s", author):sub(1, 12)

	-- MR number (extract from reference or use iid)
	local mr_num = entry.iid or "?"
	if entry.references and entry.references.full then
		mr_num = entry.references.full:match("!(%d+)$") or mr_num
	end

	-- Title (will be truncated by telescope if needed)
	local title = entry.title or "(no title)"

	return string.format("%s %s | !%-4s | %s%s", state_icon, author, mr_num, title, draft_marker)
end

-- Helper: Create preview content for MR
local function create_mr_preview(entry)
	local lines = {}

	-- Title
	table.insert(lines, "Title: " .. (entry.title or "(no title)"))
	table.insert(lines, "")

	-- Author
	if entry.author then
		local author_name = entry.author.name or entry.author.username
		table.insert(lines, "Author: " .. entry.author.username .. " (" .. author_name .. ")")
	end

	-- Project (from reference)
	if entry.references and entry.references.full then
		table.insert(lines, "Project: " .. entry.references.full)
	end

	-- State and draft
	local state_info = "State: " .. (entry.state or "unknown")
	if entry.draft then
		state_info = state_info .. " (DRAFT)"
	end
	table.insert(lines, state_info)

	-- URL
	if entry.web_url then
		table.insert(lines, "URL: " .. entry.web_url)
	end

	-- Dates
	if entry.created_at then
		table.insert(lines, "Created: " .. entry.created_at)
	end
	if entry.updated_at then
		table.insert(lines, "Updated: " .. entry.updated_at)
	end

	-- Branches
	if entry.source_branch and entry.target_branch then
		table.insert(lines, "Branches: " .. entry.source_branch .. " → " .. entry.target_branch)
	end

	-- Description
	table.insert(lines, "")
	table.insert(lines, "Description:")
	if entry.description and entry.description ~= "" then
		-- Split description by newlines
		for line in entry.description:gmatch("[^\r\n]+") do
			table.insert(lines, line)
		end
	else
		table.insert(lines, "(no description)")
	end

	return lines
end

-- Picker 1: Group/Team MRs
function M.group_mrs(opts)
	-- Check if glab is available
	if not check_glab_available() then
		return
	end

	opts = opts or {}
	local group = opts.group or "cloudflare/cache"
	local group_encoded = urlencode(group)

	-- Build API endpoint
	local endpoint = string.format("groups/%s/merge_requests", group_encoded)

	-- API fields/filters
	local fields = {
		state = opts.state or "opened",
		per_page = opts.per_page or "100",
	}

	-- Show loading notification
	vim.notify("Loading GitLab MRs for " .. group .. "...", vim.log.levels.INFO)

	-- Fetch MRs from GitLab API
	local results = glab_api_json(endpoint, fields)

	if not results then
		return
	end

	if #results == 0 then
		vim.notify("No merge requests found for " .. group, vim.log.levels.WARN)
		return
	end

	-- Create telescope picker
	pickers
		.new(opts, {
			prompt_title = string.format("GitLab MRs - %s (Team)", group),
			finder = finders.new_table({
				results = results,
				entry_maker = function(entry)
					return {
						value = entry,
						display = format_mr_display(entry),
						ordinal = (entry.author and entry.author.username or "")
							.. " "
							.. (entry.title or "")
							.. " "
							.. (entry.references and entry.references.full or ""),
					}
				end,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					if selection and selection.value.web_url then
						-- Open in browser
						vim.fn.system(string.format("open '%s'", selection.value.web_url))
					end
				end)
				return true
			end,
			previewer = previewers.new_buffer_previewer({
				title = "MR Details",
				define_preview = function(self, entry, _)
					local lines = create_mr_preview(entry.value)
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
				end,
			}),
		})
		:find()
end

-- Picker 2: Current Project MRs
function M.current_project_mrs(opts)
	-- Check if glab is available
	if not check_glab_available() then
		return
	end

	opts = opts or {}

	-- Get current project from git remote
	local project_path = get_current_gitlab_project()

	if not project_path then
		vim.notify("Not in a GitLab repository or no remote configured", vim.log.levels.ERROR)
		return
	end

	local project_encoded = urlencode(project_path)

	-- Build API endpoint
	local endpoint = string.format("projects/%s/merge_requests", project_encoded)

	-- API fields/filters
	local fields = {
		state = opts.state or "opened",
		per_page = opts.per_page or "100",
	}

	-- Show loading notification
	vim.notify("Loading GitLab MRs for " .. project_path .. "...", vim.log.levels.INFO)

	-- Fetch MRs from GitLab API
	local results = glab_api_json(endpoint, fields)

	if not results then
		return
	end

	if #results == 0 then
		vim.notify("No merge requests found for " .. project_path, vim.log.levels.WARN)
		return
	end

	-- Create telescope picker (same structure as group_mrs)
	pickers
		.new(opts, {
			prompt_title = string.format("GitLab MRs - %s (Project)", project_path),
			finder = finders.new_table({
				results = results,
				entry_maker = function(entry)
					return {
						value = entry,
						display = format_mr_display(entry),
						ordinal = (entry.author and entry.author.username or "")
							.. " "
							.. (entry.title or "")
							.. " "
							.. (entry.iid or ""),
					}
				end,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					if selection and selection.value.web_url then
						-- Open in browser
						vim.fn.system(string.format("open '%s'", selection.value.web_url))
					end
				end)
				return true
			end,
			previewer = previewers.new_buffer_previewer({
				title = "MR Details",
				define_preview = function(self, entry, _)
					local lines = create_mr_preview(entry.value)
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
				end,
			}),
		})
		:find()
end

return M
