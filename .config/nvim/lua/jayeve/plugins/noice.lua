-- import noice plugin safely
local status, noice = pcall(require, "noice")
if not status then
	local info = debug.getinfo(1, "S").short_src
	print(info, "failed to load")
	return
end

require("notify").setup({
	background_colour = "#000000",
})

noice.setup({
	views = {
		-- an entirely custom view called "bottom_right_compact"
		mini = {
			-- placement relative to the editor window
			relative = "editor",
			position = {
				row = "100%", -- bottom
				col = "100%", -- right
			},
			anchor = "SE", -- grow up/left from bottom-right corner

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
			align = "right",
		},
	},
	routes = {
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
