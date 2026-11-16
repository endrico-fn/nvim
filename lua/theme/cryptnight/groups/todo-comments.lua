local M = {}

function M.get(c, _)
    return {
        TodoFgFIX = { fg = c.red },
        TodoBgFIX = { fg = c.bg, bg = c.red, bold = true },
        TodoSignFIX = { fg = c.red },
        TodoFgTODO = { fg = c.accent_blue },
        TodoBgTODO = { fg = c.bg, bg = c.accent_blue, bold = true },
        TodoSignTODO = { fg = c.accent_blue },
        TodoFgHACK = { fg = c.orange },
        TodoBgHACK = { fg = c.bg, bg = c.orange, bold = true },
        TodoSignHACK = { fg = c.orange },
        TodoFgWARN = { fg = c.yellow },
        TodoBgWARN = { fg = c.bg, bg = c.yellow, bold = true },
        TodoSignWARN = { fg = c.yellow },
        TodoFgPERF = { fg = c.violet },
        TodoBgPERF = { fg = c.bg, bg = c.violet, bold = true },
        TodoSignPERF = { fg = c.violet },
        TodoFgNOTE = { fg = c.light_green },
        TodoBgNOTE = { fg = c.bg, bg = c.light_green, bold = true },
        TodoSignNOTE = { fg = c.light_green },
    }
end

return M
