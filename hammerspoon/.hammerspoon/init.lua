-- ~/.hammerspoon/init.lua
-- Thin bootloader: all real config lives in ~/.config/hammerspoon
require("hs.ipc")

local home = os.getenv("HOME")
hs.alert.show("Hammerspoon config loaded")

-- Allow require("foo") to load ~/.config/hammerspoon/foo.lua
package.path = package.path .. ";" .. home .. "/.config/hammerspoon/?.lua"

-- quite Hacky but it works :)
-- Table structure: term_info[pid] = { status = "IDLE", tmux = "IN_TMUX" }
local term_info = {}

function CheckInTmux(pid, status, tmux)
	if pid then
		term_info[tonumber(pid)] = {
			status = status,
			tmux = tmux,
		}
	end
end

-- Auto-reload config on file changes
local reload = require("reload")
reload.start()

require("apps")
require("hotkeys")
