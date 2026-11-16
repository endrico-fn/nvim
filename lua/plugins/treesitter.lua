return {
    {
        "nvim-treesitter/nvim-treesitter",
        version = false,
        lazy = false,
        build = ":TSUpdate",
        cmd = { "TSInstall", "TSUpdate" },
        opts = {
            install_dir = vim.fn.stdpath("data") .. "/site",
            ensure_installed = {
                "bash",
                "c",
                "diff",
                "go",
                "javascript",
                "json",
                "lua",
                "markdown",
                "markdown_inline",
                "python",
                "query",
                "regex",
                "rust",
                "toml",
                "tsx",
                "typescript",
                "vim",
                "vimdoc",
                "yaml",
            },
        },
        config = function(_, opts)
            require("nvim-treesitter").setup(opts)

            local install = require("nvim-treesitter.install")
            local config_mod = require("nvim-treesitter.config")
            local parsers = require("nvim-treesitter.parsers")
            local async = require("nvim-treesitter.async")

            local pending = {}

            local function ensure_lang(lang, on_done)
                if not lang or lang == "" or pending[lang] then
                    return
                end
                if
                    vim.fn.executable("cc") == 0
                    and vim.fn.executable("gcc") == 0
                    and vim.fn.executable("clang") == 0
                then
                    return
                end
                if not vim.tbl_contains(config_mod.get_available(), lang) then
                    return
                end
                if vim.tbl_contains(config_mod.get_installed(), lang) then
                    if on_done then
                        on_done()
                    end
                    return
                end

                pending[lang] = true
                local to_install = { lang }
                if parsers[lang] and parsers[lang].requires then
                    vim.list_extend(to_install, parsers[lang].requires)
                end

                local task = install.install(to_install, { summary = true })
                async.arun(function()
                    local ok, err = pcall(async.join, { task })
                    pending[lang] = nil
                    if not ok then
                        vim.schedule(function()
                            vim.notify(
                                ("treesitter: gagal install parser '%s': %s"):format(lang, err),
                                vim.log.levels.WARN
                            )
                        end)
                        return
                    end
                    if on_done then
                        vim.schedule(on_done)
                    end
                end)
            end

            for _, lang in ipairs(opts.ensure_installed or {}) do
                ensure_lang(lang)
            end

            -- Auto-install missing non-core parsers on demand when opening matching filetypes
            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup("treesitter_auto_install", { clear = true }),
                callback = function(args)
                    local buf = args.buf
                    local ft = vim.bo[buf].filetype
                    if ft == "" or ft == "bigfile" or vim.bo[buf].buftype ~= "" then
                        return
                    end
                    local lang = vim.treesitter.language.get_lang(ft) or ft

                    local function start()
                        if not vim.api.nvim_buf_is_valid(buf) then
                            return
                        end
                        if pcall(vim.treesitter.start, buf, lang) then
                            for _, win in ipairs(vim.fn.win_findbuf(buf)) do
                                vim.wo[win].foldmethod = "expr"
                                vim.wo[win].foldexpr = "v:lua.vim.treesitter.foldexpr()"
                            end
                            if vim.treesitter.query.get(lang, "indents") then
                                vim.bo[buf].indentexpr =
                                    "v:lua.require'nvim-treesitter'.indentexpr()"
                            end
                        end
                    end

                    if not vim.tbl_contains(config_mod.get_installed(), lang) then
                        ensure_lang(lang, start)
                    end
                end,
            })
        end,
    },

    {
        "nvim-treesitter/nvim-treesitter-context",
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            max_lines = 3,
            min_window_height = 20,
            multiline_threshold = 1,
            trim_scope = "outer",
            mode = "cursor",
            separator = nil,
        },
        keys = {
            {
                "[C",
                function()
                    require("treesitter-context").go_to_context(vim.v.count1)
                end,
                desc = "Jump to Context Header",
            },
            {
                "<leader>ux",
                function()
                    require("treesitter-context").toggle()
                end,
                desc = "Toggle Treesitter Context",
            },
        },
    },
}
