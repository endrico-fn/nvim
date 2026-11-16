return {
    "nvim-treesitter/nvim-treesitter",
    version = false,
    build = ":TSUpdate",
    event = { "BufReadPre", "BufNewFile", "VeryLazy" },
    cmd = { "TSInstall", "TSUpdate", "TSUpdateSync" },
    opts = {
        install_dir = vim.fn.stdpath("data") .. "/site",
        ensure_installed = {
            "astro",
            "bash",
            "c",
            "cpp",
            "css",
            "dart",
            "diff",
            "dockerfile",
            "gitcommit",
            "gitignore",
            "go",
            "gomod",
            "gosum",
            "gowork",
            "html",
            "javascript",
            "jsdoc",
            "json",
            "json5",
            "jsonc",
            "lua",
            "luadoc",
            "markdown",
            "markdown_inline",
            "proto",
            "python",
            "query",
            "regex",
            "rust",
            "scss",
            "sql",
            "svelte",
            "toml",
            "tsx",
            "typescript",
            "vim",
            "vimdoc",
            "vue",
            "yaml",
            "zig",
        },
    },

    config = function(_, opts)
        require("nvim-treesitter.config").setup(opts)

        local install = require("nvim-treesitter.install")
        local config_mod = require("nvim-treesitter.config")
        local parsers = require("nvim-treesitter.parsers")
        local async = require("nvim-treesitter.async")

        local ft_to_lang = {
            javascriptreact = "javascript",
            typescriptreact = "tsx",
            ["markdown.mdx"] = "markdown",
            ["yaml.docker-compose"] = "yaml",
        }

        -- satu state dipakai bersama oleh bulk install & per-filetype install
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

        -- 1) bulk install daftar ensure_installed, sekarang ada feedback kalau gagal
        for _, lang in ipairs(opts.ensure_installed or {}) do
            ensure_lang(lang)
        end

        -- 2) fallback: bahasa lain yang tidak ada di ensure_installed,
        --    plus langsung nyalakan highlight begitu parser siap
        vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("treesitter_auto_install", { clear = true }),
            callback = function(args)
                local ft = vim.bo[args.buf].filetype
                if ft == "" then
                    return
                end
                local lang = ft_to_lang[ft] or ft

                local function start()
                    if vim.api.nvim_buf_is_valid(args.buf) then
                        pcall(vim.treesitter.start, args.buf, lang)
                    end
                end

                if vim.tbl_contains(config_mod.get_installed(), lang) then
                    start()
                else
                    ensure_lang(lang, start)
                end
            end,
        })
    end,
}
