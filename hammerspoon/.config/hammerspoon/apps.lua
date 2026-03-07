-- ~/.config/hammerspoon/apps.lua
-- Central place to define app names you launch often.

Apps = {
	alacritty = "Alacritty",
	anki = "Anki",
	code = "Windsurf",
	chatgpt = "ChatGPT",
	chrome = "Google Chrome",
	discord = "Discord",
	finder = "Finder",
	googlechat = "Google Chat",
	googlemaps = "Google Maps",
	googlemeet = "Google Meet",
	kitty = "Kitty",
	localsend = "Localsend",
	onepassword = "1Password",
	quicktime = "Quicktime Player",
	signal = "Signal",
	slack = "Slack",
	spark = "Spark",
	spotify = "Spotify",
	teams = "Microsoft Teams (PWA)",
	whatsapp = "Whatsapp",
	youtube = "Youtube",
}

-- these are typically chrome extensions bundle ids
-- hs -c 'for _, app in ipairs(hs.application.runningApplications()) do
--   print(app:name(), app:bundleID())
-- end'
PWA_Aps = {
	google_messages = "com.google.Chrome.app.hpfldicfbfomlpcikngkocigghgafkph",
	google_maps = "com.google.Chrome.app.mnhkaebcjjhencmpkapnbdaogjamfbcj",
}

BundleIDs = {
	spark = "com.readdle.smartemail-Mac",
}
