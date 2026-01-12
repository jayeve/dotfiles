require("jayeve.utils")
-- Code used for the extractor system for language learning
local M = {}
local function parse_time(time_str)
	print("parse_time() raw input:", vim.inspect(time_str))

	-- Trim whitespace
	time_str = time_str:match("^%s*(.-)%s*$")
	print("trimmed:", vim.inspect(time_str))

	-- Try H:MM:SS(.xx)
	local h, m, s, frac = time_str:match("^(%d+):(%d%d):(%d%d)%.?(%d*)$")

	print(
		"H:MM:SS match ->",
		"h=",
		vim.inspect(h),
		"m=",
		vim.inspect(m),
		"s=",
		vim.inspect(s),
		"frac=",
		vim.inspect(frac)
	)

	if h then
		return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s) + (frac and tonumber("0." .. frac) or 0), frac ~= nil
	end

	-- 🔍 DEBUG THIS LINE
	local m2, s2, frac2 = time_str:match("^(%d+):(%d%d)%.?(%d*)$")

	print("M:SS match ->", "m2=", vim.inspect(m2), "s2=", vim.inspect(s2), "frac2=", vim.inspect(frac2))

	if m2 then
		return tonumber(m2) * 60 + tonumber(s2) + (frac2 and tonumber("0." .. frac2) or 0), frac2 ~= nil
	end

	-- just seconds (integer or fraction i.e. 2, 2.4, 76, etc.)
	local sec = tonumber(time_str)
	if sec then
		-- keep_fraction true if contains decimal
		local has_fraction = time_str:match("%.") ~= nil
		return sec, has_fraction
	end

	-- print("❌ No match for time_str:", vim.inspect(time_str))
	return nil
end

local function format_time(seconds, keep_fraction)
	local h = math.floor(seconds / 3600)
	local rem = seconds - (h * 3600)
	local m = math.floor(rem / 60)
	local s = rem - (m * 60)

	if h > 0 then
		if keep_fraction then
			return string.format("%02d:%02d:%05.2f", h, m, s)
		else
			return string.format("%02d:%02d:%02d", h, m, math.floor(s + 0.5))
		end
	else
		if keep_fraction then
			return string.format("%02d:%05.2f", m, s)
		else
			return string.format("%02d:%02d", m, math.floor(s + 0.5))
		end
	end
end

local function trim(s)
	return s:match("^%s*(.-)%s*$")
end

local function add_seconds_and_normalize(seconds_to_add)
	local line = vim.api.nvim_get_current_line()

	local cols = {}
	for field in line:gmatch("([^,]+)") do
		table.insert(cols, trim(field))
	end

	if #cols < 3 then
		vim.notify("Not enough CSV columns", vim.log.levels.ERROR, { title = "jayeve.extractor" })
		return
	end

	local start_seconds, start_frac = parse_time(cols[2])
	if not start_seconds then
		vim.notify("Invalid time in column 2: " .. cols[2], vim.log.levels.ERROR, { title = "jayeve.extractor" })
		return
	end

	local end_seconds = start_seconds + seconds_to_add
	local keep_fraction = start_frac or seconds_to_add % 1 ~= 0

	cols[2] = format_time(start_seconds, start_frac)
	cols[3] = format_time(end_seconds, keep_fraction)

	vim.api.nvim_set_current_line(table.concat(cols, ","))
end
local function set_start_time(new_time_str)
	local line = vim.api.nvim_get_current_line()

	local cols = {}
	for field in line:gmatch("([^,]+)") do
		table.insert(cols, trim(field))
	end

	if #cols < 3 then
		vim.notify("Not enough CSV columns", vim.log.levels.ERROR, { title = "jayeve.extractor" })
		return
	end

	local seconds, had_fraction = parse_time(new_time_str)
	if not seconds then
		vim.notify("Invalid time string: " .. new_time_str, vim.log.levels.ERROR, { title = "jayeve.extractor" })
		return
	end

	cols[2] = format_time(seconds, had_fraction)
	cols[3] = format_time(seconds + 5, had_fraction)

	vim.api.nvim_set_current_line(table.concat(cols, ","))
end
M.SetStartTime = function()
	local input = vim.fn.input("Set start time (HH:MM:SS.xx): ")
	set_start_time(input)
end
function M.subtract_seconds_from_start(seconds_to_subtract)
	local line = vim.api.nvim_get_current_line()

	-- Simple CSV split + trim
	local cols = {}
	for field in line:gmatch("([^,]+)") do
		table.insert(cols, trim(field))
	end

	if #cols < 2 then
		vim.notify("Not enough CSV columns", vim.log.levels.ERROR, { title = "jayeve.extractor" })
		return
	end

	local start_seconds, had_fraction = parse_time(cols[2])
	if not start_seconds then
		vim.notify("Invalid time in column 2: " .. cols[2], vim.log.levels.ERROR, { title = "jayeve.extractor" })
		return
	end

	local new_start = start_seconds - seconds_to_subtract
	if new_start < 0 then
		new_start = 0
	end

	cols[2] = format_time(new_start, had_fraction or seconds_to_subtract % 1 ~= 0)

	vim.api.nvim_set_current_line(table.concat(cols, ","))
end
function M.add_seconds_to_start(seconds_to_add)
	local line = vim.api.nvim_get_current_line()

	-- Simple CSV split + trim
	local cols = {}
	for field in line:gmatch("([^,]+)") do
		table.insert(cols, trim(field))
	end

	if #cols < 2 then
		vim.notify("Not enough CSV columns", vim.log.levels.ERROR, { title = "jayeve.extractor" })
		return
	end

	local start_seconds, had_fraction = parse_time(cols[2])
	if not start_seconds then
		vim.notify("Invalid time in column 2: " .. cols[2], vim.log.levels.ERROR, { title = "jayeve.extractor" })
		return
	end

	local new_start = start_seconds + seconds_to_add

	cols[2] = format_time(new_start, had_fraction or seconds_to_add % 1 ~= 0)

	vim.api.nvim_set_current_line(table.concat(cols, ","))
end
function M.add_seconds_to_end(seconds_to_add)
	seconds_to_add = tonumber(seconds_to_add)
	if not seconds_to_add then
		vim.notify("Invalid seconds value", vim.log.levels.ERROR, { title = "jayeve.extractor" })
		return
	end

	local line = vim.api.nvim_get_current_line()
	local cols = {}
	for field in line:gmatch("([^,]+)") do
		table.insert(cols, trim(field))
	end

	if #cols < 3 then
		vim.notify("Not enough CSV columns", vim.log.levels.ERROR, { title = "jayeve.extractor" })
		return
	end

	local end_seconds, end_frac = parse_time(cols[3])
	if not end_seconds then
		vim.notify("Invalid time in column 3: " .. cols[3], vim.log.levels.ERROR, { title = "jayeve.extractor" })
		return
	end

	local new_end = end_seconds + seconds_to_add
	local keep_fraction = end_frac or math.abs(seconds_to_add % 1) > 0

	cols[3] = format_time(new_end, keep_fraction)

	vim.api.nvim_set_current_line(table.concat(cols, ","))
end
function M.subtract_seconds_from_end(seconds_to_subtract)
	seconds_to_subtract = tonumber(seconds_to_subtract)
	if not seconds_to_subtract then
		vim.notify("Invalid seconds value", vim.log.levels.ERROR, { title = "jayeve.extractor" })
		return
	end

	local line = vim.api.nvim_get_current_line()
	local cols = {}
	for field in line:gmatch("([^,]+)") do
		table.insert(cols, trim(field))
	end

	if #cols < 3 then
		vim.notify("Not enough CSV columns", vim.log.levels.ERROR, { title = "jayeve.extractor" })
		return
	end

	local end_seconds, end_frac = parse_time(cols[3])
	if not end_seconds then
		vim.notify("Invalid time in column 3: " .. cols[3], vim.log.levels.ERROR, { title = "jayeve.extractor" })
		return
	end

	local new_end = end_seconds - seconds_to_subtract
	if new_end < 0 then
		new_end = 0
	end

	local keep_fraction = end_frac or math.abs(seconds_to_subtract % 1) > 0
	cols[3] = format_time(new_end, keep_fraction)

	vim.api.nvim_set_current_line(table.concat(cols, ","))
end
M.AddSecondsToStart = function()
	local input = vim.fn.input("Seconds to add to Start: ")
	local seconds = tonumber(input)

	if not seconds then
		vim.notify("Invalid number", vim.log.levels.ERROR, { title = "jayeve.extractor" })
		return
	end

	M.add_seconds_to_start(seconds)
end
M.AddSecondsToEnd = function()
	local input = vim.fn.input("Seconds to add to End: ")
	local seconds = tonumber(input)

	if not seconds then
		vim.notify("Invalid number", vim.log.levels.ERROR, { title = "jayeve.extractor" })
		return
	end

	M.add_seconds_to_end(seconds)
end
M.SubtractSecondsFromStart = function()
	local input = vim.fn.input("Seconds to subtract from Start: ")
	local seconds = tonumber(input)

	if not seconds then
		vim.notify("Invalid number", vim.log.levels.ERROR, { title = "jayeve.extractor" })
		return
	end

	M.subtract_seconds_from_start(seconds)
end
M.SubtractSecondsFromEnd = function()
	local input = vim.fn.input("Seconds to subtract from End: ")
	local seconds = tonumber(input)

	if not seconds then
		vim.notify("Invalid number", vim.log.levels.ERROR, { title = "jayeve.extractor" })
		return
	end

	M.subtract_seconds_from_end(seconds)
end
M.SetDifference = function()
	local input = vim.fn.input("Seconds to add (e.g. 1.46): ")
	local seconds = tonumber(input)

	if not seconds then
		vim.notify("Invalid number", vim.log.levels.ERROR, { title = "jayeve.extractor" })
		return
	end

	add_seconds_and_normalize(seconds)
end

-- Smart defaults: use /Volumes/sandis1/languages if it exists, otherwise ~/Downloads
local function get_default_downloads_path()
	local primary = "/Volumes/sandisk1/languages"
	if vim.fn.isdirectory(primary) == 1 then
		return primary
	else
		vim.notify(
			"directory /Volumes/sandisk1/languages/ not found, using ~/Downloads/",
			vim.log.levels.WARN,
			{ title = "jayeve.extractor" }
		)
		return vim.fn.expand("~/Downloads")
	end
end

-- Find the project root (where Cargo.toml is)
local function find_project_root()
	local current_file = vim.fn.expand("%:p")
	local current_dir = vim.fn.fnamemodify(current_file, ":h")

	-- Search up the directory tree for Cargo.toml
	while current_dir ~= "/" do
		if vim.fn.filereadable(current_dir .. "/Cargo.toml") == 1 then
			return current_dir
		end
		current_dir = vim.fn.fnamemodify(current_dir, ":h")
	end

	return nil
end

-- Get the extractor binary path, building if necessary
local function get_extractor_binary(callback)
	local project_root = find_project_root()
	if not project_root then
		vim.notify("Could not find Cargo.toml (project root)", vim.log.levels.ERROR, { title = "jayeve.extractor" })
		return
	end

	local binary_path = project_root .. "/target/debug/extractor"

	vim.notify("Building extractor binary...", vim.log.levels.INFO, { title = "jayeve.extractor" })

	vim.fn.jobstart("cargo build", {
		cwd = project_root,
		on_exit = function(_, exit_code)
			if exit_code == 0 then
				vim.notify("Build complete!", vim.log.levels.INFO, { title = "jayeve.extractor" })
				callback(binary_path)
			else
				vim.notify(
					"Build failed (exit code: " .. exit_code .. ")",
					vim.log.levels.ERROR,
					{ title = "jayeve.extractor" }
				)
			end
		end,
		on_stdout = function(_, data)
			if data and #data > 0 then
				for _, line in ipairs(data) do
					if line ~= "" then
						vim.api.nvim_echo({ { "[extractor] " .. line, "Normal" } }, false, {})
					end
				end
			end
		end,
		on_stderr = function(_, data)
			if data and #data > 0 then
				for _, line in ipairs(data) do
					if line ~= "" then
						vim.api.nvim_echo({ { "[extractor] " .. line, "WarningMsg" } }, false, {})
					end
				end
			end
		end,
	})
end

M.play_clip = function()
	local current_file = vim.fn.expand("%:p")
	local line_number = vim.fn.line(".")

	if not current_file:match("%.csv$") then
		vim.notify("Not in a CSV file!", vim.log.levels.WARN, { title = "jayeve.extractor" })
		return
	end

	get_extractor_binary(function(binary_path)
		local cmd = string.format(
			"%s play %s -n %d",
			vim.fn.shellescape(binary_path),
			vim.fn.shellescape(current_file),
			math.max(1, line_number - 1)
		)

		local downloads_path = get_default_downloads_path()
		-- Add downloads path if configured
		if downloads_path then
			cmd = cmd .. " -p " .. vim.fn.shellescape(downloads_path)
		end

		-- vim.notify(
		-- 	string.format("Playing clip from line %d...", line_number),
		-- 	vim.log.levels.INFO,
		-- 	{ title = "jayeve.extractor" }
		-- )

		-- Wrap in explicit shell array format to ensure child process output is captured
		vim.fn.jobstart({ "sh", "-c", cmd }, {
			stdout_buffered = false,
			stderr_buffered = false,
			on_exit = function(_, exit_code)
				if exit_code ~= 0 then
					vim.notify(
						string.format("Playback failed (exit code: %d)", exit_code),
						vim.log.levels.ERROR,
						{ title = "jayeve.extractor" }
					)
				end
			end,
			on_stdout = function(_, data)
				if data and #data > 0 then
					for _, line in ipairs(data) do
						if line ~= "" then
							vim.api.nvim_echo({ { "[extractor] " .. line, "Normal" } }, false, {})
						end
					end
				end
			end,
			on_stderr = function(_, data)
				if data and #data > 0 then
					for _, line in ipairs(data) do
						if line ~= "" then
							vim.api.nvim_echo({ { "[extractor] " .. line, "Normal" } }, false, {})
						end
					end
				end
			end,
		})
	end)
end

vim.api.nvim_create_user_command("PlayClip", M.play_clip, {})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "csv",
	callback = function()
		vim.keymap.set("n", "<leader>p", M.play_clip, {
			buffer = true,
			desc = "Play audio clip for current line",
		})
	end,
})
vim.api.nvim_create_user_command("PlayClip", M.play_clip, {})

return M
