vim.g.mapleader = " "
vim.g.maplocalleader = ","

local keymap = vim.keymap.set

-- File & Quit
keymap("n", "<leader>W", "<cmd>noautocmd write<CR>", { desc = "Save without formatting" })
keymap("n", "<leader>qq", "<cmd>q<CR>", { desc = "Quit" })
keymap("n", "<leader>fn", "<cmd>enew<CR>", { desc = "New File" })

-- Window navigation & splits (preserves native '-' and '|' motions)
keymap("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })
keymap("n", "<leader>w-", "<cmd>split<CR>", { desc = "Horizontal split" })
keymap("n", "<leader>w|", "<cmd>vsplit<CR>", { desc = "Vertical split" })

keymap("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase height" })
keymap("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease height" })
keymap("n", "<C-Left>", "<cmd>vertical resize +2<CR>", { desc = "Increase width" })
keymap("n", "<C-Right>", "<cmd>vertical resize -2<CR>", { desc = "Decrease width" })

-- Clear hlsearch (and active multicursors only when already loaded — never loads eagerly)
keymap("n", "<Esc>", function()
    local mc = package.loaded["multicursor-nvim"]
    if mc and mc.hasCursors() then
        mc.clearCursors()
    else
        vim.cmd.nohlsearch()
    end
end, { desc = "Clear hlsearch / multicursors" })
keymap("i", "<Esc>", "<Esc><cmd>nohlsearch<CR>", { desc = "Exit insert & clear hlsearch" })

keymap("i", "jk", "<Esc>", { noremap = true, silent = true, desc = "Exit insert mode" })
keymap("v", "<", "<gv", { desc = "Indent left" })
keymap("v", ">", ">gv", { desc = "Indent right" })

-- Line moving (unobstructed after Kitty alt+shift+* migration)
keymap("n", "<A-j>", "<cmd>m .+1<CR>==", { desc = "Move line down" })
keymap("n", "<A-k>", "<cmd>m .-2<CR>==", { desc = "Move line up" })
keymap("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
keymap("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- UI Toggles & Built-in 0.12 Tools
keymap("n", "<leader>uw", function()
    vim.wo.wrap = not vim.wo.wrap
    vim.notify(
        "Word wrap: " .. (vim.wo.wrap and "ON" or "OFF"),
        vim.log.levels.INFO,
        { title = "UI" }
    )
end, { desc = "Toggle Word Wrap" })

keymap("n", "<leader>us", function()
    vim.opt_local.spell = not vim.opt_local.spell:get()
    vim.notify(
        "Spellcheck: " .. (vim.opt_local.spell:get() and "ON" or "OFF"),
        vim.log.levels.INFO,
        { title = "UI" }
    )
end, { desc = "Toggle Spellcheck" })

keymap("n", "<leader>uu", "<cmd>Undotree<CR>", { desc = "Toggle Native Undotree" })

-- Quickfix / Trouble navigation
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

-- Fold shortcuts
keymap("n", "<leader>zR", "zR", { desc = "Open All Folds" })
keymap("n", "<leader>zM", "zM", { desc = "Close All Folds" })
keymap("n", "<leader>za", "za", { desc = "Toggle Fold" })

-- gx: Open Markdown [text](url) link under cursor before falling back to native vim.ui.open
keymap("n", "gx", function()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2] + 1

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
