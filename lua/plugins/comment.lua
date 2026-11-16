return {
    {
        "JoosepAlviste/nvim-ts-context-commentstring",
        event = { "BufReadPost", "BufNewFile" },
        opts = { enable_autocmd = false },
        config = function(_, opts)
            require("ts_context_commentstring").setup(opts)
            vim.g.skip_ts_context_commentstring_module = true
            local get_option = vim.filetype.get_option
            vim.filetype.get_option = function(filetype, option)
                return option == "commentstring"
                        and require("ts_context_commentstring.internal").calculate_commentstring()
                    or get_option(filetype, option)
            end
        end,
    },
    {
        "folke/todo-comments.nvim",
        cmd = { "TodoTrouble" },
        event = { "BufReadPost", "BufNewFile" },
        opts = {},
        keys = {
            {
                "]t",
                function()
                    require("todo-comments").jump_next()
                end,
                desc = "Next Todo Comment",
            },
            {
                "[t",
                function()
                    require("todo-comments").jump_prev()
                end,
                desc = "Previous Todo Comment",
            },
            { "<leader>xt", "<cmd>TodoTrouble<cr>", desc = "Todo (Trouble)" },
        },
    },
}
