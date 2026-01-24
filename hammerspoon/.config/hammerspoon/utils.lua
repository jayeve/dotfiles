-- ~/.config/hammerspoon/utils.lua
local M = {}

-- URL-encode a string for query params
function M.urlEncode(str)
	if not str then
		return ""
	end
	str = tostring(str)
	str = str:gsub("\n", "\r\n")
	str = str:gsub("([^%w%-%_%.%~ ])", function(c)
		return string.format("%%%02X", string.byte(c))
	end)
	str = str:gsub(" ", "%%20")
	return str
end

-- Try to copy currently selected text, then return clipboard
function M.getSelectedOrClipboardText()
	local original = hs.pasteboard.getContents()

	-- Attempt Cmd+C to copy selection
	hs.eventtap.keyStroke({ "cmd" }, "c", 0)
	hs.timer.usleep(150000) -- 150ms

	local copied = hs.pasteboard.getContents()
	if copied and copied ~= "" then
		return copied
	end

	-- Fallback: previous clipboard
	return original or ""
end

return M
