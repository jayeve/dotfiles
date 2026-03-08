-- ╔════════════════════════════════════════════════════════════════╗
-- ║  Logging Utility Module                                        ║
-- ╚════════════════════════════════════════════════════════════════╝
--
-- Usage:
--   local log = require("jayeve.utils.log")
--   log.error("File not found")
--   log.warn("Deprecated function")
--   log.info("Operation completed")
--   log.debug("Variable value:", var)  -- Goes to :messages

local M = {}

-- Get calling module name for automatic titles
local function get_caller_info()
	local info = debug.getinfo(3, "S")
	if info and info.source then
		local source = info.source:match("^@?(.+)$")
		-- Extract meaningful module name from path
		local module = source:match("lua/jayeve/(.+)%.lua$")
		if module then
			return module:gsub("/", ".")
		end
	end
	return nil
end

-- ══════════════════════════════════════════════════════════════════
-- Error: Red notification popup (bottom-left)
-- ══════════════════════════════════════════════════════════════════
function M.error(msg, opts)
	opts = opts or {}

	-- Auto-set title if not provided
	if not opts.title then
		opts.title = get_caller_info() or "Error"
	end

	vim.notify(msg, vim.log.levels.ERROR, opts)
end

-- ══════════════════════════════════════════════════════════════════
-- Warning: Yellow notification popup (bottom-left)
-- ══════════════════════════════════════════════════════════════════
function M.warn(msg, opts)
	opts = opts or {}

	if not opts.title then
		opts.title = get_caller_info() or "Warning"
	end

	vim.notify(msg, vim.log.levels.WARN, opts)
end

-- ══════════════════════════════════════════════════════════════════
-- Info: Blue notification popup (bottom-left)
-- ══════════════════════════════════════════════════════════════════
function M.info(msg, opts)
	opts = opts or {}

	if not opts.title then
		opts.title = get_caller_info() or "Info"
	end

	vim.notify(msg, vim.log.levels.INFO, opts)
end

-- ══════════════════════════════════════════════════════════════════
-- Debug: Plain print to :messages (not a popup)
-- ══════════════════════════════════════════════════════════════════
function M.debug(...)
	local args = { ... }
	local msg = table.concat(
		vim.tbl_map(function(v)
			return type(v) == "string" and v or vim.inspect(v)
		end, args),
		" "
	)

	print("[DEBUG]", msg)
end

-- ══════════════════════════════════════════════════════════════════
-- Trace: Detailed debug to :messages
-- ══════════════════════════════════════════════════════════════════
function M.trace(...)
	local args = { ... }
	local msg = table.concat(
		vim.tbl_map(function(v)
			return type(v) == "string" and v or vim.inspect(v)
		end, args),
		" "
	)

	print("[TRACE]", msg)
end

return M
