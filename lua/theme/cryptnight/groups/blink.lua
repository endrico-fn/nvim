local M = {}

function M.get(c, _)
	local hl = {
		BlinkCmpMenu                         = { fg = c.fg, bg = c.none },
		BlinkCmpMenuBorder                   = { link = "FloatBorder" },
		BlinkCmpMenuSelection                = { link = "PmenuSel" },
		BlinkCmpScrollBarThumb                = { link = "PmenuThumb" },
		BlinkCmpScrollBarGutter               = { link = "PmenuSbar" },
		BlinkCmpLabel                         = { fg = c.fg },
		BlinkCmpLabelMatch                    = { fg = c.medium_blue, bold = true },
		BlinkCmpLabelDeprecated               = { fg = c.suggestion, strikethrough = true },
		BlinkCmpLabelDetail                   = { fg = c.fg_dark },
		BlinkCmpLabelDescription              = { fg = c.fg_dark },
		BlinkCmpSource                        = { fg = c.fg_dark },
		BlinkCmpGhostText                     = { fg = c.suggestion },
		BlinkCmpDoc                           = { fg = c.fg, bg = c.none },
		BlinkCmpDocBorder                     = { link = "FloatBorder" },
		BlinkCmpDocSeparator                  = { fg = c.fg, bg = c.none },
		BlinkCmpDocCursorLine                 = { link = "Visual" },
		BlinkCmpSignatureHelp                 = { fg = c.fg, bg = c.none },
		BlinkCmpSignatureHelpBorder           = { link = "FloatBorder" },
		BlinkCmpSignatureHelpActiveParameter   = { fg = c.orange, bold = true, underline = true },
		BlinkCmpKindCopilot                   = { fg = c.blue_green },
	}

	require("theme.cryptnight.groups.kinds").kinds(hl, "BlinkCmpKind%s")

	return hl
end

return M
