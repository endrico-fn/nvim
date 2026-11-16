local M = {}

function M.get(c, _)
    return {
        LazyBackdrop = { bg = c.bg },
        LazyNormal = { link = "NormalFloat" },
    }
end

return M
