vim.keymap.set("n", "<leader>ch", "<cmd>LspClangdSwitchSourceHeader<cr>", {
    buf = 0,
    silent = true,
    noremap = true,
    desc = "C: Switch Source/Header",
})
