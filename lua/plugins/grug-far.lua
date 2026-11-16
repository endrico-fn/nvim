return {
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
}
