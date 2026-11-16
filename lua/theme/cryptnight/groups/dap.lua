local M = {}

function M.get(c, _)
	return {
		DapUIBreakpointsCurrentLine   = { fg = c.blue_green, bold = true },
		DapUIBreakpointsDisabledLine  = { fg = c.dim_highlight },
		DapUIBreakpointsInfo          = { fg = c.blue_green },
		DapUIBreakpointsLine          = { fg = c.pink },
		DapUIBreakpointsPath          = { fg = c.pink },
		DapUICurrentFrameName         = { fg = c.blue_green, bold = true },
		DapUIDecoration               = { fg = c.pink },
		DapUIFloatBorder              = { link = "FloatBorder" },
		DapUILineNumber               = { fg = c.pink },
		DapUIModifiedValue            = { fg = c.pink, bold = true },
		DapUIPlayPause                = { fg = c.blue_green },
		DapUIPlayPauseNC              = { fg = c.blue_green },
		DapUIRestart                  = { fg = c.blue_green },
		DapUIRestartNC                = { fg = c.blue_green },
		DapUIScope                    = { fg = c.pink },
		DapUISource                   = { fg = c.medium_blue },
		DapUIStepBack                 = { fg = c.pink },
		DapUIStepBackNC               = { fg = c.pink },
		DapUIStepInto                 = { fg = c.pink },
		DapUIStepIntoNC               = { fg = c.pink },
		DapUIStepOut                  = { fg = c.pink },
		DapUIStepOutNC                = { fg = c.pink },
		DapUIStepOver                 = { fg = c.pink },
		DapUIStepOverNC               = { fg = c.pink },
		DapUIStop                     = { fg = c.red },
		DapUIStopNC                   = { fg = c.red },
		DapUIStoppedThread            = { fg = c.pink },
		DapUIThread                   = { fg = c.blue_green },
		DapUIType                     = { fg = c.pink },
		DapUIUnavailable              = { fg = c.dim_highlight },
		DapUIUnavailableNC            = { fg = c.dim_highlight },
		DapUIWatchesEmpty             = { fg = c.dim_highlight },
		DapUIWatchesError             = { fg = c.red },
		DapUIWatchesValue             = { fg = c.blue_green },
		DapUIWinSelect                = { fg = c.pink, bold = true },
	}
end

return M
