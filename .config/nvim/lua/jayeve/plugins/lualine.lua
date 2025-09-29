-- safely import lualine
local status, lualine = pcall(require, "lualine")
if not status then
  local info = debug.getinfo(1, "S").short_src
  print(info, "failed to load")
  return
end

-- base theme: nightfly
local nightfly = require("lualine.themes.nightfly")

-- dark-mode friendly pastel lavender colors
local dark_pastel = {
  bg_dark       = "#1e1e2e",  -- main background (matches terminal)
  fg_light      = "#e0d9f0",  -- text on dark bg
  lavender      = "#9b7fbf",  -- deeper pastel lavender
  light_lavender= "#bfa3e0",  -- highlight/secondary
  blue          = "#7fbce0",
  green         = "#80d080",
  yellow        = "#e0d07f",
  pink          = "#e0a3b0",
  gray          = "#2e2e3e",  -- inactive sections
}

-- normal mode
nightfly.normal.a.fg = dark_pastel.bg_dark
nightfly.normal.a.bg = dark_pastel.lavender
nightfly.normal.b.fg = dark_pastel.fg_light
nightfly.normal.b.bg = dark_pastel.bg_dark

-- insert mode
nightfly.insert.a.fg = dark_pastel.bg_dark
nightfly.insert.a.bg = dark_pastel.blue
nightfly.insert.b.fg = dark_pastel.fg_light
nightfly.insert.b.bg = dark_pastel.bg_dark

-- visual mode
nightfly.visual.a.fg = dark_pastel.bg_dark
nightfly.visual.a.bg = dark_pastel.green
nightfly.visual.b.fg = dark_pastel.fg_light
nightfly.visual.b.bg = dark_pastel.bg_dark

-- replace mode
nightfly.replace.a.fg = dark_pastel.bg_dark
nightfly.replace.a.bg = dark_pastel.pink
nightfly.replace.b.fg = dark_pastel.fg_light
nightfly.replace.b.bg = dark_pastel.bg_dark

-- command mode
nightfly.command = {
	a = {
		gui = "bold",
		bg = dark_pastel.yellow,
		fg = dark_pastel.bg_dark, -- black
	},
	b = {
		gui = "bold",
		bg = dark_pastel.bg_dark,
		fg = dark_pastel.fg_light, -- black
	},
}

-- inactive
nightfly.inactive.a.bg = dark_pastel.gray
nightfly.inactive.a.fg = dark_pastel.fg_light
nightfly.inactive.b.bg = dark_pastel.gray
nightfly.inactive.b.fg = dark_pastel.fg_light

-- setup lualine
lualine.setup({
  options = {
    theme = nightfly,
    component_separators = { left = "", right = "" },
    section_separators = { left = "", right = "" },
    icons_enabled = true,
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch", "diff" },
    lualine_c = { "filename" },
    lualine_x = { "encoding", "fileformat", "filetype" },
    lualine_y = { "progress" },
    lualine_z = { "location" },
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = { "filename" },
    lualine_x = { "location" },
    lualine_y = {},
    lualine_z = {},
  },
  tabline = {},
  extensions = {},
})
