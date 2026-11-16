vim.keymap.set("n", "<leader>kz", "<cmd>terminal zig build<cr>", {
    buf = 0,
    silent = true,
    noremap = true,
    desc = "Zig: Build",
})
