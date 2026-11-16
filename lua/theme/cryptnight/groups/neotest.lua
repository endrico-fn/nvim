local M = {}

function M.get(c, _)
    return {
        NeotestAdapterName = { fg = c.fg, bold = true },
        NeotestDir = { fg = c.blue },
        NeotestExpandMarker = { fg = c.dim_highlight },
        NeotestFailed = { fg = c.red },
        NeotestFile = { fg = c.blue },
        NeotestFocused = { bold = true },
        NeotestIndent = { fg = c.dim_highlight },
        NeotestMarked = { fg = c.yellow_orange, bold = true },
        NeotestNamespace = { fg = c.pink },
        NeotestPassed = { fg = c.blue_green },
        NeotestRunning = { fg = c.dark_yellow },
        NeotestSkipped = { fg = c.blue },
        NeotestTarget = { fg = c.light_red },
        NeotestWatching = { fg = c.dark_yellow },
        NeotestWinSelect = { fg = c.blue, bold = true },
    }
end

return M
