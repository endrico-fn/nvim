return {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
        max_lines = 3,
        min_window_height = 20,
        multiline_threshold = 1,
        trim_scope = "outer",
        mode = "cursor",
        separator = nil,
    },
    keys = {
        {
            "[c",
            function()
                require("treesitter-context").go_to_context(vim.v.count1)
            end,
            desc = "Jump to Context Header",
        },
        {
            "<leader>ux",
            function()
                require("treesitter-context").toggle()
            end,
            desc = "Toggle Treesitter Context",
        },
    },
}
