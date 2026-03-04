-- ~/.config/hammerspoon/tmux.lua
local M = {}

local function shQuote(s)
	return "'" .. tostring(s):gsub("'", [['"'"']]) .. "'"
end

local function sh(cmd)
	-- run via login shell so PATH/aliases/etc are present
	-- Set PATH to include Homebrew before executing
	local fullCmd = "export PATH=/opt/homebrew/bin:/opt/homebrew/sbin:$PATH; " .. cmd
	local out, ok, _, rc = hs.execute("/bin/zsh -c " .. shQuote(fullCmd))
	return out or "", ok, rc
end

local function splitLines(s)
	local t = {}
	for line in (s or ""):gmatch("[^\r\n]+") do
		line = line:gsub("^%s+", ""):gsub("%s+$", "")
		if line ~= "" then
			table.insert(t, line)
		end
	end
	return t
end

local function tmuxClients()
	-- Prefer client_tty because it always exists and is a valid switch-client -c target
	local out = sh([[tmux list-clients -F '#{client_tty}' 2>/dev/null || true]])
	return splitLines(out)
end

local function tmuxSessions()
	local out = sh([[tmux ls -F '#S' 2>/dev/null || true]])
	return splitLines(out)
end

local function tmuxHasSession(name)
	local _, ok, rc = sh("tmux has-session -t " .. shQuote(name) .. " 2>/dev/null")
	return ok and rc == 0
end

local function tmuxEnsureSessionDetached(name, root)
	-- Create detached if missing
	if not tmuxHasSession(name) then
		sh("tmux new-session -d -s " .. shQuote(name) .. " -c " .. shQuote(root))
	end
end

local function focusedWindowIsTmux()
	local win = hs.window.focusedWindow()
	local title = win and win:title() or ""
	return title:sub(1, 5) == "tmux:"
end

local function alacrittyIsOpen()
	local app = hs.application.get(Apps.alacritty)
	return app ~= nil and app:mainWindow() ~= nil
end

local function focusAlacritty()
	hs.application.launchOrFocus(Apps.alacritty)
end

local function typeInFocusedTerminal(cmd)
	hs.eventtap.keyStrokes(cmd)
	hs.eventtap.keyStroke({}, "return")
end

local function openNewAlacrittyTab()
	-- Adjust if your Alacritty uses a different shortcut (Cmd+N for new window, etc.)
	hs.eventtap.keyStroke({ "cmd" }, "t")
end

local function attachCmd(session_name, session_root, includeRoot)
	-- includeRoot=true => pass -c root (only matters on creation)
	if includeRoot then
		return string.format([[tmux new-session -A -s %s -c %s]], session_name, session_root)
	else
		return string.format([[tmux new-session -A -s %s]], session_name)
	end
end

local function switchAllClientsToSession(clients, session_name)
	for _, c in ipairs(clients) do
		sh("tmux switch-client -c " .. shQuote(c) .. " -t " .. shQuote(session_name) .. " 2>/dev/null || true")
	end
end

local function trim(s)
	return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function split_once(s, sep)
	local i = s:find(sep, 1, true)
	if not i then
		return s, nil
	end
	return s:sub(1, i - 1), s:sub(i + #sep)
end

function M.fzf_tmux_sessions(default_session_name, default_session_root)
	-- Try to include session_path, fall back if unsupported/empty
	local out = sh(
		[[tmux list-sessions -F "#{session_name}: #{session_path}" 2>/dev/null || tmux list-sessions -F "#{session_name}" 2>/dev/null || true]]
	)
	local choices = {}

	for line in out:gmatch("[^\r\n]+") do
		line = trim(line)
		if line ~= "" then
			local name, path = split_once(line, ": ")
			name = trim(name)
			path = trim(path or "")

			table.insert(choices, {
				text = name,
				subText = (path ~= "" and path or "(no session_path reported)"),
				session_name = name,
				session_root = path, -- may be ""
			})
		end
	end

	-- Always offer a default (handy if tmux server isn't running)
	table.insert(choices, 1, {
		text = default_session_name,
		subText = "default (create if missing)",
		session_name = default_session_name,
		session_root = default_session_root,
	})

	local chooser = hs.chooser.new(function(choice)
		if not choice then
			return
		end
		local name = choice.session_name or default_session_name
		local root = (choice.session_root and choice.session_root ~= "" and choice.session_root) or default_session_root
		M.target_session(name, root, default_session_name, default_session_root)
	end)

	chooser:choices(choices)
	chooser:searchSubText(true)
	chooser:placeholderText("Select tmux session (Esc to cancel)")
	chooser:show()
end

-- Hammerspoon: target a tmux session from anywhere, using Alacritty as the UI.
-- Assumptions:
--  - tmux title prefix is "tmux:" (e.g. tmux set-titles-string "tmux:#S | #W")
--  - Alacritty has a "new tab" shortcut on Cmd+T (adjust if yours differs)
--  - You are OK with keystroke injection into Alacritty when attaching
function M.target_session(session_name, session_root, default_session_name, default_session_root)
	local dotfiles_repo = os.getenv("HOME") .. "/dotfiles.git"
	session_name = session_name or "dotfiles"
	session_root = session_root or dotfiles_repo
	default_session_name = default_session_name or "dotfiles"
	default_session_root = default_session_root or dotfiles_repo

	-- Inspect tmux clients
	local clients = tmuxClients()
	if #clients == 0 then
		hs.alert.show("beeep! 0 clients", 1)
	elseif #clients > 1 then
		hs.alert.show("beeep! multiple clients, attaching them all to session", 1)
	else
		hs.alert.show("exactly 1 client " .. clients[1], 1)
	end

	-- Snapshot tmux sessions
	local sessions = tmuxSessions()
	local hasAnySessions = (#sessions > 0)

	-- If Alacritty not open: launch and attach via keystrokes
	if not alacrittyIsOpen() then
		focusAlacritty()

		hs.timer.doAfter(0.25, function()
			-- If no tmux sessions exist at all, attach/create the default session
			if not hasAnySessions then
				typeInFocusedTerminal(attachCmd(shQuote(default_session_name), shQuote(default_session_root), true))
				return
			end

			-- Otherwise attach/create target session
			if not tmuxHasSession(session_name) then
				typeInFocusedTerminal(attachCmd(shQuote(session_name), shQuote(session_root), true))
				return
			end

			-- Session exists, attach without -c
			typeInFocusedTerminal(attachCmd(shQuote(session_name), shQuote(session_root), false))
		end)

		return
	end

	-- Alacritty already open
	focusAlacritty()

	hs.timer.doAfter(0.15, function()
		-- Ensure a default session exists if there are no sessions
		if not hasAnySessions then
			tmuxEnsureSessionDetached(default_session_name, default_session_root)
		end

		-- Ensure target session exists if we will need to switch clients
		-- (switch-client requires the session to exist)
		tmuxEnsureSessionDetached(session_name, session_root)

		if focusedWindowIsTmux() then
			-- We are looking at tmux: move all clients to target session
			local currentClients = tmuxClients()
			switchAllClientsToSession(currentClients, session_name)
			return
		end

		-- Not currently viewing tmux. Open a new tab and attach/create target session from there.
		openNewAlacrittyTab()
		hs.timer.doAfter(0.15, function()
			typeInFocusedTerminal(attachCmd(shQuote(session_name), shQuote(session_root), true))
		end)
	end)
end

-- Export focusedWindowIsTmux for use in other modules
M.focusedWindowIsTmux = focusedWindowIsTmux

return M
