local M = {}

function M.get(c, _)
    return {
        WhichKey = { fg = c.blue },
        WhichKeyDesc = { fg = c.fg_dark },
        WhichKeyIconAzure = { fg = c.blue_green },
        WhichKeyIconBlue = { fg = c.blue },
        WhichKeyIconGreen = { fg = c.light_green },
        WhichKeyIconGrey = { fg = c.gray },
        WhichKeyIconOrange = { fg = c.yellow_orange },
        WhichKeyIconPurple = { fg = c.pink },
        WhichKeyIconRed = { fg = c.red },
        WhichKeyIconYellow = { fg = c.yellow },
        WhichKeySeparator = { fg = c.fg, bg = c.none },
        WhichKeyValue = { fg = c.fg, bg = c.none },
        WhichKeyNormal = { fg = c.fg, bg = c.none },
        WhichKeyBorder = { link = "FloatBorder" },
        WhichKeyTitle = { fg = c.accent_blue, bg = c.none, bold = true },
    }
end

return M
