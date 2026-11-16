return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
        {
            "<leader>uF",
            function()
                vim.g.disable_autoformat = not vim.g.disable_autoformat
                if vim.g.disable_autoformat then
                    vim.notify("Auto-format disabled", vim.log.levels.WARN)
                else
                    vim.notify("Auto-format enabled", vim.log.levels.INFO)
                end
            end,
            desc = "Toggle Auto-format",
        },
    },
    opts = {
        default_format_opts = {
            timeout_ms = 1500,
            async = true,
            quiet = false,
            lsp_format = "fallback",
        },
        formatters_by_ft = {
            javascript = { "biome-check", "prettierd", "prettier", stop_after_first = true },
            typescript = { "biome-check", "prettierd", "prettier", stop_after_first = true },
            javascriptreact = { "biome-check", "prettierd", "prettier", stop_after_first = true },
            typescriptreact = { "biome-check", "prettierd", "prettier", stop_after_first = true },
            css = { "biome-check", "prettierd", "prettier", stop_after_first = true },
            scss = { "biome-check", "prettierd", "prettier", stop_after_first = true },
            less = { "biome-check", "prettierd", "prettier", stop_after_first = true },
            html = { "biome-check", "prettierd", "prettier", stop_after_first = true },
            json = { "biome-check", "prettierd", "prettier", stop_after_first = true },
            jsonc = { "biome-check", "prettierd", "prettier", stop_after_first = true },
            json5 = { "biome-check", "prettierd", "prettier", stop_after_first = true },
            svelte = { "prettierd", "prettier", stop_after_first = true },
            vue = { "biome-check", "prettierd", "prettier", stop_after_first = true },
            astro = { "biome-check", "prettierd", "prettier", stop_after_first = true },
            yaml = { "yamlfmt", "prettierd", "prettier", stop_after_first = true },
            ["yaml.docker-compose"] = {
                "yamlfmt",
                "prettierd",
                "prettier",
                stop_after_first = true,
            },
            markdown = { "prettierd", "markdown-toc", "injected" },

            -- Biarkan bahasa backend/sistem lainnya tetap seperti semula
            lua = { "stylua" },
            python = { "ruff_organize_imports", "ruff_format" },
            sh = { "shfmt" },
            bash = { "shfmt" },
            toml = { "taplo", lsp_format = "prefer" },
            sql = { "sqlfluff", "sql_formatter", stop_after_first = true },
            proto = { "buf", lsp_format = "prefer" },
            c = { lsp_format = "prefer" },
            cpp = { lsp_format = "prefer" },
            go = { "goimports", lsp_format = "last" },
            rust = { "rustfmt", lsp_format = "prefer" },
            zig = { "zigfmt", lsp_format = "prefer" },
            dart = { "dart_format", lsp_format = "prefer" },
        },
        formatters = {
            -- Biome hanya bila proyek punya biome.json(c); selain itu stop_after_first
            -- jatuh ke prettierd/prettier.
            ["biome-check"] = {
                condition = function(_, ctx)
                    return vim.fs.find(
                        { "biome.json", "biome.jsonc" },
                        { path = ctx.filename, upward = true }
                    )[1] ~= nil
                end,
            },
            ["markdown-toc"] = {
                condition = function(_, ctx)
                    for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
                        if line:find("<!%-%- toc %-%->") then
                            return true
                        end
                    end
                end,
            },
            injected = {
                options = {
                    ignore_errors = true,
                },
            },
        },

        format_on_save = function(bufnr)
            if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                return
            end
            local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(bufnr))
            if ok and stats and stats.size > 100 * 1024 then
                return
            end
            if vim.bo[bufnr].buftype ~= "" then
                return
            end
            return { timeout_ms = 5000 }
        end,

        notify_on_error = true,
        notify_no_formatters = false,

        log_level = vim.log.levels.WARN,
    },
}
