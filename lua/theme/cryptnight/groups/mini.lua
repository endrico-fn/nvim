local M = {}

function M.get(c, _)
    return {
        MiniIconsAzure = { fg = c.blue },
        MiniIconsBlue = { fg = c.blue },
        MiniIconsCyan = { fg = c.cyan },
        MiniIconsGreen = { fg = c.light_green },
        MiniIconsGrey = { fg = c.gray },
        MiniIconsOrange = { fg = c.orange },
        MiniIconsPurple = { fg = c.violet },
        MiniIconsRed = { fg = c.red },
        MiniIconsYellow = { fg = c.yellow },
    }
end

return M
