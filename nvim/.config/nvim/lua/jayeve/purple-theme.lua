local M = {}

function M.setup()
	local colors = {
		bg = "#282828",
		bg_soft = "#1c1c23",
		fg = "#e6e6f0",
		muted = "#7a7a8c",

		purple = "#9966cc",
		gold = "#a17e1f",

		red = "#c65a5a",
		green = "#5ab977",
		blue = "#5f87ff",
		cyan = "#5fb3b3",
		orange = "#d48a3a",
	}

	vim.cmd("highlight clear")
	vim.cmd("set termguicolors")
	vim.g.colors_name = "amethyst_gold"

	local hl = vim.api.nvim_set_hl

	-- Editor
	hl(0, "Normal", { fg = colors.fg, bg = colors.bg })
	hl(0, "NormalFloat", { fg = colors.fg, bg = colors.bg_soft })
	hl(0, "CursorLine", { bg = colors.bg_soft })
	hl(0, "LineNr", { fg = colors.muted })
	hl(0, "CursorLineNr", { fg = colors.gold, bold = true })

	-- UI
	hl(0, "Visual", { bg = "#2a2236" })
	hl(0, "StatusLine", { fg = colors.bg, bg = colors.purple, bold = true })
	hl(0, "StatusLineNC", { fg = colors.muted, bg = colors.bg_soft })
	hl(0, "VertSplit", { fg = colors.bg_soft })
	hl(0, "Pmenu", { fg = colors.fg, bg = colors.bg_soft })
	hl(0, "PmenuSel", { fg = colors.bg, bg = colors.gold, bold = true })

	-- Syntax
	hl(0, "Comment", { fg = colors.muted, italic = true })
	hl(0, "String", { fg = colors.green })
	hl(0, "Number", { fg = colors.orange })
	hl(0, "Boolean", { fg = colors.orange })
	hl(0, "Keyword", { fg = colors.purple, bold = true })
	hl(0, "Function", { fg = colors.gold })
	hl(0, "Type", { fg = colors.purple })
	hl(0, "Identifier", { fg = colors.fg })
	hl(0, "Constant", { fg = colors.gold })

	-- Diagnostics
	hl(0, "DiagnosticError", { fg = colors.red })
	hl(0, "DiagnosticWarn", { fg = colors.gold })
	hl(0, "DiagnosticInfo", { fg = colors.blue })
	hl(0, "DiagnosticHint", { fg = colors.cyan })

	-- Git
	hl(0, "DiffAdd", { fg = colors.green })
	hl(0, "DiffChange", { fg = colors.purple })
	hl(0, "DiffDelete", { fg = colors.red })
end

return M
