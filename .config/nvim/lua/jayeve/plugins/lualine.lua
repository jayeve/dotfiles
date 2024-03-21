-- import lualine plugin safely
local status, lualine = pcall(require, "lualine")
if not status then
	local info = debug.getinfo(1, "S").short_src
	print(info, "failed to load")
	return
end

-- get lualine nightfly theme
local lualine_nightfly = require("lualine.themes.nightfly")
-- local gruvbox = require("lualine.themes.gruvbox")

-- new colors for theme
local new_colors = {
	blue = "#65D1FF",
	green = "#33ff68",
	violet = "#FF61EF",
	yellow = "#FFDA7B",
	black = "#000000",
	purple = "af33ff",
	light_purple = "#9153d3",
	white = "#ffffff",
}

-- change nightlfy theme colors
lualine_nightfly.normal.a.fg = new_colors.black
lualine_nightfly.normal.a.bg = new_colors.light_purple
lualine_nightfly.insert.a.bg = new_colors.blue
lualine_nightfly.visual.a.bg = new_colors.green
lualine_nightfly.command = {
	a = {
		gui = "bold",
		bg = new_colors.yellow,
		fg = new_colors.black, -- black
	},
}

-- configure lualine with modified theme
lualine.setup({
	options = {
		theme = lualine_nightfly,
	},
	sections = {
		lualine_x = { "encoding", "fileformat", "filetype" },
	},
})
