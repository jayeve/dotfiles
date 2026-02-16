local M = {}

function M.snapLeft()
	local win = hs.window.focusedWindow()
	if not win then
		return
	end

	local winFrame = win:frame()
	local screen = win:screen()
	local screenFrame = screen:frame()

	-- Check if window is perfectly filling the left half (with small tolerance for rounding)
	local tolerance = 10
	local isPerfectLeftHalf = math.abs(winFrame.x - screenFrame.x) < tolerance
		and math.abs(winFrame.y - screenFrame.y) < tolerance
		and math.abs(winFrame.w - screenFrame.w / 2) < tolerance
		and math.abs(winFrame.h - screenFrame.h) < tolerance

	if isPerfectLeftHalf then
		-- Already perfectly filling left half, move to right half of screen to the left
		local screenToLeft = screen:toWest()
		if screenToLeft then
			local leftScreenFrame = screenToLeft:frame()
			-- Always recalculate based on target screen dimensions
			win:setFrame({
				x = leftScreenFrame.x + leftScreenFrame.w / 2,
				y = leftScreenFrame.y,
				w = leftScreenFrame.w / 2,
				h = leftScreenFrame.h,
			}, 0)
		end
	-- If no screen to the left, do nothing (already at leftmost position)
	else
		-- Not perfectly filling left half, snap to left half of current screen
		win:setFrame({
			x = screenFrame.x,
			y = screenFrame.y,
			w = screenFrame.w / 2,
			h = screenFrame.h,
		}, 0)
	end
end

function M.snapRight()
	local win = hs.window.focusedWindow()
	if not win then
		return
	end

	local winFrame = win:frame()
	local screen = win:screen()
	local screenFrame = screen:frame()
	-- Check if window is perfectly filling the right half (with small tolerance for rounding)
	local tolerance = 10
	local isPerfectRightHalf = math.abs(winFrame.x - (screenFrame.x + screenFrame.w / 2)) < tolerance
		and math.abs(winFrame.y - screenFrame.y) < tolerance
		and math.abs(winFrame.w - screenFrame.w / 2) < tolerance
		and math.abs(winFrame.h - screenFrame.h) < tolerance

	if isPerfectRightHalf then
		-- Already perfectly filling right half, move to left half of screen to the right
		local screenToRight = screen:toEast()
		if screenToRight then
			local rightScreenFrame = screenToRight:frame()
			-- Always recalculate based on target screen dimensions
			win:setFrame({
				x = rightScreenFrame.x,
				y = rightScreenFrame.y,
				w = rightScreenFrame.w / 2,
				h = rightScreenFrame.h,
			}, 0)
		end
	-- If no screen to the right, do nothing (already at rightmost position)
	else
		-- Not perfectly filling right half, snap to right half of current screen
		win:setFrame({
			x = screenFrame.x + screenFrame.w / 2,
			y = screenFrame.y,
			w = screenFrame.w / 2,
			h = screenFrame.h,
		}, 0)
	end
end

function M.snapTop()
	local win = hs.window.focusedWindow()
	if not win then
		return
	end

	local f = win:screen():frame()
	win:setFrame({
		x = f.x,
		y = f.y,
		w = f.w,
		h = f.h / 2,
	}, 0)
end

function M.snapBottom()
	local win = hs.window.focusedWindow()
	if not win then
		return
	end

	local f = win:screen():frame()
	win:setFrame({
		x = f.x,
		y = f.y + (f.h / 2),
		w = f.w,
		h = f.h / 2,
	}, 0)
end

function M.snapTopLeft()
	local win = hs.window.focusedWindow()
	if not win then
		return
	end

	local f = win:screen():frame()
	win:setFrame({
		x = f.x,
		y = f.y,
		w = f.w / 2,
		h = f.h / 2,
	}, 0)
end

function M.snapTopRight()
	local win = hs.window.focusedWindow()
	if not win then
		return
	end

	local f = win:screen():frame()
	win:setFrame({
		x = f.x + (f.w / 2),
		y = f.y,
		w = f.w / 2,
		h = f.h / 2,
	}, 0)
end

function M.snapBottomLeft()
	local win = hs.window.focusedWindow()
	if not win then
		return
	end

	local f = win:screen():frame()
	win:setFrame({
		x = f.x,
		y = f.y + (f.h / 2),
		w = f.w / 2,
		h = f.h / 2,
	}, 0)
end

function M.snapBottomRight()
	local win = hs.window.focusedWindow()
	if not win then
		return
	end

	local f = win:screen():frame()
	win:setFrame({
		x = f.x + (f.w / 2),
		y = f.y + (f.h / 2),
		w = f.w / 2,
		h = f.h / 2,
	}, 0)
end

return M
