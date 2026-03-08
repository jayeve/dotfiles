-- import nvim-treesitter plugin safely
local treesitter = require("nvim-treesitter.configs")

-- Detect OS for platform-specific configuration
local os_name = vim.loop.os_uname().sysname
local is_linux = os_name == "Linux"

-- configure treesitter
treesitter.setup({
	-- enable syntax highlighting
	highlight = {
		enable = true,
		disable = { "yaml" },
	},
	-- enable indentation
	indent = { enable = true },
	-- enable autotagging (w/ nvim-ts-autotag plugin)
	autotag = { enable = true },
	-- ensure these language parsers are installed
	ensure_installed = is_linux
			and {
				-- Reduced set for Raspberry Pi to avoid compilation issues
				"bash",
				"lua",
				"json",
				"yaml",
				"markdown",
				"markdown_inline",
				"vim",
				"python",
			}
		or {
			-- Full set for macOS
			"go",
			"bash",
			"regex",
			"rust",
			"toml",
			"lua",
			"json",
			"javascript",
			"typescript",
			"tsx",
			"yaml",
			"html",
			"css",
			"kotlin",
			"markdown",
			"markdown_inline",
			"svelte",
			"graphql",
			"bash",
			"vim",
			"dockerfile",
			"gitignore",
			"python",
		},
	-- auto install above language parsers (disable on Linux to avoid issues)
	auto_install = not is_linux,
})
