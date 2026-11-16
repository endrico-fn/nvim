return {
    "stevearc/aerial.nvim",
    event = { "LspAttach", "BufReadPost" },
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "echasnovski/mini.icons",
    },

    keys = {
        { "<leader>aa", "<cmd>AerialToggle!<cr>", desc = "Aerial (Symbol Outline)" },
        { "<leader>af", "<cmd>AerialNavToggle<cr>", desc = "Aerial Nav Float" },
        { "[S", "<cmd>AerialPrev<cr>", desc = "Aerial: Prev Symbol" },
        { "]S", "<cmd>AerialNext<cr>", desc = "Aerial: Next Symbol" },
    },

    opts = {

        layout = {
            min_width = 22,
            win_opts = {
                winhl = "Normal:NormalFloat,FloatBorder:FloatBorder,SignColumn:SignColumnSB",
                signcolumn = "yes",
                statuscolumn = " ",
            },
        },

        close_automatic_events = { "unfocus", "switch_buffer", "unsupported" },

        filter_kind = {
            "Class",
            "Constructor",
            "Enum",
            "Function",
            "Interface",
            "Method",
            "Module",
            "Namespace",
            "Package",
            "Property",
            "Struct",
            "Trait",
            "Type",
            "TypeParameter",
        },

        highlight_on_hover = true,

        show_guides = true,
        guides = {
            mid_item = "├╴",
            last_item = "└╴",
            nested_top = "│ ",
            whitespace = "  ",
        },

        get_highlight = function(symbol, is_icon, is_collapsed)
            if is_collapsed and symbol.children and #symbol.children > 0 then
                return "AerialCollapsed"
            end
            return string.format("Aerial%sIcon", symbol.kind)
        end,

        nav = {
            border = "single",
            max_width = 0.45,
            win_opts = { winblend = 10 },
        },

        lsp = {
            priority = { basedpyright = 10, lua_ls = 10 },
        },
    },

    config = function(_, opts)
        require("aerial").setup(opts)

        vim.api.nvim_set_hl(0, "AerialLine", { link = "Visual" })
        vim.api.nvim_set_hl(0, "AerialCollapsed", { link = "Folded" })
        vim.api.nvim_set_hl(0, "AerialGuide", { link = "NonText" })

        local kind_hl_map = {
            Array = "Constant",
            Boolean = "Boolean",
            Class = "Type",
            Constant = "Constant",
            Constructor = "Function",
            Enum = "Type",
            EnumMember = "Constant",
            Event = "Exception",
            Field = "Identifier",
            File = "Directory",
            Function = "Function",
            Interface = "Type",
            Key = "Identifier",
            Method = "Function",
            Module = "Include",
            Namespace = "Include",
            Null = "Constant",
            Number = "Number",
            Object = "Type",
            Operator = "Operator",
            Package = "Include",
            Property = "Identifier",
            String = "String",
            Struct = "Structure",
            TypeParameter = "TypeDef",
            Variable = "Identifier",
        }

        for kind, hl in pairs(kind_hl_map) do
            vim.api.nvim_set_hl(0, "Aerial" .. kind .. "Icon", { link = hl })
        end
    end,
}
