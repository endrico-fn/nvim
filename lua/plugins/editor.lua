local web_commentstring_fts = {
    "astro",
    "svelte",
    "html",
    "vue",
    "javascriptreact",
    "typescriptreact",
}

return {
    {
        "folke/flash.nvim",
        keys = {
            {
                "gs",
                mode = { "n", "x", "o" },
                function()
                    require("flash").jump()
                end,
                desc = "Flash Jump",
            },
            {
                "gS",
                mode = { "n", "x", "o" },
                function()
                    require("flash").treesitter()
                end,
                desc = "Flash Treesitter",
            },
            {
                "r",
                mode = "o",
                function()
                    require("flash").remote()
                end,
                desc = "Flash Remote",
            },
            {
                "R",
                mode = { "o", "x" },
                function()
                    require("flash").treesitter_search()
                end,
                desc = "Flash Treesitter Search",
            },
            {
                "<C-f>",
                mode = "c",
                function()
                    require("flash").toggle()
                end,
                desc = "Toggle Flash Search",
            },
        },
        opts = {
            jump = {
                nohlsearch = true,
            },
            label = {
                uppercase = false,
                exclude = "hjkliardc",
                rainbow = {
                    enabled = true,
                },
            },
            modes = {
                char = {
                    multi_line = false,
                    autohide = true,
                    highlight = { backdrop = false },
                },
            },
            remote_op = {
                restore = true,
            },
        },
    },

    {
        "echasnovski/mini.ai",
        event = "VeryLazy",
        opts = function()
            local ai = require("mini.ai")
            return {
                n_lines = 500,
                custom_textobjects = {
                    o = ai.gen_spec.treesitter({
                        a = { "@block.outer", "@conditional.outer", "@loop.outer" },
                        i = { "@block.inner", "@conditional.inner", "@loop.inner" },
                    }),
                    f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
                    c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
                    t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^<>]->$" },
                    d = { "%f[%d]%d+" },
                    e = {
                        {
                            "%u[%l%d]+%f[^%l%d]",
                            "%f[%S][%l%d]+%f[^%l%d]",
                            "%f[%P][%l%d]+%f[^%l%d]",
                            "^[%l%d]+%f[^%l%d]",
                        },
                        "^().*()$",
                    },
                    u = ai.gen_spec.function_call(),
                    U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }),
                },
            }
        end,
    },

    {
        "kylechui/nvim-surround",
        keys = {
            "ys",
            "ds",
            "cs",
            { "S", mode = "x", desc = "Surround Selection" },
        },
        config = true,
    },

    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        opts = {
            check_ts = true,
            fast_wrap = {
                highlight = "PmenuSel",
                highlight_grey = "LineNr",
            },
        },
    },

    {
        "MagicDuck/grug-far.nvim",
        cmd = "GrugFar",
        keys = {
            {
                "<leader>rr",
                function()
                    local file = vim.api.nvim_buf_get_name(0)
                    local prefills = file ~= "" and { paths = vim.fn.fnamemodify(file, ":.") } or {}
                    require("grug-far").open({ prefills = prefills })
                end,
                desc = "Replace (Current File)",
            },
            {
                "<leader>rR",
                function()
                    require("grug-far").open()
                end,
                desc = "Replace (Project)",
            },
            {
                "<leader>rw",
                function()
                    require("grug-far").open({
                        prefills = { search = vim.fn.expand("<cword>") },
                    })
                end,
                desc = "Replace (Word)",
            },
            {
                "<leader>rW",
                function()
                    local file = vim.api.nvim_buf_get_name(0)
                    local prefills = file ~= "" and { paths = vim.fn.fnamemodify(file, ":.") } or {}
                    require("grug-far").with_visual_selection({ prefills = prefills })
                end,
                mode = "v",
                desc = "Replace (Selection)",
            },
        },
        opts = {
            transient = true,
            windowCreationCommand = "botright vsplit",
            keymaps = {
                close = { n = "q" },
            },
            engines = {
                ripgrep = {
                    extraArgs = "--hidden --glob=!.git/",
                },
            },
        },
    },

    {
        "cshuaimin/ssr.nvim",
        keys = {
            {
                "<leader>rS",
                function()
                    require("ssr").open()
                end,
                mode = { "n", "x" },
                desc = "Replace (Structured)",
            },
        },
        config = true,
    },

    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        dependencies = { "nvim-lua/plenary.nvim" },
        keys = {
            {
                "<leader>ma",
                function()
                    local harpoon = require("harpoon")
                    harpoon:list():add()
                    local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:.")
                    vim.notify("Ditambahkan: " .. file, vim.log.levels.INFO, { title = "Harpoon" })
                end,
                desc = "Harpoon: Add file",
            },
            {
                "<leader>mr",
                function()
                    local harpoon = require("harpoon")
                    harpoon:list():remove()
                    local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:.")
                    vim.notify("Dihapus: " .. file, vim.log.levels.WARN, { title = "Harpoon" })
                end,
                desc = "Harpoon: Remove file",
            },
            {
                "<leader>mm",
                function()
                    require("harpoon").ui:toggle_quick_menu(require("harpoon"):list())
                end,
                desc = "Harpoon: Quick Menu",
            },
            {
                "<leader>mf",
                function()
                    local harpoon = require("harpoon")
                    local items = {}
                    for i, item in ipairs(harpoon:list().items) do
                        if item and item.value and item.value ~= "" then
                            table.insert(items, {
                                idx = i,
                                file = item.value,
                                text = string.format("%d: %s", i, item.value),
                            })
                        end
                    end
                    if #items == 0 then
                        vim.notify(
                            "Harpoon list kosong",
                            vim.log.levels.INFO,
                            { title = "Harpoon" }
                        )
                        return
                    end
                    if _G.Snacks and Snacks.picker then
                        Snacks.picker({
                            title = "Harpoon Files",
                            items = items,
                            format = "file",
                        })
                    else
                        harpoon.ui:toggle_quick_menu(harpoon:list())
                    end
                end,
                desc = "Harpoon: Picker",
            },
            {
                "<leader>mc",
                function()
                    require("harpoon"):list():clear()
                    vim.notify("List dikosongkan", vim.log.levels.INFO, { title = "Harpoon" })
                end,
                desc = "Harpoon: Clear list",
            },
            {
                "[H",
                function()
                    require("harpoon"):list():prev()
                end,
                desc = "Harpoon: Prev file",
            },
            {
                "]H",
                function()
                    require("harpoon"):list():next()
                end,
                desc = "Harpoon: Next file",
            },
            {
                "<leader>1",
                function()
                    require("harpoon"):list():select(1)
                end,
                desc = "Harpoon: File 1",
            },
            {
                "<leader>2",
                function()
                    require("harpoon"):list():select(2)
                end,
                desc = "Harpoon: File 2",
            },
            {
                "<leader>3",
                function()
                    require("harpoon"):list():select(3)
                end,
                desc = "Harpoon: File 3",
            },
            {
                "<leader>4",
                function()
                    require("harpoon"):list():select(4)
                end,
                desc = "Harpoon: File 4",
            },
            {
                "<leader>5",
                function()
                    require("harpoon"):list():select(5)
                end,
                desc = "Harpoon: File 5",
            },
            {
                "<leader>6",
                function()
                    require("harpoon"):list():select(6)
                end,
                desc = "Harpoon: File 6",
            },
            {
                "<leader>7",
                function()
                    require("harpoon"):list():select(7)
                end,
                desc = "Harpoon: File 7",
            },
            {
                "<leader>8",
                function()
                    require("harpoon"):list():select(8)
                end,
                desc = "Harpoon: File 8",
            },
            {
                "<leader>9",
                function()
                    require("harpoon"):list():select(9)
                end,
                desc = "Harpoon: File 9",
            },
        },
        opts = {
            settings = {
                save_on_toggle = true,
                sync_on_ui_close = true,
                key = function()
                    local fname = vim.api.nvim_buf_get_name(0)
                    return require("util.root").root_dir(fname) or vim.uv.cwd()
                end,
            },
        },
    },

    {
        "jake-stewart/multicursor.nvim",
        -- Note: <Esc> stays in config/keymaps.lua so pressing <Esc> never loads this plugin eagerly.
        keys = {
            {
                "<A-n>",
                function()
                    require("multicursor-nvim").lineAddCursor(1)
                end,
                mode = { "n", "v" },
                desc = "MC: Add Down",
            },
            {
                "<A-p>",
                function()
                    require("multicursor-nvim").lineAddCursor(-1)
                end,
                mode = { "n", "v" },
                desc = "MC: Add Up",
            },
            {
                "<leader>n",
                function()
                    require("multicursor-nvim").matchAddCursor(1)
                end,
                mode = { "n", "v" },
                desc = "MC: Add Match Forward",
            },
            {
                "<leader>N",
                function()
                    require("multicursor-nvim").matchAddCursor(-1)
                end,
                mode = { "n", "v" },
                desc = "MC: Add Match Backward",
            },
            {
                "<A-x>",
                function()
                    require("multicursor-nvim").matchSkipCursor(1)
                end,
                mode = { "n", "v" },
                desc = "MC: Skip Match",
            },
            {
                "<leader>A",
                function()
                    require("multicursor-nvim").matchAllAddCursors()
                end,
                mode = { "n", "v" },
                desc = "MC: Select All Matches",
            },
            {
                "<A-s>",
                function()
                    require("multicursor-nvim").splitCursors()
                end,
                mode = "v",
                desc = "MC: Split Lines",
            },
            {
                "<A-a>",
                function()
                    require("multicursor-nvim").alignCursors()
                end,
                mode = { "n", "v" },
                desc = "MC: Align Cursors",
            },
            {
                "<A-[>",
                function()
                    require("multicursor-nvim").nextCursor()
                end,
                mode = { "n", "v" },
                desc = "MC: Next Cursor",
            },
            {
                "<A-]>",
                function()
                    require("multicursor-nvim").prevCursor()
                end,
                mode = { "n", "v" },
                desc = "MC: Prev Cursor",
            },
            {
                "<A-d>",
                function()
                    require("multicursor-nvim").deleteCursor()
                end,
                mode = { "n", "v" },
                desc = "MC: Delete Cursor",
            },
            {
                "<A-e>",
                function()
                    local mc = require("multicursor-nvim")
                    if mc.cursorsEnabled() then
                        mc.disableCursors()
                    else
                        mc.enableCursors()
                    end
                end,
                mode = "n",
                desc = "MC: Toggle Enabled",
            },
            {
                "I",
                function()
                    require("multicursor-nvim").insertVisual()
                end,
                mode = "v",
                desc = "MC: Insert Visual",
            },
            {
                "A",
                function()
                    require("multicursor-nvim").appendVisual()
                end,
                mode = "v",
                desc = "MC: Append Visual",
            },
        },
        config = function()
            local mc = require("multicursor-nvim")
            mc.setup()

            local function set_mc_highlights()
                vim.api.nvim_set_hl(0, "MultiCursorCursor", { link = "Cursor" })
                vim.api.nvim_set_hl(0, "MultiCursorVisual", { link = "Visual" })
                vim.api.nvim_set_hl(0, "MultiCursorSign", { link = "SignColumn" })
                vim.api.nvim_set_hl(0, "MultiCursorDisabledCursor", { link = "Comment" })
                vim.api.nvim_set_hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
                vim.api.nvim_set_hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
            end

            set_mc_highlights()
            vim.api.nvim_create_autocmd("ColorScheme", {
                group = vim.api.nvim_create_augroup("mc_hl", { clear = true }),
                callback = set_mc_highlights,
            })
        end,
    },

    {
        "uga-rosa/ccc.nvim",
        cmd = {
            "CccPick",
            "CccConvert",
            "CccHighlighterEnable",
            "CccHighlighterToggle",
            "CccHighlighterDisable",
        },
        keys = {
            { "<leader>Cp", "<cmd>CccPick<cr>", desc = "Pick & Edit Color" },
            { "<leader>Cc", "<cmd>CccConvert<cr>", desc = "Convert Color Format" },
            { "<leader>Ch", "<cmd>CccHighlighterToggle<cr>", desc = "Toggle Color Highlight" },
        },
        opts = {
            highlighter = {
                auto_enable = false,
            },
            recognize = {
                input = true,
                output = true,
            },
            bar_char = "🬋",
            point_char = "┃",
            win_opts = {
                border = "single",
                title = " 󰏘 Color ",
                title_pos = "center",
                width = 48,
            },
        },
        config = function(_, opts)
            local ccc = require("ccc")
            opts.pickers = {
                ccc.picker.hex,
                ccc.picker.hex_short,
                ccc.picker.css_rgb,
                ccc.picker.css_hsl,
                ccc.picker.css_hwb,
                ccc.picker.css_oklab,
                ccc.picker.css_oklch,
            }
            opts.inputs = {
                ccc.input.rgb,
                ccc.input.hsl,
                ccc.input.oklch,
            }
            opts.outputs = {
                ccc.output.hex,
                ccc.output.hex_short,
                ccc.output.css_rgb,
                ccc.output.css_hsl,
                ccc.output.css_hwb,
                ccc.output.css_oklch,
            }
            local mapping = ccc.mapping
            opts.mappings = {
                ["<CR>"] = mapping.complete,
                ["q"] = mapping.quit,
                ["<Esc>"] = mapping.quit,
                ["l"] = mapping.increase1,
                ["h"] = mapping.decrease1,
                ["L"] = mapping.increase10,
                ["H"] = mapping.decrease10,
                ["i"] = mapping.cycle_input_mode,
                ["o"] = mapping.cycle_output_mode,
                ["a"] = mapping.toggle_alpha,
            }
            ccc.setup(opts)
        end,
    },

    {
        "JoosepAlviste/nvim-ts-context-commentstring",
        ft = web_commentstring_fts,
        opts = { enable_autocmd = false },
        config = function(_, opts)
            require("ts_context_commentstring").setup(opts)
            vim.g.skip_ts_context_commentstring_module = true
            local get_option = vim.filetype.get_option
            vim.filetype.get_option = function(filetype, option)
                if
                    option == "commentstring" and vim.tbl_contains(web_commentstring_fts, filetype)
                then
                    return require("ts_context_commentstring.internal").calculate_commentstring()
                end
                return get_option(filetype, option)
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

    {
        "folke/persistence.nvim",
        event = "BufReadPre",
        opts = {},
        keys = {
            {
                "<leader>qS",
                function()
                    require("persistence").select()
                end,
                desc = "Select Session",
            },
            {
                "<leader>qs",
                function()
                    require("persistence").load()
                end,
                desc = "Restore Session",
            },
            {
                "<leader>ql",
                function()
                    require("persistence").load({ last = true })
                end,
                desc = "Restore Last Session",
            },
            {
                "<leader>qd",
                function()
                    require("persistence").stop()
                end,
                desc = "Don't Save Current Session",
            },
        },
    },
}
