return {
    {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
            library = {
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
                { path = "snacks.nvim", words = { "Snacks" } },
                { path = "obsidian.nvim", words = { "obsidian" } },
                { path = "lazy.nvim" },
            },

            enabled = function(root_dir)
                if vim.g.lazydev_enabled ~= nil then
                    return vim.g.lazydev_enabled
                end
                return true
            end,

            integrations = {
                blink_cmp = true,
            },
        },
    },

    { "Bilal2453/luvit-meta", lazy = true },
}
