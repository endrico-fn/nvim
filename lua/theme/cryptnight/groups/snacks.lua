local M = {}

function M.get(c, _)
    return {
        SnacksDashboardHeader = { fg = c.cyan, bold = true },
        SnacksDashboardIcon = { fg = c.medium_blue },
        SnacksDashboardDesc = { fg = c.fg },
        SnacksDashboardKey = { fg = c.orange, bold = true },
        SnacksDashboardFooter = { fg = c.suggestion, italic = true },
        SnacksDashboardSpecial = { fg = c.pink },
        SnacksDashboardDir = { fg = c.cyan },
        SnacksDashboardFile = { fg = c.fg },

        SnacksNotifierInfo = { fg = c.cyan },
        SnacksNotifierWarn = { fg = c.orange },
        SnacksNotifierError = { fg = c.red },
        SnacksNotifierDebug = { fg = c.gray },
        SnacksNotifierTrace = { fg = c.violet },
        SnacksNotifierBorderInfo = { fg = c.cyan },
        SnacksNotifierBorderWarn = { fg = c.orange },
        SnacksNotifierBorderError = { fg = c.red },

        SnacksIndent = { fg = c.suggestion, nocombine = true },
        SnacksIndentScope = { fg = c.blue, nocombine = true },

        SnacksPickerGitStatusUntracked = { fg = c.cyan },
        SnacksPickerGitStatusModified = { fg = c.yellow_orange or c.orange },
        SnacksPickerGitStatusAdded = { fg = c.green },
        SnacksPickerGitStatusDeleted = { fg = c.red },
        SnacksPickerGitStatusStaged = { fg = c.accent_blue or c.blue },

        -- Snacks Float Windows & Backdrop (Transparent BG, Border only)
        SnacksBackdrop = { bg = c.none },
        SnacksNormal = { fg = c.fg, bg = c.none },
        SnacksNormalNC = { fg = c.fg, bg = c.none },
        SnacksWinSeparator = { fg = c.bg_search or c.border, bg = c.none },

        -- Snacks Picker & Float Explorer (Transparent BG, Border only)
        SnacksPicker = { fg = c.fg, bg = c.none },
        SnacksPickerBorder = { link = "FloatBorder" },
        SnacksPickerBox = { fg = c.fg, bg = c.none },
        SnacksPickerInput = { fg = c.fg, bg = c.none },
        SnacksPickerInputBorder = { link = "FloatBorder" },
        SnacksPickerList = { fg = c.fg, bg = c.none },
        SnacksPickerListBorder = { link = "FloatBorder" },
        SnacksPickerPreview = { fg = c.fg, bg = c.none },
        SnacksPickerPreviewBorder = { link = "FloatBorder" },
        SnacksPickerTitle = { link = "FloatTitle" },
        SnacksPickerInputTitle = { link = "FloatTitle" },
        SnacksPickerListTitle = { link = "FloatTitle" },
        SnacksPickerPreviewTitle = { link = "FloatTitle" },

        -- Snacks Terminal Float (Minimalist, transparent BG, single border)
        SnacksTerminalNormal = { fg = c.fg, bg = c.none },
        SnacksTerminalNormalNC = { fg = c.fg, bg = c.none },
        SnacksTerminalBorder = { link = "FloatBorder" },
        SnacksTerminalTitle = { link = "FloatTitle" },
    }
end

return M
