local M = {}

function M.snapLeft()
	local win = hs.window.focusedWindow()
	if not win then
		return
	end

	local screenFrame = win:screen():frame()
	win:setFrame({
		x = screenFrame.x,
		y = screenFrame.y,
		w = screenFrame.w / 2,
		h = screenFrame.h,
	}, 0)
end

function M.snapRight()
	local win = hs.window.focusedWindow()
	if not win then
		return
	end

	local screenFrame = win:screen():frame()
	win:setFrame({
		x = screenFrame.x + screenFrame.w / 2,
		y = screenFrame.y,
		w = screenFrame.w / 2,
		h = screenFrame.h,
	}, 0)
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
