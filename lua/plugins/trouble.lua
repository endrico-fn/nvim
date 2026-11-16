return {
    "folke/trouble.nvim",
    cmd = "Trouble",
    dependencies = { "echasnovski/mini.icons" },
    keys = {
        { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Workspace Diagnostics" },
        {
            "<leader>xX",
            "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
            desc = "Buffer Diagnostics",
        },
        {
            "<leader>xE",
            "<cmd>Trouble diagnostics toggle filter.severity=vim.diagnostic.severity.ERROR<cr>",
            desc = "Errors Only",
        },
        {
            "<leader>xW",
            "<cmd>Trouble diagnostics toggle filter.severity={min=vim.diagnostic.severity.WARN}<cr>",
            desc = "Warnings + Errors",
        },
        { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols" },
        {
            "<leader>xl",
            "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
            desc = "LSP Panel",
        },
        { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List" },
        { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List" },
    },
    opts = {
        auto_close = true,
        focus = true,
    },
}
