local M = {}

-- Re-export canonical palette dari colors/storm.lua untuk hindari duplikasi.
-- Single source of truth: colors/storm.lua
M.storm = require("theme.cryptnight.colors.storm")

function M.get(style)
    return vim.deepcopy(M[style or "storm"])
end

return M
