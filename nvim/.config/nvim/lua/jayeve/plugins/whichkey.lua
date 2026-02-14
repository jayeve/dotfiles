local function safeCall(import)
	local status, import_ = pcall(require, import)
	if not status then
		local info = debug.getinfo(1, "S").short_src
		print(info .. " failed to load " .. import)
	end
	return import_
end

local harpoon_mark = safeCall("harpoon.mark")
local harpoon_ui = safeCall("harpoon.ui")
local lualine_nightfly = safeCall("lualine.themes.nightfly")
local utils = require("jayeve.utils")
local extractor = require("jayeve.extractor")
local prj = require("jayeve.plugins.prj")

local function togglePurple()
	if vim.g.colors_name == "neovim_purple" then
		vim.cmd("colorscheme gruvbox")
		require("lualine").setup({
			options = {
				theme = lualine_nightfly,
			},
		})
	else
		vim.cmd("colorscheme neovim_purple")
		require("lualine").setup({
			options = {
				theme = "neovim_purple",
			},
		})
	end
end

local which_key = safeCall("which-key")
local gitlinker = safeCall("gitlinker")
local actions = safeCall("gitlinker.actions")

---------------------
-- General Keymaps
---------------------

which_key.add({
	-- Insert mode keybindings
	{ "jk", "<ESC>", desc = "exit insert mode", mode = "i" },

	-- Normal mode general keybindings
	{
		";",
		function()
			vim.cmd("nohlsearch")
		end,
		desc = "clear search highlights",
		mode = "n",
	},
	{ "x", '"_x', desc = "delete char without yanking", mode = "n" },
	{ "<leader><leader>", "/", desc = "search", mode = "n" },

	-- Increment/decrement numbers
	{ "<leader>+", "<C-a>", desc = "increment number", mode = "n" },
	{ "<leader>-", "<C-x>", desc = "decrement number", mode = "n" },

	-- Window management
	{ "<leader>s", group = "split/session" },
	{ "<leader>sv", "<C-w>v", desc = "split window vertically", mode = "n" },
	{ "<leader>sh", "<C-w>s", desc = "split window horizontally", mode = "n" },
	{ "<leader>se", "<C-w>=", desc = "make split windows equal", mode = "n" },
	{ "<leader>sx", ":close<CR>", desc = "close current split window", mode = "n" },
	{ "<leader>sm", ":MaximizerToggle<CR>", desc = "toggle split window maximization", mode = "n" },

	-- Tab management
	{ "<leader>t", group = "tab" },
	{ "<leader>to", ":tabnew<CR>", desc = "open new tab", mode = "n" },
	{ "<leader>tx", ":tabclose<CR>", desc = "close current tab", mode = "n" },
	{ "<leader>tn", ":tabn<CR>", desc = "go to next tab", mode = "n" },
	{ "<leader>tp", ":tabp<CR>", desc = "go to previous tab", mode = "n" },

	-- NvimTree
	{ "<leader>e", ":NvimTreeToggle<CR>", desc = "toggle file explorer", mode = "n" },

	-- Telescope
	{
		"<leader><tab>",
		"<cmd>Telescope find_files find_command=rg,--files,--hidden,--glob,!.git/*<cr>",
		desc = "find files (hidden, respects .gitignore)",
		mode = "n",
	},
	{ "<leader>r", "<cmd>Telescope live_grep<cr>", desc = "live grep", mode = "n" },
	{ "<leader>c", "<cmd>Telescope grep_string<cr>", desc = "grep string under cursor", mode = "n" },
	{ "<leader>o", "<cmd>Telescope buffers<cr>", desc = "list open buffers", mode = "n" },
	{ "<leader>L", "<cmd>Telescope jumplist<cr>", desc = "jumplist", mode = "n" },
	{ "<leader>j", "<cmd>Telescope zoxide list<cr>", desc = "zoxide projects list", mode = "n" },
	{ "<leader>k", "<cmd>Telescope frecency<cr>", desc = "file frecency", mode = "n" },
	{ "<leader>u", "<cmd>Telescope harpoon marks<cr>", desc = "harpoon marks", mode = "n" },
	{ "<leader>M", "<cmd>Telescope metals commands<cr>", desc = "metals commands", mode = "n" },

	-- Telescope git commands
	{ "<leader>g", group = "git" },
	{ "<leader>gC", "<cmd>Telescope git_commits<cr>", desc = "git commits", mode = "n" },
	{ "<leader>gfc", "<cmd>Telescope git_bcommits<cr>", desc = "git file commits", mode = "n" },
	{ "<leader>gb", "<cmd>Telescope git_branches<cr>", desc = "git branches", mode = "n" },
	{ "<leader>gs", "<cmd>Telescope git_status<cr>", desc = "git status", mode = "n" },
	{ "<leader>gwc", "<cmd>Telescope git_worktree create_git_worktree<cr>", desc = "create git worktree", mode = "n" },
	{
		"<leader>gwl",
		"<cmd>Telescope git_worktree git_worktrees<cr>",
		desc = "switch and delete git worktree",
		mode = "n",
	},
	-- Telescope history commands
	{ "<leader>h", group = "history" },
	{ "<leader>hc", "<cmd>Telescope command_history<cr>", desc = "command history", mode = "n" },
	{ "<leader>hy", "<cmd>Telescope neoclip<cr>", desc = "yank history", mode = "n" },
	{ "<leader>hf", "<cmd>Telescope oldfiles<cr>", desc = "file history", mode = "n" },
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "csv",
	callback = function()
		which_key.add({
			-- Extractor audio clip controls
			{
				",j",
				extractor.play_clip,
				desc = "play audio clip for current line",
				mode = "n",
			},
			{
				",a",
				function()
					extractor.subtract_seconds_from_start(0.25)
				end,
				desc = "subtract 0.25s from START of clip",
				mode = "n",
			},
			{
				",s",
				function()
					extractor.add_seconds_to_start(0.25)
				end,
				desc = "add 0.25s to START of clip",
				mode = "n",
			},
			{
				",d",
				function()
					extractor.subtract_seconds_from_end(0.25)
				end,
				desc = "subtract 0.25s from END of clip",
				mode = "n",
			},
			{
				",f",
				function()
					extractor.add_seconds_to_end(0.25)
				end,
				desc = "add 0.25s to END of clip",
				mode = "n",
			},
			{
				",q",
				extractor.SubtractSecondsFromStart,
				desc = "subtract custom time from START of clip",
				mode = "n",
			},
			{
				",w",
				extractor.AddSecondsToStart,
				desc = "add custom time to START of clip",
				mode = "n",
			},
			{
				",e",
				extractor.SubtractSecondsFromEnd,
				desc = "subtract custom time from END of clip",
				mode = "n",
			},
			{
				",r",
				extractor.AddSecondsToEnd,
				desc = "add custom time to END of clip",
				mode = "n",
			},
			{
				",,",
				extractor.SetStartTime,
				desc = "set start time for clip",
				mode = "n",
			},
			{
				",<leader>",
				extractor.SetDifference,
				desc = "set difference for clip audio",
				mode = "n",
			},
		})
	end,
})

which_key.add({
	-- History
	-- Write
	{ "<leader>w", group = "write/workspace" },
	{
		"<leader>ww",
		function()
			vim.cmd("noautocmd write")
		end,
		desc = "write file without triggering auto commands",
		mode = "n",
	},

	-- Utility keybindings
	{
		"<leader>H",
		function()
			vim.cmd("edit ~/dotfiles/HOTKEYS.md")
		end,
		desc = "open hotkey reference",
		mode = "n",
	},
	{ "<leader>N", utils.open_personal_notes, desc = "open this week's personal notes", mode = "n" },
	{ "<leader>n", utils.open_notes, desc = "open this week's weekly notes", mode = "n" },
	{
		"<leader>l",
		function()
			utils.copy_file_path_to_clipboard(true, true)
		end,
		desc = "copy full file path at current line",
		mode = "n",
	},
	{
		"<leader>f",
		function()
			utils.copy_file_path_to_clipboard(false, true)
		end,
		desc = "copy full file path",
		mode = "n",
	},
	{
		"<leader>p",
		function()
			prj.gitlab_project_picker()
		end,
		desc = "GitLab project picker (~9K repos)",
		mode = "n",
	},
	{
		"<leader>b",
		function()
			utils.copy_file_path_to_clipboard(false, false)
		end,
		desc = "copy file name",
		mode = "n",
	},
	{ "<leader>d", utils.copy_directory_to_clipboard, desc = "copy current buffer directory", mode = "n" },

	-- Git operations (additional)
	{ "<leader>gc", utils.open_gitlab_link_for_current_line, desc = "open gitlab MR or commit", mode = "n" },
	{ "<leader>gg", utils.open_repo_url, desc = "open the git repository URL", mode = "n" },
	{ "<leader>gr", utils.open_repo_url, desc = "open the git repository URL", mode = "n" },
	{ "<leader>g.", utils.cd_to_git_root, desc = "cd into cur buf's git root", mode = "n" },

	-- Tmux & Sessions
	{
		"<leader>m",
		function()
			prj.tmux_session_picker()
		end,
		desc = "switch tmux session",
		mode = "n",
	},

	-- Display & UI
	{ "<leader>P", togglePurple, desc = "toggle purple display", mode = "n" },
	{
		"<leader>a",
		function()
			vim.api.nvim_call_function("ToggleRTL", {})
		end,
		desc = "toggle Arabic (left -> right) mode",
		mode = "n",
	},
	{
		"<leader>z",
		function()
			vim.cmd("ZenMode")
		end,
		desc = "zen mode",
		mode = "n",
	},
	{
		"<leader>=",
		function()
			vim.api.nvim_input("<C-w>=")
		end,
		desc = "equalize windows",
		mode = "n",
	},
	{
		"<leader>I",
		function()
			vim.cmd("IBLToggle")
		end,
		desc = "toggle indent marker lines",
		mode = "n",
	},

	-- Harpoon
	{ "<leader>i", group = "harpoon" },
	{ "<leader>ia", harpoon_mark.add_file, desc = "add file to harpoon", mode = "n" },
	{ "<leader>ir", harpoon_mark.remove_file, desc = "remove file from harpoon", mode = "n" },
	{ "<leader>il", harpoon_ui.toggle_quick_menu, desc = "toggle quick menu", mode = "n" },

	-- Buffer operations
	{
		"<leader>q",
		function()
			vim.cmd("bdelete")
		end,
		desc = "close current buffer",
		mode = "n",
	},
	{
		"<leader>B",
		function()
			gitlinker.get_repo_url({ action_callback = actions.open_in_browser })
		end,
		desc = "open ref link in browser",
		mode = "n",
	},

	-- Directory navigation
	{ "<leader>.", utils.cd_to_current_buf_directory, desc = "cd into cur buf's dir", mode = "n" },
	{ "<c-g>", utils.show_cur_location, desc = "show current location", mode = "n" },

	-- Quickfix navigation
	{
		"]q",
		function()
			vim.cmd("cnext")
		end,
		desc = "next in quickfix list",
		mode = "n",
	},
	{
		"[q",
		function()
			vim.cmd("cprev")
		end,
		desc = "prev in quickfix list",
		mode = "n",
	},
})

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
		-- Enable completion triggered by <c-x><c-o>
		vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

		-- Buffer local mappings
		which_key.add({
			-- LSP call hierarchy
			{
				",qi",
				function()
					vim.lsp.buf.incoming_calls()
				end,
				desc = "incoming calls",
				mode = "n",
				buffer = ev.buf,
			},
			{
				",qo",
				function()
					vim.lsp.buf.outgoing_calls()
				end,
				desc = "outgoing calls",
				mode = "n",
				buffer = ev.buf,
			},

			-- LSP navigation
			{
				"gD",
				function()
					vim.lsp.buf.declaration()
				end,
				desc = "go to declaration",
				mode = "n",
				buffer = ev.buf,
			},
			{
				"gd",
				function()
					vim.lsp.buf.definition()
				end,
				desc = "go to definition",
				mode = "n",
				buffer = ev.buf,
			},
			{
				"K",
				function()
					vim.lsp.buf.hover()
				end,
				desc = "hover documentation",
				mode = "n",
				buffer = ev.buf,
			},
			{
				"gI",
				function()
					vim.lsp.buf.implementation()
				end,
				desc = "go to implementation",
				mode = "n",
				buffer = ev.buf,
			},
			{
				"<C-m>",
				function()
					vim.lsp.buf.signature_help()
				end,
				desc = "signature help",
				mode = "n",
				buffer = ev.buf,
			},
			{
				"<space>D",
				function()
					vim.lsp.buf.type_definition()
				end,
				desc = "type definition",
				mode = "n",
				buffer = ev.buf,
			},
			{
				"gR",
				function()
					vim.lsp.buf.references()
				end,
				desc = "go to references",
				mode = "n",
				buffer = ev.buf,
			},

			-- LSP workspace management
			{
				"<leader>wa",
				function()
					vim.lsp.buf.add_workspace_folder()
				end,
				desc = "add workspace folder",
				mode = "n",
				buffer = ev.buf,
			},
			{
				"<leader>wr",
				function()
					vim.lsp.buf.remove_workspace_folder()
				end,
				desc = "remove workspace folder",
				mode = "n",
				buffer = ev.buf,
			},
			{
				"<leader>wl",
				function()
					print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
				end,
				desc = "list workspace folders",
				mode = "n",
				buffer = ev.buf,
			},

			-- LSP refactoring
			{
				",n",
				function()
					vim.lsp.buf.rename()
				end,
				desc = "rename (LSP)",
				mode = "n",
				buffer = ev.buf,
			},
			{
				",rn",
				function()
					vim.lsp.buf.rename()
				end,
				desc = "rename variable",
				mode = "n",
				buffer = ev.buf,
			},
			{
				",ca",
				function()
					vim.lsp.buf.code_action()
				end,
				desc = "code action",
				mode = { "n", "v" },
				buffer = ev.buf,
			},
			{
				",F",
				function()
					vim.lsp.buf.format({ async = true })
				end,
				desc = "format buffer (async)",
				mode = "n",
				buffer = ev.buf,
			},
			{
				",rs",
				":LspRestart<cr>",
				desc = "restart LSP",
				mode = "n",
				buffer = ev.buf,
			},

			-- Diagnostic navigation
			{
				"]d",
				function()
					vim.diagnostic.jump({ count = 1, float = true })
				end,
				desc = "next diagnostic message",
				mode = "n",
				buffer = ev.buf,
			},
			{
				"[d",
				function()
					vim.diagnostic.jump({ count = -1, float = true })
				end,
				desc = "prev diagnostic message",
				mode = "n",
				buffer = ev.buf,
			},
		})
	end,
})
