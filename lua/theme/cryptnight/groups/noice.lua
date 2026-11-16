local M = {}

function M.get(c, _)
	return {
		NoicePopupmenu                   = { link = "Pmenu" },
		NoicePopupmenuBorder             = { link = "FloatBorder" },
		NoicePopupmenuSelected           = { link = "PmenuSel" },
		NoicePopupmenuMatch              = { fg = c.medium_blue, bold = true },
		NoiceVirtualText                 = { fg = c.suggestion },
		NoiceSplit                       = { link = "Normal" },
		NoiceSplitBorder                 = { link = "FloatBorder" },
		NoicePopup                       = { link = "NormalFloat" },
		NoicePopupBorder                 = { link = "FloatBorder" },
		NoiceCmdline                     = { link = "NormalFloat" },
		NoiceCmdlinePopup                = { link = "NormalFloat" },
		NoiceCmdlinePopupTitle           = { link = "FloatTitle" },
		NoiceCmdlinePopupTitleCmdline    = { link = "FloatTitle" },
		NoiceCmdlinePopupBorder          = { link = "FloatBorder" },
		NoiceCmdlinePopupBorderSearch    = { link = "FloatBorder" },
		NoiceCmdlinePopupTitleSearch     = { link = "FloatTitle" },
		NoiceCmdlineIconSearch           = { link = "FloatBorder" },
		NoiceMini                        = { link = "NormalFloat" },
		NoiceConfirm                     = { link = "NormalFloat" },
		NoiceConfirmBorder               = { link = "FloatBorder" },
		NoiceLspProgressClient           = { fg = c.cyan },
		NoiceLspProgressTitle            = { link = "FloatTitle" },
		NoiceLspProgressSpinner          = { fg = c.blue },
		NoiceFormatProgressDone          = { fg = c.light_green, bg = c.context_current },
		NoiceFormatProgressTodo          = { fg = c.medium_cyan, bg = c.dim_highlight },
	}
end

return M
