-- ~/.config/hammerspoon/translate.lua
local utils = require("utils")

local M = {}

-- Open Google Translate with provided text
function M.openGoogleTranslate(text, targetLang, sourceLang)
	targetLang = targetLang or "en"
	sourceLang = sourceLang or "auto"
	text = text or ""

	local url = "https://translate.google.com/?sl="
		.. sourceLang
		.. "&tl="
		.. targetLang
		.. "&text="
		.. utils.urlEncode(text)

	hs.urlevent.openURL(url)
end

-- Translate selected text (preferred) or clipboard (fallback)
function M.translateSelection(targetLang, sourceLang)
	local text = utils.getSelectedOrClipboardText()
	if not text or text == "" then
		hs.alert.show("No text selected / clipboard empty", 1)
		return
	end
	M.openGoogleTranslate(text, targetLang, sourceLang)
end

Translate = M
return M
