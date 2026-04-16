-- CSV Column Color Scheme
-- Provides colorful syntax highlighting for CSV files with alternating column colors

-- Color palette for alternating columns (Gruvbox theme)
local column_colors = {
	'#8ec07c', -- Gruvbox aqua/cyan
	'#83a598', -- Gruvbox blue
	'#d3869b', -- Gruvbox purple
	'#fabd2f', -- Gruvbox yellow
	'#fe8019', -- Gruvbox orange
	'#fb4934', -- Gruvbox red
}

-- Define highlight groups for columns
local function setup_column_highlights()
	for i, color in ipairs(column_colors) do
		vim.api.nvim_set_hl(0, 'CsvColumn' .. (i - 1), { fg = color })
	end
end

-- Function to apply column-based coloring
local function colorize_csv_columns()
	local bufnr = vim.api.nvim_get_current_buf()
	local ft = vim.bo[bufnr].filetype
	
	-- Only apply to CSV files
	if ft ~= 'csv' then
		return
	end
	
	-- Create/clear namespace
	local ns_id = vim.api.nvim_create_namespace('csv_rainbow_columns')
	vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
	
	-- Get all lines in buffer
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	
	-- Process each line
	for line_idx, line in ipairs(lines) do
		local col_idx = 0
		local field_start = 0
		local in_quotes = false
		
		-- Parse the CSV line respecting quoted fields
		for i = 1, #line do
			local char = line:sub(i, i)
			
			-- Handle quotes
			if char == '"' then
				-- Check if it's an escaped quote
				if i < #line and line:sub(i + 1, i + 1) == '"' then
					-- Skip escaped quote
				else
					in_quotes = not in_quotes
				end
			elseif char == ',' and not in_quotes then
				-- Found a delimiter - highlight the field
				local hl_group = 'CsvColumn' .. (col_idx % #column_colors)
				vim.api.nvim_buf_add_highlight(bufnr, ns_id, hl_group, line_idx - 1, field_start, i - 1)
				col_idx = col_idx + 1
				field_start = i + 1
			end
		end
		
		-- Highlight the last field in the row
		local hl_group = 'CsvColumn' .. (col_idx % #column_colors)
		vim.api.nvim_buf_add_highlight(bufnr, ns_id, hl_group, line_idx - 1, field_start, -1)
	end
end

-- Setup highlights after colorscheme loads
vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "*",
	callback = setup_column_highlights,
})

-- Apply column highlighting when opening/editing CSV files
vim.api.nvim_create_autocmd({ "BufRead", "BufEnter", "BufWritePost" }, {
	pattern = "*.csv",
	callback = function()
		-- Set filetype if not already set
		if vim.bo.filetype == '' then
			vim.bo.filetype = 'csv'
		end
		-- Apply colorization after a short delay to ensure buffer is loaded
		vim.defer_fn(colorize_csv_columns, 50)
	end,
})

-- Reapply on text changes (with debouncing via timer)
local update_timer = nil
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
	pattern = "*.csv",
	callback = function()
		if update_timer then
			vim.fn.timer_stop(update_timer)
		end
		update_timer = vim.fn.timer_start(200, colorize_csv_columns)
	end,
})

-- Setup immediately
setup_column_highlights()

return {
	setup = setup_column_highlights,
	colorize = colorize_csv_columns,
}
