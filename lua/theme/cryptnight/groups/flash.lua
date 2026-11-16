local M = {}

function M.get(c, _)
	return {
		FlashBackdrop   = { fg = c.suggestion },
		FlashLabel      = { bg = c.violet, fg = "#ffffff", bold = true },
		FlashMatch      = { bg = c.dark_blue, fg = "#ffffff" },
		FlashCurrent    = { bg = c.yellow_orange, fg = "#000000", bold = true },
		FlashPrompt     = { bg = "NONE", fg = c.cyan, bold = true },
	}
end

return M
