-- ~/.config/hammerspoon/audio.lua
local M = {}

-- Telescope-style output audio picker for Hammerspoon
-- - Lists output devices only
-- - Excludes names containing "input" (case-insensitive)
-- - Marks current output
-- - Sets selected device as default output
function M.pickOutputDevice()
	local choices = {}

	local current = hs.audiodevice.defaultOutputDevice()
	local currentUID = current and current:uid() or nil

	for _, dev in ipairs(hs.audiodevice.allOutputDevices()) do
		local name = dev:name()
		local lname = string.lower(name)

		-- Exclude anything containing "input"
		if not string.find(lname, "input", 1, true) then
			local uid = dev:uid()

			table.insert(choices, {
				text = ((uid == currentUID) and "● " or "  ") .. name,
				subText = (uid == currentUID) and "Current output" or "",
				uid = uid,
			})
		end
	end

	table.sort(choices, function(a, b)
		return a.text:lower() < b.text:lower()
	end)

	local chooser = hs.chooser.new(function(choice)
		if not choice then
			return
		end

		local dev = hs.audiodevice.findDeviceByUID(choice.uid)
		if dev then
			dev:setDefaultOutputDevice()
			hs.alert.show("🔊 " .. dev:name(), 0.8)
		end
	end)

	chooser:choices(choices)
	chooser:searchSubText(true)
	chooser:placeholderText("Select output audio device…")
	chooser:rows(10)
	chooser:width(32)
	chooser:show()
end
-- Telescope-style input audio picker for Hammerspoon
-- - Lists input devices only
-- - Excludes names containing "output" (case-insensitive)
-- - Marks current input
-- - Sets selected device as default input
function M.pickInputDevice()
	local choices = {}

	local current = hs.audiodevice.defaultInputDevice()
	local currentUID = current and current:uid() or nil

	for _, dev in ipairs(hs.audiodevice.allInputDevices()) do
		local name = dev:name()
		local lname = string.lower(name)

		-- Exclude anything containing "output"
		if not string.find(lname, "output", 1, true) then
			local uid = dev:uid()

			table.insert(choices, {
				text = ((uid == currentUID) and "● " or "  ") .. name,
				subText = (uid == currentUID) and "Current input" or "",
				uid = uid,
			})
		end
	end

	table.sort(choices, function(a, b)
		return a.text:lower() < b.text:lower()
	end)

	local chooser = hs.chooser.new(function(choice)
		if not choice then
			return
		end

		local dev = hs.audiodevice.findDeviceByUID(choice.uid)
		if dev then
			dev:setDefaultInputDevice()
			hs.alert.show("🎙 " .. dev:name(), 0.8)
		end
	end)

	chooser:choices(choices)
	chooser:searchSubText(true)
	chooser:placeholderText("Select input audio device…")
	chooser:rows(10)
	chooser:width(32)
	chooser:show()
end

return M
