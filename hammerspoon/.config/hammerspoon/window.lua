-- ~/.config/hammerspoon/window.lua
-- Enhanced multi-monitor window manager using hs.grid
-- Drop-in replacement for window_manager.lua with better multi-monitor support

local M = {}

-- Configuration
local GRID_SIZE = { w = 2, h = 2 } -- 2x2 grid for half/quarter positioning
local ANIMATION_DURATION = 0 -- No animation (instant snap)

-- Initialize grid configuration
hs.grid.setGrid(GRID_SIZE)
hs.grid.setMargins({ x = 0, y = 0 }) -- No gaps between windows
hs.window.animationDuration = 0 -- Disable all window animations for instant snapping

-- Grid cell definitions
-- Each cell is defined as {x, y, w, h} where:
--   x,y = grid position (0-indexed)
--   w,h = cell width/height in grid units
local CELLS = {
	left = { x = 0, y = 0, w = 1, h = 2 }, -- Left half (column 0, both rows)
	right = { x = 1, y = 0, w = 1, h = 2 }, -- Right half (column 1, both rows)
	top = { x = 0, y = 0, w = 2, h = 1 }, -- Top half (both columns, row 0)
	bottom = { x = 0, y = 1, w = 2, h = 1 }, -- Bottom half (both columns, row 1)
	topLeft = { x = 0, y = 0, w = 1, h = 1 }, -- Top-left quarter
	topRight = { x = 1, y = 0, w = 1, h = 1 }, -- Top-right quarter
	bottomLeft = { x = 0, y = 1, w = 1, h = 1 }, -- Bottom-left quarter
	bottomRight = { x = 1, y = 1, w = 1, h = 1 }, -- Bottom-right quarter
}

-- Helper function: Check if window is perfectly positioned in target cell
-- @param win: hs.window object
-- @param targetCell: cell table {x, y, w, h}
-- @return boolean: true if window matches target cell exactly
local function isWindowInCell(win, targetCell)
	if not win then
		return false
	end

	local currentCell = hs.grid.get(win)
	if not currentCell then
		return false
	end

	-- Compare grid positions (no tolerance needed - grid is precise)
	return currentCell.x == targetCell.x
		and currentCell.y == targetCell.y
		and currentCell.w == targetCell.w
		and currentCell.h == targetCell.h
end

-- Helper function: Move window to adjacent screen in specified direction
-- Flips the cell position (e.g., left->right, top->bottom) for natural multi-monitor movement
-- @param win: hs.window object
-- @param direction: string - "left", "right", "up", or "down"
-- @param currentCell: cell table {x, y, w, h} - the current position to flip from
local function moveToAdjacentScreen(win, direction, currentCell)
	if not win then
		return
	end

	local screen = win:screen()
	local targetScreen = nil
	local flippedCell = {}

	-- Get adjacent screen and flip cell based on direction
	if direction == "left" then
		targetScreen = screen:toWest()
		-- Flip horizontal: left half (x=0) becomes right half (x=1), and vice versa
		flippedCell = {
			x = (currentCell.x == 0) and 1 or 0, -- Flip x position
			y = currentCell.y, -- Keep y same
			w = currentCell.w, -- Keep width same
			h = currentCell.h, -- Keep height same
		}
	elseif direction == "right" then
		targetScreen = screen:toEast()
		-- Flip horizontal: right half (x=1) becomes left half (x=0), and vice versa
		flippedCell = {
			x = (currentCell.x == 0) and 1 or 0, -- Flip x position
			y = currentCell.y, -- Keep y same
			w = currentCell.w, -- Keep width same
			h = currentCell.h, -- Keep height same
		}
	elseif direction == "up" then
		targetScreen = screen:toNorth()
		-- Flip vertical: top half (y=0) becomes bottom half (y=1), and vice versa
		flippedCell = {
			x = currentCell.x, -- Keep x same
			y = (currentCell.y == 0) and 1 or 0, -- Flip y position
			w = currentCell.w, -- Keep width same
			h = currentCell.h, -- Keep height same
		}
	elseif direction == "down" then
		targetScreen = screen:toSouth()
		-- Flip vertical: bottom half (y=1) becomes top half (y=0), and vice versa
		flippedCell = {
			x = currentCell.x, -- Keep x same
			y = (currentCell.y == 0) and 1 or 0, -- Flip y position
			w = currentCell.w, -- Keep width same
			h = currentCell.h, -- Keep height same
		}
	end

	-- Only move if adjacent screen exists
	if targetScreen then
		hs.grid.set(win, flippedCell, targetScreen)
	end
end

-- Core snap function: Snap window to target cell or move to adjacent screen
-- @param targetCell: cell table {x, y, w, h}
-- @param moveDirection: string or nil - direction for multi-monitor toggle
--                       If nil, no multi-monitor movement (for quarters)
local function snapToPosition(targetCell, moveDirection)
	local win = hs.window.focusedWindow()
	if not win then
		return
	end

	-- Check if window is already in target position
	if isWindowInCell(win, targetCell) and moveDirection then
		-- Already in position, move to adjacent screen with flipped position
		moveToAdjacentScreen(win, moveDirection, targetCell)
	else
		-- Not in position, snap to target cell on current screen
		hs.grid.set(win, targetCell, win:screen())
	end
end

-- Public API: Half-screen snap functions with multi-monitor toggle

function M.snapLeft()
	snapToPosition(CELLS.left, "left")
end

function M.snapRight()
	snapToPosition(CELLS.right, "right")
end

function M.snapTop()
	snapToPosition(CELLS.top, "up")
end

function M.snapBottom()
	snapToPosition(CELLS.bottom, "down")
end

-- Public API: Quarter-screen snap functions (no multi-monitor toggle)

function M.snapTopLeft()
	snapToPosition(CELLS.topLeft, nil) -- nil = no multi-monitor movement
end

function M.snapTopRight()
	snapToPosition(CELLS.topRight, nil)
end

function M.snapBottomLeft()
	snapToPosition(CELLS.bottomLeft, nil)
end

function M.snapBottomRight()
	snapToPosition(CELLS.bottomRight, nil)
end

return M
