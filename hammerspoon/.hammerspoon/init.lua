-- ~/.hammerspoon/init.lua
-- Thin bootloader: all real config lives in ~/.config/hammerspoon
require("hs.ipc")

local home = os.getenv("HOME")

-- Allow require("foo") to load ~/.config/hammerspoon/foo.lua
package.path = package.path .. ";" .. home .. "/.config/hammerspoon/?.lua"

require("apps")
require("hotkeys")
require("translate")

hs.alert.show("Hammerspoon loaded", 1)
