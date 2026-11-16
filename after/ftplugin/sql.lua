local buf = vim.api.nvim_get_current_buf()
vim.opt_local.commentstring = "-- %s"

vim.keymap.set("n", "<leader>De", ":SQLiteExec ", {
    buf = buf,
    noremap = true,
    desc = "SQLite: Execute Query",
})
