-- import noice plugin safely
local status, noice = pcall(require, "noice")
if not status then
	local info = debug.getinfo(1, "S").short_src
	print(info, "failed to load")
	return
end

local stages_util = require("notify.stages.util")

require("notify").setup({
	background_colour = "#000000",
	top_down = false, -- Stack from bottom up
	render = "compact", -- Use compact render style for left-aligned text
	timeout = 3000, -- 3 seconds
	stages = {
		function(state)
			local next_height = state.message.height + 2
			local next_row =
				stages_util.available_slot(state.open_windows, next_height, stages_util.DIRECTION.BOTTOM_UP)
			if not next_row then
				return nil
			end
			return {
				relative = "editor",
				anchor = "SW",
				width = state.message.width,
				height = state.message.height,
				col = 0, -- Left side
				row = next_row,
				border = "rounded",
				style = "minimal",
			}
		end,
	},
})

noice.setup({
	views = {
		-- an entirely custom view called "bottom_right_compact"
		mini = {
			-- placement relative to the editor window
			relative = "editor",
			position = {
				row = "100%", -- bottom
				col = "0%", -- left
			},
			anchor = "SW", -- grow up/right from bottom-left corner

			-- size controls
			size = {
				width = "auto", -- or a function / percent
				height = "auto", -- "auto" lets it shrink/grow
			},

			-- visual styling
			border = {
				style = "rounded",
				padding = { 0, 1 },
			},

			-- window options: blending, highlights, etc.
			win_options = {
				winblend = 10,
				winhighlight = {
					Normal = "Normal",
					FloatBorder = "DiagnosticInfo",
				},
			},
			align = "left",
		},
	},
	routes = {
		{
			filter = {
				event = "notify",
			},
			view = "mini",
		},
		{
			filter = {
				event = "msg_show",
				kind = "",
			},
			opts = { skip = true },
		},
	},
	notify = {
		view = "mini",
	},
	sections = {
		lualine_x = {
			{
				noice.api.statusline.mode.get,
				cond = noice.api.statusline.mode.has,
				color = { fg = "#ff9e64" },
			},
		},
	},
	messages = {
		enabled = false,
	},
	-- avoid superfluous messages (from mason, lines written, etc)
	lsp = {
		progress = {
			enabled = false,
		},
		-- override markdown rendering so that **cmp** and other plugins use **Treesitter**
		override = {
			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
			["vim.lsp.util.stylize_markdown"] = true,
			["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
		},
	},
	-- you can enable a preset for easier configuration
	presets = {
		bottom_search = true, -- use a classic bottom cmdline for search
		command_palette = true, -- position the cmdline and popupmenu together
		long_message_to_split = true, -- long messages will be sent to a split
		inc_rename = false, -- enables an input dialog for inc-rename.nvim
		-- lsp_doc_border = false, -- add a border to hover docs and signature help
	},
})

require("telescope").load_extension("noice")
