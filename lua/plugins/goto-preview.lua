return {
    "rmagatti/goto-preview",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
        {
            "gpd",
            function()
                require("goto-preview").goto_preview_definition()
            end,
            desc = "Preview Definition",
        },
        {
            "gpi",
            function()
                require("goto-preview").goto_preview_implementation()
            end,
            desc = "Preview Implementation",
        },
        {
            "gpD",
            function()
                require("goto-preview").goto_preview_declaration()
            end,
            desc = "Preview Declaration",
        },
        {
            "gpt",
            function()
                require("goto-preview").goto_preview_type_definition()
            end,
            desc = "Preview Type Definition",
        },
        {
            "gpr",
            function()
                require("goto-preview").goto_preview_references()
            end,
            desc = "Preview References",
        },
        {
            "gP",
            function()
                require("goto-preview").close_all_win()
            end,
            desc = "Close All Previews",
        },
    },
    opts = {
        border = "single",
        preview_window = { border = "single" },
    },
}
