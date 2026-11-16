local M = {}

M.version = "1.1.0"

M.defaults = {
    style = "storm",
    transparent = false,
    terminal_colors = true,
    underline_links = false,
    group_overrides = {},
    styles = {
        comments = { italic = true },
        keywords = { italic = true },
        functions = {},
        variables = {},
        inlayhints = {},
        sidebars = "dark",
    },
    dim_inactive = false,
    on_colors = function(colors) end,
    on_highlights = function(highlights, colors) end,
    cache = true,
    plugins = {
        all = package.loaded.lazy == nil,
        auto = true,
    },
}

M.options = nil

function M.setup(options)
    M.options = vim.tbl_deep_extend("force", {}, M.defaults, options or {})
end

function M.extend(opts)
    return opts and vim.tbl_deep_extend("force", {}, M.options, opts) or M.options
end

setmetatable(M, {
    __index = function(_, k)
        if k == "options" then
            return M.defaults
        end
    end,
})

M.setup()

return M
