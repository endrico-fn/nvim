local function augroup(name)
    return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

-- Built-in optional plugins in Neovim 0.12
pcall(vim.cmd.packadd, "nvim.undotree")
pcall(vim.cmd.packadd, "nvim.difftool")

-- Built-in 0.12 UI2 message/cmdline presentation layer
pcall(function()
    require("vim._core.ui2").enable({
        enable = true,
        msg = {
            targets = "cmd",
        },
    })
end)

-- Register compound Treesitter languages
vim.treesitter.language.register("markdown", "markdown.mdx")
vim.treesitter.language.register("yaml", "yaml.docker-compose")

-- Per-buffer Treesitter highlight, foldexpr, and indentexpr (Neovim 0.12 native API)
local MAX_TS_FILESIZE = 512 * 1024
vim.api.nvim_create_autocmd("FileType", {
    group = augroup("treesitter_start"),
    callback = function(ev)
        local buf = ev.buf
        if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
            return
        end
        local ft = vim.bo[buf].filetype
        if ft == "" or ft == "bigfile" then
            return
        end
        local fname = vim.api.nvim_buf_get_name(buf)
        if fname ~= "" then
            local stat = vim.uv.fs_stat(fname)
            if stat and stat.size > MAX_TS_FILESIZE then
                return
            end
        end

        if pcall(vim.treesitter.start, buf) and vim.treesitter.highlighter.active[buf] then
            for _, win in ipairs(vim.fn.win_findbuf(buf)) do
                vim.wo[win].foldmethod = "expr"
                vim.wo[win].foldexpr = "v:lua.vim.treesitter.foldexpr()"
            end
            local lang = vim.treesitter.language.get_lang(ft)
            if
                lang
                and vim.treesitter.query.get(lang, "indents")
                and package.loaded["nvim-treesitter"]
            then
                vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end
        end
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = augroup("wrap_spell"),
    pattern = { "gitcommit", "markdown", "markdown.mdx", "text", "txt" },
    callback = function(ev)
        if vim.bo[ev.buf].buftype ~= "" then
            return
        end
        vim.opt_local.wrap = true
        vim.opt_local.spell = true
    end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
    group = augroup("highlight_yank"),
    callback = function()
        vim.hl.on_yank({
            higroup = "Visual",
            timeout = 200,
        })
    end,
})

vim.api.nvim_create_autocmd("VimResized", {
    group = augroup("resize_splits"),
    callback = function()
        vim.cmd("wincmd =")
    end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
    group = augroup("last_loc"),
    callback = function(ev)
        local exclude = { "gitcommit" }
        local buf = ev.buf
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

vim.api.nvim_create_autocmd("BufWritePre", {
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
            buf = event.buf,
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
        "nvim-undotree",
        "qf",
        "startuptime",
    },
    callback = function(event)
        vim.bo[event.buf].buflisted = false
        vim.keymap.set("n", "q", "<cmd>close<cr>", {
            buf = event.buf,
            silent = true,
            nowait = true,
            desc = "Close buffer",
        })
    end,
})

-- Lazy on-demand wrappers for util.sysdeps (keeps startup fast & non-intrusive)
vim.api.nvim_create_user_command("SysDepsCheck", function()
    require("util.sysdeps").check()
end, { desc = "Show system development dependencies status" })

vim.api.nvim_create_user_command("SysDepsInstall", function(args)
    require("util.sysdeps").install(args.args == "all")
end, {
    nargs = "?",
    complete = function()
        return { "all" }
    end,
    desc = "Install missing system dependencies via pacman and rustup",
})
