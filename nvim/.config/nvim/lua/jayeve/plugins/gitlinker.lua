-- import gitlinker plugin safely
local setup, gitlinker = pcall(require, "gitlinker")
if not setup then
	local info = debug.getinfo(1, "S").short_src
	print(info, "failed to load")
	return
end

-- configure/enable gitlinker
-- Using linrongbin16/gitlinker.nvim (newer, actively maintained, better worktree support)
gitlinker.setup({
	message = true, -- print message when URL is copied
	router = {
		browse = {
			-- cloudflare new
			["^gitlab%.cfdata%.org"] = "https://gitlab.cfdata.org/"
				.. "{_A.ORG}/"
				.. "{_A.REPO}/blob/"
				.. "{_A.REV}/"
				.. "{_A.FILE}"
				.. "#L{_A.LSTART}"
				.. "{(_A.LEND > _A.LSTART and ('-L' .. _A.LEND) or '')}",
			-- cloudflare old
			["^bitbucket%.cfdata%.org"] = function(lk)
				local project = lk.org
				local repo = lk.repo
				local url = "https://bitbucket.cfdata.org/projects/"
					.. project
					.. "/repos/"
					.. repo
					.. "/browse/"
					.. lk.file
					.. "?at="
					.. lk.rev
					.. "#"
					.. lk.lstart
				if lk.lend and lk.lend > lk.lstart then
					url = url .. "-" .. lk.lend
				end
				return url
			end,
		},
	},
})
