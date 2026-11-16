vim.g.mapleader = " "
vim.g.maplocalleader = ","

local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

keymap("n", "<leader>W", ":noautocmd write<CR>", { desc = "Save without formatting" })

keymap("n", "<leader>qq", "<cmd>q<CR>", { desc = "Quit" })

keymap("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

keymap("n", "<esc>", "<cmd>nohlsearch<CR>", { desc = "Clear hlsearch" })
keymap("i", "<esc>", "<esc><cmd>nohlsearch<CR>", { desc = "Exit insert & clear hlsearch" })

keymap("i", "jk", "<ESC>", { noremap = true, silent = true, desc = "Exit insert mode" })
keymap("v", "<", "<gv", { desc = "Indent left" })
keymap("v", ">", ">gv", { desc = "Indent right" })

keymap("n", "<A-j>", "<cmd>m .+1<CR>==", { desc = "Move line down" })
keymap("n", "<A-k>", "<cmd>m .-2<CR>==", { desc = "Move line up" })
keymap("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
keymap("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

keymap("n", "<C-Up>", ":resize +2<CR>", { desc = "Increase height" })
keymap("n", "<C-Down>", ":resize -2<CR>", { desc = "Decrease height" })
keymap("n", "<C-Left>", ":vertical resize +2<CR>", { desc = "Increase width" })
keymap("n", "<C-Right>", ":vertical resize -2<CR>", { desc = "Decrease width" })

keymap("n", "-", "<cmd>split<CR>", { desc = "Horizontal split" })
keymap("n", "|", "<cmd>vsplit<CR>", { desc = "Vertical split" })

keymap("n", "<leader>us", function()
    vim.opt.spell = not vim.opt.spell:get()
    vim.notify(
        "Spellcheck: " .. (vim.opt.spell:get() and "ON" or "OFF"),
        vim.log.levels.INFO,
        { title = "UI" }
    )
end, { desc = "Toggle Spellcheck" })

keymap("n", "<leader>fn", "<cmd>enew<CR>", { desc = "New File" })

keymap("n", "<A-z>", function()
    vim.wo.wrap = not vim.wo.wrap
    vim.notify(
        "Word wrap: " .. (vim.wo.wrap and "ON" or "OFF"),
        vim.log.levels.INFO,
        { title = "UI" }
    )
end, { desc = "Toggle Word Wrap" })

keymap("n", "[q", function()
    if package.loaded["trouble"] and require("trouble").is_open() then
        require("trouble").prev({ jump = true })
    else
        pcall(vim.cmd.cprev)
    end
end, { desc = "Previous Trouble/Quickfix Item" })

keymap("n", "]q", function()
    if package.loaded["trouble"] and require("trouble").is_open() then
        require("trouble").next({ jump = true })
    else
        pcall(vim.cmd.cnext)
    end
end, { desc = "Next Trouble/Quickfix Item" })

-- Native Fold Shortcuts
keymap("n", "<leader>zR", "zR", { desc = "Open All Folds" })
keymap("n", "<leader>zM", "zM", { desc = "Close All Folds" })
keymap("n", "<leader>za", "za", { desc = "Toggle Fold" })

-- gx: Buka URL/file (ekstensi markdown link di bawah kursor sebelum fallback ke native vim.ui.open)
keymap("n", "gx", function()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- 1-indexed

    -- Cari link markdown [text](url) yang melingkupi posisi kursor
    local target_url = nil
    local init = 1
    while true do
        local s, e, _, url = line:find("%[(.-)%]%((.-)%)", init)
        if not s then
            break
        end
        if col >= s and col <= e then
            target_url = url
            break
        end
        init = e + 1
    end

    if target_url then
        vim.ui.open(target_url)
        return
    end

    local cfile = vim.fn.expand("<cfile>")
    if cfile ~= "" then
        vim.ui.open(cfile)
    end
end, { desc = "Open URL or File under cursor", silent = true })
