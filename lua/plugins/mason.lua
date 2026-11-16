-- ATURAN PEMBAGIAN (hindari tool terpasang dua kali):
--   Mason   = binary yang HANYA dipakai di dalam editor (LSP, DAP, formatter buffer).
--   pacman  = toolchain bahasa (go, python, rustup) + tool yang dipanggil dari
--             terminal / Makefile / CI.
-- Jangan pasang tool yang sama di keduanya: mason/bin di-prepend ke PATH, sehingga
-- nvim memakai versi Mason sementara terminal memakai versi pacman (version skew).
return {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonLog" },
    opts_extend = { "ensure_installed" },
    init = function()
        local mason_bin = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin")
        -- Hindari duplikat PATH jika sudah ada (mason reinstall / reload)
        if not vim.env.PATH:find(mason_bin, 1, true) then
            vim.env.PATH = mason_bin .. ":" .. vim.env.PATH
        end

        -- Otomatis unduh paket Mason saat instalasi awal plugin selesai (cold-start / wipenvim)
        vim.api.nvim_create_autocmd("User", {
            pattern = "LazyInstall",
            once = true,
            callback = function()
                vim.schedule(function()
                    pcall(function()
                        require("lazy").load({ plugins = { "mason.nvim", "nvim-lspconfig" } })
                    end)
                end)
            end,
        })
    end,
    opts = {
        ui = {
            border = "single",
            icons = {
                package_installed = "✓",
                package_pending = "➜",
                package_uninstalled = "✗",
            },
        },
        log_level = vim.log.levels.INFO,
        max_concurrent_installers = 2,
        ensure_installed = {
            -- DAP
            "codelldb",
            "dart-debug-adapter",
            "debugpy",
            "delve",
            "js-debug-adapter",

            -- Formatters
            "buf",
            "gofumpt",
            "goimports",
            "gotests",
            "gomodifytags",
            "impl",
            "markdown-toc",
            "prettier", -- fallback conform bila prettierd gagal (lihat conform.lua)
            "prettierd",
            "shfmt",
            "sql-formatter",
            "sqlfluff",
            "stylua",
            "yamlfmt",

            -- Linters
            "actionlint", -- GitHub Actions workflow linter (presisi, ~5ms, zero FP)
            "golangci-lint",
            -- "staticcheck" DIHAPUS: tidak dipakai nvim-lint, dan gopls + golangci-lint
            -- sudah menjalankan analisis staticcheck → diagnostik dobel.
            "gotestsum", -- runner pretty untuk neotest-golang
            -- NOTE Go: govulncheck TIDAK ada di Mason registry.
            -- Install manual: go install golang.org/x/vuln/cmd/govulncheck@latest
            "hadolint",
            "htmlhint",
            "markdownlint-cli2",
            "selene",
            "shellcheck",
            "stylelint",
            "systemdlint", -- systemd unit file linter (.service, .timer, .socket)
            "yamllint",
            -- "typos" DIHAPUS: CLI typos tidak dirujuk nvim-lint/conform.
            -- Pemeriksaan ejaan memakai LSP typos_lsp (lihat lang/typos.lua).

            -- vue-language-server: hanya dipakai untuk @vue/typescript-plugin
            -- (vtsls plugin), bukan sebagai LSP — vue_ls di-disable di lang/vue.lua.
            "vue-language-server",

            -- NOTE: LSP servers auto-install via mason-lspconfig (lspconfig.lua).
            -- jangan di-ensure_installed di sini.
        },
    },
    config = function(_, opts)
        require("mason").setup(opts)
        local mr = require("mason-registry")
        mr:on("package:install:success", function()
            vim.defer_fn(function()
                require("lazy.core.handler.event").trigger({
                    event = "FileType",
                    buf = vim.api.nvim_get_current_buf(),
                })
            end, 100)
        end)

        local function ensure_installed()
            for _, tool in ipairs(opts.ensure_installed or {}) do
                pcall(function()
                    local p = mr.get_package(tool)
                    if not p:is_installed() then
                        p:install()
                    end
                end)
            end
        end

        -- JANGAN panggil mr.refresh() di jalur startup: ia melakukan update registry
        -- terhadap jaringan dan membekukan main loop saat koneksi lambat (repro:
        -- buka file apa pun -> BufReadPost -> lspconfig -> mason -> freeze).
        -- Install langsung dari cache registry lokal, ditunda ke idle.
        vim.defer_fn(ensure_installed, 2000)
    end,
}
