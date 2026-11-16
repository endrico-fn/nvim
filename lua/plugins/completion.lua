return {
    {
        "L3MON4D3/LuaSnip",
        build = "make install_jsregexp",
        dependencies = {
            "rafamadriz/friendly-snippets",
        },
        keys = {
            {
                "<C-l>",
                function()
                    if require("luasnip").jumpable(1) then
                        require("luasnip").jump(1)
                    end
                end,
                mode = { "i", "s" },
                desc = "LuaSnip: Jump forward",
            },
            {
                "<C-k>",
                function()
                    if require("luasnip").jumpable(-1) then
                        require("luasnip").jump(-1)
                    end
                end,
                mode = { "i", "s" },
                desc = "LuaSnip: Jump backward",
            },
            {
                "<C-y>",
                function()
                    if require("luasnip").choice_active() then
                        require("luasnip").change_choice(1)
                    end
                end,
                mode = { "i", "s" },
                desc = "LuaSnip: Next choice",
            },
            {
                "<C-Y>",
                function()
                    if require("luasnip").choice_active() then
                        require("luasnip").change_choice(-1)
                    end
                end,
                mode = { "i", "s" },
                desc = "LuaSnip: Prev choice",
            },
            {
                "<leader>rs",
                function()
                    local luasnip_path = vim.fn.stdpath("config") .. "/luasnippets"
                    local from_lua = require("luasnip.loaders.from_lua")
                    if vim.fn.isdirectory(luasnip_path) == 1 then
                        from_lua.load({ paths = { luasnip_path } })
                    end
                    vim.notify("Snippets reloaded", vim.log.levels.INFO, { title = "LuaSnip" })
                end,
                mode = "n",
                desc = "Reload snippets",
            },
        },
        opts = function()
            local types = require("luasnip.util.types")
            return {
                history = true,
                update_events = "TextChangedI,InsertLeave",
                delete_check_events = "TextChanged",
                enable_autosnippets = true,
                store_selection_keys = "<Tab>",
                ext_opts = {
                    [types.choiceNode] = {
                        active = {
                            virt_text = { { "⟳", "BlinkCmpSource" } },
                        },
                    },
                    [types.insertNode] = {
                        active = {
                            virt_text = { { "●", "Comment" } },
                        },
                    },
                },
                ft_func = require("luasnip.extras.filetype_functions").from_pos_or_filetype,
            }
        end,
        config = function(_, opts)
            require("luasnip").setup(opts)
            require("luasnip.loaders.from_lua").lazy_load({
                paths = { vim.fn.stdpath("config") .. "/luasnippets" },
            })
            require("luasnip.loaders.from_vscode").lazy_load()
        end,
    },

    {
        "saghen/blink.cmp",
        version = "1.*",
        event = { "InsertEnter", "CmdlineEnter" },
        dependencies = {
            "L3MON4D3/LuaSnip",
            "rafamadriz/friendly-snippets",
            "kristijanhusak/vim-dadbod-completion",
        },
        opts = {
            keymap = {
                preset = "none",
                ["<C-Space>"] = { "show", "show_documentation" },
                ["<C-e>"] = { "hide" },
                ["<CR>"] = { "accept", "fallback" },
                ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
                ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
                ["<C-n>"] = { "select_next", "fallback" },
                ["<C-p>"] = { "select_prev", "fallback" },
                ["<C-u>"] = { "scroll_documentation_up", "fallback" },
                ["<C-d>"] = { "scroll_documentation_down", "fallback" },
            },

            snippets = {
                preset = "luasnip",
            },

            appearance = {
                kind_icons = {
                    Text = "󰉿",
                    Method = "󰊕",
                    Function = "󰊕",
                    Constructor = "󰒓",
                    Field = "󰜢",
                    Variable = "󰆦",
                    Class = "󰌗",
                    Interface = "󰭦",
                    Module = "󰅩",
                    Property = "󰜢",
                    Unit = "󰪚",
                    Value = "󰦨",
                    Enum = "󰐦",
                    EnumMember = "󰐦",
                    Keyword = "󰵳",
                    Snippet = "󰵳",
                    Color = "󰏘",
                    File = "󰈔",
                    Reference = "󰬲",
                    Folder = "󰉋",
                    Constant = "󰏿",
                    Struct = "󰙅",
                    Event = "󱐋",
                    Operator = "󰪚",
                    TypeParameter = "󰬛",
                },
            },

            sources = {
                providers = {
                    lsp = {
                        name = "LSP",
                        score_offset = 10,
                    },
                    lazydev = {
                        name = "LazyDev",
                        module = "lazydev.integrations.blink",
                        score_offset = 100,
                    },
                    snippets = {
                        name = "Snippets",
                        score_offset = 3,
                        min_keyword_length = 2,
                    },
                    buffer = {
                        name = "Buffer",
                        min_keyword_length = 4,
                        max_items = 8,
                    },
                    dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
                },
                per_filetype = {
                    lua = { inherit_defaults = true, "lazydev" },
                    sql = { "dadbod", "lsp", "snippets", "buffer" },
                    mysql = { "dadbod", "lsp", "snippets", "buffer" },
                    pgsql = { "dadbod", "lsp", "snippets", "buffer" },
                },
            },

            signature = {
                enabled = true,
                window = {
                    border = "single",
                },
            },

            cmdline = {
                enabled = true,
                keymap = {
                    preset = "cmdline",
                    ["<Right>"] = false,
                    ["<Left>"] = false,
                    ["<Up>"] = { "select_prev", "fallback" },
                    ["<Down>"] = { "select_next", "fallback" },
                },
                completion = {
                    menu = {
                        auto_show = function()
                            return vim.fn.getcmdtype() == ":"
                        end,
                    },
                    ghost_text = {
                        enabled = true,
                    },
                },
            },

            completion = {
                list = { selection = { preselect = true, auto_insert = false } },
                ghost_text = { enabled = true },
                menu = {
                    border = "single",
                    draw = {
                        treesitter = { "lsp" },
                        align_to = "label",
                        padding = 1,
                        gap = 1,
                        columns = {
                            { "kind_icon", "label", "label_description", gap = 1 },
                            { "source_name" },
                        },
                        components = {
                            source_name = {
                                width = { max = 4 },
                                text = function(ctx)
                                    local map = {
                                        LSP = "LSP",
                                        Buffer = "BUF",
                                        Snippets = "SNP",
                                        Path = "PTH",
                                        LazyDev = "DEV",
                                        Dadbod = "DB",
                                    }
                                    return map[ctx.source_name] or ctx.source_name:sub(1, 3)
                                end,
                                highlight = "BlinkCmpSource",
                            },
                        },
                    },
                },
                documentation = {
                    window = {
                        border = "single",
                    },
                    auto_show = true,
                    auto_show_delay_ms = 400,
                },
            },
        },
    },
}
