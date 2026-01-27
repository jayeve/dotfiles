-- ~/.hammerspoon/init.lua
-- Thin bootloader: all real config lives in ~/.config/hammerspoon
require("hs.ipc")

local home = os.getenv("HOME")
hs.alert.show("Hammerspoon config loaded")

-- Allow require("foo") to load ~/.config/hammerspoon/foo.lua
package.path = package.path .. ";" .. home .. "/.config/hammerspoon/?.lua"

-- Table structure: term_info[pid] = { status = "IDLE", tmux = "IN_TMUX" }
local term_info = {}

function CheckInTmux(pid, status, tmux)
	-- hs.alert.show(string.format("pid=%s\nstatus=%s\ntmux=%s", tostring(pid), tostring(status), tostring(tmux)), 1)

	if pid then
		term_info[tonumber(pid)] = {
			status = status,
			tmux = tmux,
		}
	end
end

hs.loadSpoon("Hammerflow")

-- Hammerflow searches these in order and loads the first valid TOML.
spoon.Hammerflow.loadFirstValidTomlFile({ "home.toml", "work.toml" })

if spoon.Hammerflow.auto_reload then
	hs.loadSpoon("ReloadConfiguration")
	spoon.ReloadConfiguration.watch_paths = {
		hs.configdir,
		home .. "/.config/hammerspoon",
	}
	spoon.ReloadConfiguration:start()
end

require("apps")
require("locations")
require("hotkeys")
