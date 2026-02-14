-- import cmp-nvim-lsp plugin safely
local cmp_nvim_lsp_status, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if not cmp_nvim_lsp_status then
	local info = debug.getinfo(1, "S").short_src
	print(info, "failed to load")
	return
end

local keymap = vim.keymap -- for conciseness

-- used to enable autocompletion (assign to every lsp server config)
local capabilities = cmp_nvim_lsp.default_capabilities()

-- Change the Diagnostic symbols in the sign column (gutter)
-- (not in youtube nvim video)
local signs = { Error = " ", Warn = " ", Hint = "? ", Info = " " }
for type, icon in pairs(signs) do
	local hl = "DiagnosticSign" .. type
	vim.diagnostic.config({
		signs = {
			numhl = { text = icon, texthl = hl },
			linehl = { text = icon, texthl = hl },
		},
	})
end

-- configure html server
vim.lsp.config.html = {
	cmd = { "vscode-html-language-server", "--stdio" },
	filetypes = { "html" },
	root_markers = { ".git" },
	capabilities = capabilities,
}

-- make bash-lsp work with zsh (nvim builtin-lsp)
vim.lsp.config.bashls = {
	cmd = { "bash-language-server", "start" },
	filetypes = { "sh", "zsh", "bash" },
	root_markers = { ".git" },
	capabilities = capabilities,
}

-- lspconfig.yamlls.setup({
-- 	settings = {
-- 		yaml = {
-- 			format = { enable = true },
-- 			keyOrdering = false,
-- 		},
-- 	},
-- })

vim.filetype.add({
	extension = {
		zsh = "sh",
		sh = "sh", -- force sh-files with zsh-shebang to still get sh as filetype
	},
	filename = {
		[".zshrc"] = "sh",
		[".zshenv"] = "sh",
	},
})

-- confgure golang
vim.lsp.config.gopls = {
	capabilities = capabilities,
	cmd = { "gopls" },
	filetypes = { "go", "gomod", "goworkd", "gotmpl" },
	root_markers = { "go.work", "go.mod", ".git" },
	settings = {
		gopls = {
			completeUnimported = true,
			usePlaceholders = true,
		},
	},
}

-- -- confgure golang when programming in ere go code
-- vim.lsp.config.gopls = {
-- 	capabilities = capabilities,
-- 	cmd = { "gopls" },
-- 	filetypes = { "go", "gomod", "goworkd", "gotmpl" },
-- 	root_markers = { "go.work", "go.mod", ".git" },
-- 	settings = {
-- 		gopls = {
-- 			completeUnimported = true,
-- 			usePlaceholders = true,
-- 			-- https://github.com/bazel-contrib/rules_go/wiki/Editor-setup
-- 			env = {
-- 				GOPACKAGESDRIVER = "./tools/gopackagesdriver.sh",
-- 			},
-- 			directoryFilters = {
-- 				"-bazel-bin",
-- 				"-bazel-out",
-- 				"-bazel-testlogs",
-- 				"-bazel-mypkg",
-- 			},
-- 		},
-- 	},
-- }

-- configure css server
vim.lsp.config.cssls = {
	cmd = { "vscode-css-language-server", "--stdio" },
	filetypes = { "css", "scss", "less" },
	root_markers = { ".git" },
	capabilities = capabilities,
}

-- configure tailwindcss server
vim.lsp.config.tailwindcss = {
	cmd = { "tailwindcss-language-server", "--stdio" },
	filetypes = { "html", "css", "scss", "javascript", "javascriptreact", "typescript", "typescriptreact" },
	root_markers = { "tailwind.config.js", "tailwind.config.ts", ".git" },
	capabilities = capabilities,
}

-- configure lua server (with special settings)
vim.lsp.config.lua_ls = {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_markers = { ".git" },
	capabilities = capabilities,
	settings = { -- custom settings for lua
		Lua = {
			-- make the language server recognize "vim" global
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				-- make language server aware of runtime files
				library = {
					[vim.fn.expand("$VIMRUNTIME/lua")] = true,
					[vim.fn.stdpath("config") .. "/lua"] = true,
				},
			},
		},
	},
}

vim.lsp.config.clangd = {
	cmd = { "clangd" },
	filetypes = { "c", "cpp", "objc", "objcpp" },
	root_markers = { ".git", "compile_commands.json" },
	capabilities = capabilities,
}

vim.lsp.config.intelephense = {
	cmd = { "intelephense", "--stdio" },
	filetypes = { "php" },
	root_markers = { "composer.json", ".git" },
	capabilities = capabilities,
}

-- vim.lsp.config.ruff_lsp = {
-- 	cmd = { "ruff-lsp" },
-- 	filetypes = { "python" },
-- 	root_markers = { ".git" },
-- 	init_options = {
-- 		settings = {
-- 			-- Any extra CLI arguments for `ruff` go here.
-- 			args = {},
-- 		},
-- 	},
-- }

vim.lsp.config.rust_analyzer = {
	cmd = { "rust-analyzer" },
	filetypes = { "rust" },
	root_markers = { "Cargo.toml", ".git" },
	capabilities = capabilities,
	settings = {
		["rust-analyzer"] = {
			cargo = {
				features = { "boringssl", "s2n" }, -- list your features here
				allFeatures = true, -- or set to true
			},
		},
	},
}

vim.lsp.config.pyright = {
	cmd = { "pyright-langserver", "--stdio" },
	filetypes = { "python" },
	root_markers = { "pyrightconfig.json", "pyproject.toml", "setup.py", ".git" },
	capabilities = capabilities,
	settings = {
		pyright = { autoImportCompletion = true },
		python = {
			analysis = {
				autoSearchPaths = true,
				diagnosticMode = "openFilesOnly",
				useLibraryCodeForTypes = true,
				typeCheckingMode = "off",
			},
		},
	},
}
