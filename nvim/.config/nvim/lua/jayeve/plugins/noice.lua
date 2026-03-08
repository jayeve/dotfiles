-- ╔════════════════════════════════════════════════════════════════╗
-- ║  NOICE + NVIM-NOTIFY Configuration (Clean, From Scratch)      ║
-- ╚════════════════════════════════════════════════════════════════╝
--
-- Architecture:
--   • print() → native Vim message area (:messages)
--   • vim.notify() → routed to nvim-notify → bottom-left popups
--   • Regular messages handled natively by Vim
--   • :Noice history shows only notify events (not regular prints)

-- ══════════════════════════════════════════════════════════════════
-- PART 1: Setup nvim-notify (rendering backend)
-- ══════════════════════════════════════════════════════════════════
require("notify").setup({
	-- Visual settings
	background_colour = "#000000",
	fps = 60, -- Smooth animations
	icons = {
		ERROR = "",
		WARN = "",
		INFO = "",
		DEBUG = "",
		TRACE = "✎",
	},

	-- Size constraints
	max_width = 80,
	max_height = 20,
	minimum_width = 40,

	-- Behavior
	level = vim.log.levels.INFO, -- Minimum level to show
	render = "compact", -- Clean left-aligned text
	timeout = 3000, -- 3 seconds before fade
	top_down = false, -- Stack from bottom up

	-- ════════════════════════════════════════════════════════════════
	-- Custom Animation Stages (Bottom-Left Positioning)
	-- ════════════════════════════════════════════════════════════════
	stages = {
		-- Stage 1: Open window at bottom-left
		function(state)
			local stages_util = require("notify.stages.util")
			local next_height = state.message.height + 2

			-- Find available slot stacking from bottom up
			local next_row = stages_util.available_slot(
				state.open_windows,
				next_height,
				stages_util.DIRECTION.BOTTOM_UP
			)

			if not next_row then
				return nil -- No space available
			end

			return {
				relative = "editor",
				anchor = "SW", -- Southwest = bottom-left
				width = state.message.width,
				height = state.message.height,
				col = 0, -- Left edge
				row = next_row, -- Calculated position
				border = "rounded",
				style = "minimal",
				opacity = 100,
			}
		end,

		-- Stage 2: Stable display (fully visible)
		function(state, win)
			return {
				opacity = { 100 },
				col = { 0 },
			}
		end,

		-- Stage 3: Display time (timeout timer)
		function(state, win)
			return {
				col = { 0 },
				time = true, -- Marks this as the timeout stage
			}
		end,

		-- Stage 4: Fade out animation
		function(state, win)
			return {
				width = {
					1,
					frequency = 2.5,
					damping = 0.9,
					complete = function(cur_width)
						return cur_width < 3
					end,
				},
				opacity = {
					0,
					frequency = 2,
					complete = function(cur_opacity)
						return cur_opacity <= 4
					end,
				},
				col = { 0 },
			}
		end,
	},
})

-- Set as default notify handler
vim.notify = require("notify")

-- ══════════════════════════════════════════════════════════════════
-- PART 2: Setup noice.nvim (message capture & routing)
-- ══════════════════════════════════════════════════════════════════
require("noice").setup({

	-- ────────────────────────────────────────────────────────────────
	-- CMDLINE: Enhanced command-line UI
	-- ────────────────────────────────────────────────────────────────
	cmdline = {
		enabled = true,
		view = "cmdline_popup", -- Floating popup (or "cmdline" for classic)

		format = {
			-- Command mode (:)
			cmdline = {
				pattern = "^:",
				icon = "",
				lang = "vim",
				title = "",
			},

			-- Search (/)
			search_down = {
				kind = "search",
				pattern = "^/",
				icon = " ",
				lang = "regex",
				title = "",
			},

			-- Search backward (?)
			search_up = {
				kind = "search",
				pattern = "^%?",
				icon = " ",
				lang = "regex",
				title = "",
			},

			-- Shell command (:!)
			filter = {
				pattern = "^:%s*!",
				icon = "$",
				lang = "bash",
				title = "",
			},

			-- Lua (:lua, :=)
			lua = {
				pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" },
				icon = "",
				lang = "lua",
				title = "",
			},

			-- Help (:help)
			help = {
				pattern = "^:%s*he?l?p?%s+",
				icon = "",
				title = "",
			},

			-- Input prompts
			input = {
				view = "cmdline_input",
				icon = "󰥻 ",
			},
		},
	},

	-- ────────────────────────────────────────────────────────────────
	-- MESSAGES: Disable noice message handling - use native Vim
	-- ────────────────────────────────────────────────────────────────
	messages = {
		enabled = false, -- Let Vim handle messages natively
	},

	-- ────────────────────────────────────────────────────────────────
	-- POPUPMENU: Enhanced completion menu
	-- ────────────────────────────────────────────────────────────────
	popupmenu = {
		enabled = true,
		backend = "nui",
	},

	-- ────────────────────────────────────────────────────────────────
	-- ROUTES: Smart message routing rules
	-- ────────────────────────────────────────────────────────────────
	routes = {
		-- ╔═══════════════════════════════════════════════════════════╗
		-- ║  RULE 1: vim.notify() → nvim-notify (bottom-left popup)  ║
		-- ╚═══════════════════════════════════════════════════════════╝
		{
			filter = { event = "notify" },
			view = "notify",
		},

		-- ╔═══════════════════════════════════════════════════════════╗
		-- ║  RULE 2: Skip annoying spam messages                     ║
		-- ╚═══════════════════════════════════════════════════════════╝
		{
			filter = {
				event = "msg_show",
				any = {
					{ find = "written" },
					{ find = "^%d+ lines" },
					{ find = "^%d+L, %d+B$" },
					{ find = "%-%-No lines in buffer%-%-" },
				},
			},
			opts = { skip = true },
		},

		-- ╔═══════════════════════════════════════════════════════════╗
		-- ║  RULE 3: Long messages → auto-open in split              ║
		-- ╚═══════════════════════════════════════════════════════════╝
		{
			filter = {
				event = "msg_show",
				min_height = 10,
			},
			view = "split",
		},

		-- ╔═══════════════════════════════════════════════════════════╗
		-- ║  RULE 4: Treesitter install progress → mini view         ║
		-- ╚═══════════════════════════════════════════════════════════╝
		{
			filter = {
				event = "msg_show",
				find = "TreeSitter",
			},
			view = "mini",
		},
	},

	-- ────────────────────────────────────────────────────────────────
	-- NOTIFY: Ensure notify events use nvim-notify
	-- ────────────────────────────────────────────────────────────────
	notify = {
		enabled = true,
		view = "notify",
	},

	-- ────────────────────────────────────────────────────────────────
	-- LSP: Enhanced LSP UI
	-- ────────────────────────────────────────────────────────────────
	lsp = {
		-- LSP progress (installing, indexing, etc.)
		progress = {
			enabled = true,
			format = "lsp_progress",
			format_done = "lsp_progress_done",
			throttle = 1000 / 30, -- 30 FPS
			view = "mini", -- Separate mini view (not bottom-left!)
		},

		-- Override rendering to use treesitter
		override = {
			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
			["vim.lsp.util.stylize_markdown"] = true,
			["cmp.entry.get_documentation"] = true,
		},

		-- Hover documentation
		hover = {
			enabled = true,
			silent = false,
		},

		-- Signature help
		signature = {
			enabled = true,
			auto_open = {
				enabled = true,
				trigger = true,
				luasnip = true,
				throttle = 50,
			},
		},

		-- LSP messages
		message = {
			enabled = true,
			view = "notify",
		},
	},

	-- ────────────────────────────────────────────────────────────────
	-- PRESETS: Quality of life features
	-- ────────────────────────────────────────────────────────────────
	presets = {
		bottom_search = true, -- Classic bottom cmdline for search
		command_palette = true, -- Center cmdline and popupmenu
		long_message_to_split = true, -- Long messages → split (redundant with routes but good)
		inc_rename = false,
		lsp_doc_border = false,
	},

	-- ────────────────────────────────────────────────────────────────
	-- VIEWS: Customize view behavior
	-- ────────────────────────────────────────────────────────────────
	views = {
		-- Mini view for LSP progress (top-right, not conflicting with notify popups)
		mini = {
			backend = "mini",
			relative = "editor",
			align = "message-right",
			timeout = 2000,
			reverse = true,
			focusable = false,
			position = {
				row = "95%", -- Near bottom but above notifications
				col = "100%", -- Right edge
			},
			size = "auto",
			border = {
				style = "none",
			},
			zindex = 100,
			win_options = {
				winblend = 0,
				winhighlight = {
					Normal = "NoiceMini",
					IncSearch = "",
					CurSearch = "",
					Search = "",
				},
			},
		},

		-- Popup for :Noice last, errors, etc.
		popup = {
			backend = "popup",
			relative = "editor",
			position = "50%",
			size = {
				width = "80%",
				height = "60%",
			},
			border = {
				style = "rounded",
				padding = { 0, 1 },
			},
			win_options = {
				winblend = 10,
				winhighlight = {
					Normal = "NoicePopup",
					FloatBorder = "NoicePopupBorder",
				},
			},
		},

		-- Split for message history
		split = {
			backend = "split",
			enter = true,
			relative = "editor",
			position = "bottom",
			size = "40%",
			close = {
				keys = { "q", "<Esc>" },
			},
			win_options = {
				winhighlight = {
					Normal = "NoiceSplit",
					FloatBorder = "NoiceSplitBorder",
				},
			},
		},
	},

	-- ────────────────────────────────────────────────────────────────
	-- COMMANDS: History access commands
	-- ────────────────────────────────────────────────────────────────
	commands = {
		-- :Noice (or :Noice history)
		history = {
			view = "split",
			opts = { enter = true, format = "details" },
			filter = {
				any = {
					{ event = "notify" },
					{ error = true },
					{ warning = true },
					{ event = "msg_show", kind = { "" } },
					{ event = "lsp", kind = "message" },
				},
			},
		},

		-- :Noice last
		last = {
			view = "popup",
			opts = { enter = true, format = "details" },
			filter = {
				any = {
					{ event = "notify" },
					{ error = true },
					{ warning = true },
					{ event = "msg_show", kind = { "" } },
					{ event = "lsp", kind = "message" },
				},
			},
			filter_opts = { count = 1 },
		},

		-- :Noice errors
		errors = {
			view = "popup",
			opts = { enter = true, format = "details" },
			filter = { error = true },
			filter_opts = { reverse = true },
		},

		-- :Noice dismiss
		dismiss = {
			view = "notify",
			opts = { stop = false },
			filter = {},
		},
	},

	-- ────────────────────────────────────────────────────────────────
	-- FORMAT: Message formatting
	-- ────────────────────────────────────────────────────────────────
	format = {
		default = { "{message}" },
		notify = { "{message}" },
		details = {
			"{level} ",
			"{date} ",
			"{event}",
			{ "{kind}", before = { ".", hl_group = "NoiceFormatKind" } },
			" ",
			"{title} ",
			"{message}",
		},
	},
})

-- ══════════════════════════════════════════════════════════════════
-- PART 3: Telescope Integration (if telescope is available)
-- ══════════════════════════════════════════════════════════════════
local telescope_ok, telescope = pcall(require, "telescope")
if telescope_ok then
	telescope.load_extension("noice")
end
