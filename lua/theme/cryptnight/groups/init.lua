local Config = require("theme.cryptnight.config")
local Util = require("theme.cryptnight.util")

local M = {}

M.plugins = {
    ["gitsigns.nvim"] = "gitsigns",
    ["bufferline.nvim"] = "bufferline",
    ["neotest"] = "neotest",
    ["trouble.nvim"] = "trouble",
    ["blink.cmp"] = "blink",
    ["nvim-dap"] = "dap",
    ["snacks.nvim"] = "snacks",
    ["harpoon"] = "harpoon",
    ["lazy.nvim"] = "lazy",
    ["which-key.nvim"] = "which-key",
    ["todo-comments.nvim"] = "todo-comments",
    ["mini.icons"] = "mini",
    ["mini.indentscope"] = "mini",
    ["mini.nvim"] = "mini",
    ["crates.nvim"] = "crates",
    ["flash.nvim"] = "flash",
    ["render-markdown.nvim"] = "render-markdown",
}

function M.get(name, colors, opts)
    local mod = require("theme.cryptnight.groups." .. name)
    return mod.get(colors, opts)
end

function M.setup(colors, opts)
    local groups = {
        base = true,
        kinds = true,
        semantic_tokens = true,
        treesitter = true,
    }

    if opts.plugins.all then
        for _, group in pairs(M.plugins) do
            groups[group] = true
        end
    elseif opts.plugins.auto and package.loaded.lazy then
        local plugins = require("lazy.core.config").plugins
        for plugin, group in pairs(M.plugins) do
            if plugins[plugin] then
                groups[group] = true
            end
        end
    end

    for plugin, group in pairs(M.plugins) do
        local use = opts.plugins[group]
        use = use == nil and opts.plugins[plugin] or use
        if use ~= nil then
            if type(use) == "table" then
                use = use.enabled
            end
            groups[group] = use or nil
        end
    end

    local names = vim.tbl_keys(groups)
    table.sort(names)

    local cache_key = opts.style
    local cache = opts.cache and Util.cache.read(cache_key)

    local inputs = {
        colors = colors,
        plugins = names,
        version = Config.version,
        opts = {
            transparent = opts.transparent,
            styles = opts.styles,
            dim_inactive = opts.dim_inactive,
        },
    }

    local ret = cache and vim.deep_equal(inputs, cache.inputs) and cache.groups

    if not ret then
        ret = {}
        for _, name in ipairs(names) do
            for k, v in pairs(M.get(name, colors, opts)) do
                ret[k] = v
            end
        end
        Util.resolve(ret)
        if opts.cache then
            Util.cache.write(cache_key, { groups = ret, inputs = inputs })
        end
    end

    opts.on_highlights(ret, colors)

    return ret, groups
end

return M
