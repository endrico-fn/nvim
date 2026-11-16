local M = {}

function M.get(c, _)
    return {
        GitSignsAdd = { fg = c.git.add },
        GitSignsChange = { fg = c.yellow },
        GitSignsDelete = { fg = c.red },
        GitSignsAddLn = { fg = c.bg, bg = c.git.add },
        GitSignsChangeLn = { fg = c.bg, bg = c.yellow },
        GitSignsDeleteLn = { fg = c.bg, bg = c.red },
    }
end

return M
