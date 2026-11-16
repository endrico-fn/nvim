return {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
        linters_by_ft = {
            sh = { "shellcheck" },
            bash = { "shellcheck" },
            zsh = { "shellcheck" },
            css = { "stylelint" },
            scss = { "stylelint" },
            -- Astro: Astro LSP + eslint cover template errors; stylelint gated per project
            astro = { "stylelint" },
            -- Svelte: stylelint jika project punya .stylelintrc
            svelte = { "stylelint" },
            dockerfile = { "hadolint" },
            go = { "golangcilint" },
            -- htmlhint hanya untuk file HTML murni, gated via .htmlhintrc
            html = { "htmlhint" },
            json = {},
            lua = { "selene" },
            markdown = { "markdownlint-cli2" },
            proto = { "buf_lint" },
            python = {}, -- ruff LSP handle lint — nvim-lint sengaja kosong biar tidak dobel
            sql = { "sqlfluff" },
            -- systemd unit files: .service, .timer, .socket, .target, .mount, dll
            systemd = { "systemdlint" },
            yaml = { "yamllint", "actionlint" },
            ["yaml.docker-compose"] = { "yamllint" },
        },
        linters = {
            actionlint = {
                -- Hanya aktif di dalam .github/workflows/ — tidak pernah jalan di YAML biasa
                condition = function(ctx)
                    return ctx.filename:find("%.github[/\\]workflows[/\\]", 1, false) ~= nil
                end,
            },
            -- selene hanya jalan jika ada selene.toml (hindari noise di luar proyek selene)
            selene = {
                condition = function(ctx)
                    return vim.fs.find({ "selene.toml" }, { path = ctx.dirname, upward = true })[1]
                        ~= nil
                end,
            },
            -- markdownlint hanya jika proyek punya config (default rules sangat berisik, mis. MD013)
            ["markdownlint-cli2"] = {
                condition = function(ctx)
                    return vim.fs.find({
                        ".markdownlint-cli2.jsonc",
                        ".markdownlint-cli2.yaml",
                        ".markdownlint",
                        ".markdownlint.json",
                        ".markdownlint.jsonc",
                        ".markdownlint.yaml",
                        ".markdownlint.yml",
                        ".markdownlint.cjs",
                        ".markdownlint.mjs",
                        "markdownlint.json",
                        "markdownlint.yaml",
                        "markdownlint.yml",
                        "markdownlint.cjs",
                        "markdownlint.mjs",
                    }, { path = ctx.dirname, upward = true })[1] ~= nil
                end,
            },
            htmlhint = {
                -- hanya jalan jika project punya .htmlhintrc (hindari default rules yg berisik)
                condition = function(ctx)
                    return vim.fs.find({
                        ".htmlhintrc",
                        ".htmlhintrc.json",
                        ".htmlhintrc.js",
                        "htmlhint.config.js",
                    }, { path = ctx.dirname, upward = true })[1] ~= nil
                end,
            },
            stylelint = {
                condition = function(ctx)
                    return vim.fs.find({
                        ".stylelintrc",
                        ".stylelintrc.json",
                        ".stylelintrc.yaml",
                        ".stylelintrc.yml",
                        ".stylelintrc.js",
                        "stylelint.config.js",
                        "stylelint.config.mjs",
                    }, { path = ctx.dirname, upward = true })[1] ~= nil
                end,
            },
            sqlfluff = {
                condition = function(ctx)
                    return vim.fs.find({
                        ".sqlfluff",
                        ".sqlfluff.toml",
                        "pyproject.toml",
                        "setup.cfg",
                        "tox.ini",
                    }, { path = ctx.dirname, upward = true })[1] ~= nil
                end,
            },
            golangcilint = {
                -- Gate: hanya jalan di dalam modul Go (hemat CPU/RAM Celeron 3.4GB).
                -- nvim-lint upstream sudah branch args v1/v2 otomatis (getArgs via
                -- `golangci-lint version`), jadi tidak perlu override args di sini.
                -- Standalone file tanpa go.mod tetap ke-handle upstream via :p modifier.
                condition = function(ctx)
                    return vim.fs.find({
                        "go.work",
                        "go.mod",
                        ".golangci.yml",
                        ".golangci.yaml",
                        ".golangci.toml",
                        ".golangci.json",
                    }, { path = ctx.dirname, upward = true })[1] ~= nil
                end,
            },
        },
    },
    config = function(_, opts)
        local lint = require("lint")
        lint.linters_by_ft = opts.linters_by_ft
        for name, linter in pairs(opts.linters or {}) do
            lint.linters[name] = lint.linters[name] or {}
            lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name], linter)
        end

        local lint_timers = {}

        local _notified_missing = {}

        local function smart_lint(bufnr)
            if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
                return
            end
            local ft = vim.bo[bufnr].filetype
            if ft == "" or vim.b[bufnr].sqlite_path then
                return
            end

            local linters = lint.linters_by_ft[ft] or {}
            local available = {}
            for _, name in ipairs(linters) do
                local linter = lint.linters[name]
                if linter then
                    local should_run = true
                    if linter.condition then
                        local filename = vim.api.nvim_buf_get_name(bufnr)
                        local dirname = filename ~= "" and vim.fn.fnamemodify(filename, ":h")
                            or vim.fn.getcwd()
                        local ctx = { dirname = dirname, filename = filename, bufnr = bufnr }
                        local ok, res = pcall(linter.condition, ctx)
                        if not ok or not res then
                            should_run = false
                        end
                    end
                    if should_run then
                        local cmd = type(linter.cmd) == "function" and linter.cmd() or linter.cmd
                        if vim.fn.executable(cmd or name) == 1 then
                            table.insert(available, name)
                        elseif not _notified_missing[name] then
                            _notified_missing[name] = true
                            vim.notify(
                                "Linter '" .. name .. "' tidak ditemukan. Install via Mason.",
                                vim.log.levels.WARN,
                                { title = "nvim-lint" }
                            )
                        end
                    end
                end
            end

            if #available > 0 and vim.api.nvim_buf_is_valid(bufnr) then
                vim.api.nvim_buf_call(bufnr, function()
                    lint.try_lint(available)
                end)
            end
        end

        vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
            group = vim.api.nvim_create_augroup("user_lint", { clear = true }),
            callback = function(args)
                local bufnr = args.buf
                if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
                    return
                end
                local timer = lint_timers[bufnr]
                if timer then
                    pcall(function()
                        if not timer:is_closing() then
                            timer:stop()
                            timer:close()
                        end
                    end)
                end
                local new_timer = vim.uv.new_timer()
                lint_timers[bufnr] = new_timer
                new_timer:start(
                    300,
                    0,
                    vim.schedule_wrap(function()
                        pcall(function()
                            if not new_timer:is_closing() then
                                new_timer:close()
                            end
                        end)
                        lint_timers[bufnr] = nil
                        smart_lint(bufnr)
                    end)
                )
            end,
        })

        vim.api.nvim_create_autocmd("BufDelete", {
            group = vim.api.nvim_create_augroup("user_lint_cleanup", { clear = true }),
            callback = function(args)
                local timer = lint_timers[args.buf]
                if timer then
                    pcall(function()
                        if not timer:is_closing() then
                            timer:stop()
                            timer:close()
                        end
                    end)
                    lint_timers[args.buf] = nil
                end
            end,
        })
    end,
}
