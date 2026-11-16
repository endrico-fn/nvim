local function augroup(name)
    return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

vim.api.nvim_create_autocmd("FileType", {
    group = augroup("wrap_spell"),
    pattern = { "gitcommit", "markdown", "text", "txt" },
    callback = function()
        vim.opt_local.wrap = true
        vim.opt_local.spell = true
    end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
    group = augroup("highlight_yank"),
    callback = function()
        (vim.hl or vim.highlight).on_yank({
            higroup = "Visual",
            timeout = 200,
        })
    end,
})

vim.api.nvim_create_autocmd({ "VimResized" }, {
    group = augroup("resize_splits"),
    callback = function()
        vim.cmd("wincmd =")
    end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
    group = augroup("last_loc"),
    callback = function()
        local exclude = { "gitcommit" }
        local buf = vim.api.nvim_get_current_buf()
        if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].user_last_loc then
            return
        end
        vim.b[buf].user_last_loc = true
        local mark = vim.api.nvim_buf_get_mark(buf, '"')
        local lcount = vim.api.nvim_buf_line_count(buf)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = augroup("web_indent"),
    pattern = {
        "astro",
        "svelte",
        "vue",
        "typescript",
        "typescriptreact",
        "javascript",
        "javascriptreact",
        "css",
        "scss",
        "html",
        "json",
        "jsonc",
    },
    callback = function()
        vim.opt_local.tabstop = 2
        vim.opt_local.softtabstop = 2
        vim.opt_local.shiftwidth = 2
    end,
})

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    group = augroup("auto_create_dir"),
    callback = function(event)
        if event.match:match("^%w%w+:[\\/][\\/]") then
            return
        end
        local file = vim.uv.fs_realpath(event.match) or event.match
        vim.fn.mkdir(vim.fn.fnamemodify(file, ":h"), "p")
    end,
})

vim.api.nvim_create_autocmd("TermOpen", {
    group = augroup("terminal_settings"),
    callback = function(event)
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], {
            buffer = event.buf,
            silent = true,
            desc = "Terminal: Normal mode",
        })
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = augroup("close_with_q"),
    pattern = {
        "checkhealth",
        "grug-far-help",
        "help",
        "lspinfo",
        "man",
        "neotest-output",
        "neotest-output-panel",
        "neotest-summary",
        "notify",
        "qf",
        "startuptime",
    },
    callback = function(event)
        vim.bo[event.buf].buflisted = false
        vim.keymap.set("n", "q", "<cmd>close<cr>", {
            buffer = event.buf,
            silent = true,
            nowait = true,
            desc = "Close buffer",
        })
    end,
})
