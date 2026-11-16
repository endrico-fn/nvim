local M = {}

function M.get(c, _)
	return {
		CratesNvimLoading    = { fg = c.suggestion },
		CratesNvimVersion    = { fg = c.blue },
		CratesNvimPreRelease = { fg = c.orange },
		CratesNvimYanked     = { fg = c.red },
		CratesNvimNoMatch    = { fg = c.red },
		CratesNvimUpgrade    = { fg = c.yellow, bold = true },
		CratesNvimError      = { fg = c.red },
	}
end

return M
