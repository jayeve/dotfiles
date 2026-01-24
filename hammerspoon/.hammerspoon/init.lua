-- ~/.hammerspoon/init.lua
-- Thin bootloader: all real config lives in ~/.config/hammerspoon
require("hs.ipc")

local home = os.getenv("HOME")

-- Allow require("foo") to load ~/.config/hammerspoon/foo.lua
package.path = package.path .. ";" .. home .. "/.config/hammerspoon/?.lua"

hs.loadSpoon("Hammerflow")

-- Hammerflow searches these in order and loads the first valid TOML.
spoon.Hammerflow.loadFirstValidTomlFile({
	"home.toml",
	"work.toml",
	"Spoons/Hammerflow.spoon/sample.toml",
})

-- Optional: if your TOML enables auto_reload, respect it.
if spoon.Hammerflow.auto_reload then
	hs.loadSpoon("ReloadConfiguration")
	spoon.ReloadConfiguration:start()
end

require("apps")
require("hotkeys")
require("translate")

hs.alert.show("Hammerspoon loaded", 1)
