return {
    "folke/noice.nvim",
    event = "UIEnter",
    dependencies = {
        "MunifTanjim/nui.nvim",
    },
    keys = {
        {
            "<leader>snl",
            function()
                require("noice").cmd("last")
            end,
            desc = "Noice Last Message",
        },
        {
            "<leader>snh",
            function()
                require("noice").cmd("history")
            end,
            desc = "Noice History",
        },
        {
            "<leader>sna",
            function()
                require("noice").cmd("all")
            end,
            desc = "Noice All",
        },
        {
            "<leader>snd",
            function()
                require("noice").cmd("dismiss")
            end,
            desc = "Dismiss All",
        },
        {
            "<leader>snt",
            function()
                require("noice").cmd("pick")
            end,
            desc = "Noice Picker",
        },
        {
            "<S-Enter>",
            function()
                require("noice").redirect(vim.fn.getcmdline())
            end,
            mode = "c",
            desc = "Redirect Cmdline",
        },
    },
    opts = {
        lsp = {
            progress = {
                enabled = true,
                view = "mini",
            },
            hover = {
                enabled = true,
            },
            signature = {
                enabled = false, -- Ditangani secara eksklusif oleh blink.cmp
            },
            override = {
                ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                ["vim.lsp.util.stylize_markdown"] = true,
                -- NOTE: override cmp.entry.get_documentation dihapus
                -- karena user sudah beralih ke blink.cmp (bukan nvim-cmp).
            },
        },

        notify = {
            enabled = false, -- Biarkan snacks.notifier yang menangani vim.notify
        },
        cmdline = {
            enabled = not vim.g.neovide,
        },
        messages = {
            enabled = not vim.g.neovide,
            view = "notify",
        },
        popupmenu = {
            enabled = false,
        },
        health = {
            checker = not vim.g.neovide,
        },

        presets = {
            bottom_search = false,
            command_palette = false,
            long_message_to_split = true,
            inc_rename = true,
            lsp_doc_border = true,
        },

        routes = {
            {
                filter = {
                    event = "msg_show",
                    any = {
                        { find = "%d+L, %d+B" },
                        { find = "; after #%d+" },
                        { find = "; before #%d+" },
                        { find = "written" },
                        { find = "yanked" },
                    },
                },
                view = "mini",
            },
        },

        views = {
            cmdline_popup = {
                position = {
                    row = 5,
                    col = "50%",
                },
                size = {
                    width = 60,
                    height = "auto",
                },
                border = {
                    style = "single",
                    padding = { 0, 1 },
                },
                win_options = {
                    winblend = 0,
                },
            },
            mini = {
                timeout = 5000, -- Menahan notifikasi mini selama 5 detik
                win_options = { winblend = 0 },
                position = { row = -2, col = "100%" },
                size = { width = "auto", height = "auto" },
            },
        },
    },
}
