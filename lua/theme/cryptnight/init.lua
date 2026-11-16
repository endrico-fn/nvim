local config = require("theme.cryptnight.config")

local M = {}
M.styles = {}

function M.load(opts)
    opts = config.extend(opts)
    vim.o.background = "dark"
    return require("theme.cryptnight.theme").setup(opts)
end

M.setup = config.setup

return M
