return {
    "uga-rosa/ccc.nvim",
    event = { "BufReadPost", "BufNewFile" },
    cmd = {
        "CccPick",
        "CccConvert",
        "CccHighlighterEnable",
        "CccHighlighterToggle",
        "CccHighlighterDisable",
    },
    keys = {
        { "<leader>Cp", "<cmd>CccPick<cr>", desc = "Pick & Edit" },
        { "<leader>Cc", "<cmd>CccConvert<cr>", desc = "Convert Format" },
        { "<leader>Ch", "<cmd>CccHighlighterToggle<cr>", desc = "Toggle Color Highlight" },
    },
    opts = {
        highlighter = {
            auto_enable = true,
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
}
