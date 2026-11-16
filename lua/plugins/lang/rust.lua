local system_cores = #(vim.uv.cpu_info() or {})
local optimal_threads = math.max(1, system_cores > 2 and (system_cores - 1) or 1)
local cargo_jobs = tostring(math.max(1, math.min(2, system_cores - 1)))

return {
    {
        "mrcjkb/rustaceanvim",
        version = false,
        ft = { "rust" },
        init = function()
            -- Inisialisasi vim.g.rustaceanvim via closure fungsi sesuai panduan resmi rustaceanvim.
            -- Dievaluasi dinamis saat ftplugin/rust.lua dimuat sebelum LSP client di-attach.
            vim.g.rustaceanvim = function()
                local codelldb = vim.fn.exepath("codelldb")
                local dap_cfg = {
                    autoload_configurations = false,
                }

                if codelldb ~= "" then
                    local system_lib_path = "/usr/lib/liblldb.so"
                    local mason_lib_path = vim.fn.stdpath("data")
                        .. "/mason/packages/codelldb/extension/lldb/lib/liblldb.so"
                    local lib_path = vim.uv.fs_stat(system_lib_path) and system_lib_path
                        or mason_lib_path
                    if vim.uv.fs_stat(lib_path) then
                        dap_cfg.adapter =
                            require("rustaceanvim.config").get_codelldb_adapter(codelldb, lib_path)
                    end
                end

                return {
                    dap = dap_cfg,
                    server = {
                        default_settings = {
                            ["rust-analyzer"] = {
                                cargo = {
                                    buildScripts = { enable = true },
                                    -- allFeatures=false mencegah RA meng-index ratusan fitur crate eksternal
                                    -- yang tidak dipakai, menghemat 500MB-1GB RAM dan konsisten dengan Cargo.toml
                                    allFeatures = false,
                                    loadOutDirsFromCheck = true,
                                    targetDir = vim.fn.stdpath("cache") .. "/rust-analyzer-target/",
                                },
                                procMacro = {
                                    enable = true,
                                    attributes = { enable = true },
                                },
                                server = {
                                    extraEnv = {
                                        RA_LOG = "error",
                                    },
                                },
                                workspace = {
                                    symbol = { search = { scope = "workspace", limit = 128 } },
                                },
                                numThreads = optimal_threads,
                                check = {
                                    command = "clippy",
                                    allTargets = true,
                                    -- Batasi kompilasi clippy maksimal 2 jobs agar Celeron N4120 tidak 100% tersedot
                                    extraArgs = { "--no-deps", "-j", cargo_jobs },
                                },
                                diagnostics = {
                                    enable = true,
                                    experimental = { enable = false },
                                    disabled = { "unresolved-proc-macro" },
                                },
                                files = {
                                    excludeDirs = {
                                        ".direnv",
                                        ".git",
                                        ".jj",
                                        ".github",
                                        ".gitlab",
                                        "bin",
                                        "node_modules",
                                        "target",
                                        "venv",
                                        ".venv",
                                    },
                                    -- Inotify server Linux lebih efisien daripada polling/client watcher
                                    watcher = "server",
                                },
                                inlayHints = {
                                    bindingModeHints = { enable = true },
                                    chainingHints = { enable = true },
                                    closingBraceHints = { enable = true, minLines = 10 },
                                    parameterHints = { enable = true },
                                    typeHints = { enable = true },
                                    maxLength = 25,
                                },
                                lru = { capacity = 128 },
                                -- Lazy on-demand parsing, buka file instan tanpa CPU 100% di startup
                                cachePriming = { enable = false },
                                completion = {
                                    callable = { snippets = "fill_arguments" },
                                    postfix = { enable = true },
                                },
                                hover = {
                                    actions = {
                                        enable = true,
                                        references = false,
                                    },
                                },
                                lens = {
                                    -- Matikan kalkulasi graph referensi yang tidak dirender di Neovim UI
                                    enable = false,
                                },
                            },
                        },
                    },
                }
            end
        end,
        config = function()
            if vim.fn.executable("rust-analyzer") == 0 then
                vim.notify(
                    "rust-analyzer tidak ditemukan di PATH.",
                    vim.log.levels.ERROR,
                    { title = "rustaceanvim" }
                )
            end
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("rustaceanvim_keymaps", { clear = true }),
                callback = function(args)
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if not client or client.name ~= "rust-analyzer" then
                        return
                    end
                    local bufnr = args.buf

                    -- Navigasi & Tindakan Cepat Rustacean
                    vim.keymap.set("n", "<leader>ca", function()
                        vim.cmd.RustLsp("codeAction")
                    end, { desc = "Rust: Code Action", buffer = bufnr })
                    vim.keymap.set("n", "<leader>dD", function()
                        vim.cmd.RustLsp("debuggables")
                    end, { desc = "Rust: Debuggables", buffer = bufnr })
                    vim.keymap.set("n", "<leader>ke", function()
                        vim.cmd.RustLsp("explainError")
                    end, { desc = "Rust: Explain Error", buffer = bufnr })
                    vim.keymap.set("n", "<leader>kd", function()
                        vim.cmd.RustLsp("renderDiagnostic")
                    end, {
                        desc = "Rust: Render Diagnostic (Full ANSI)",
                        buffer = bufnr,
                    })
                    vim.keymap.set("n", "<leader>kp", function()
                        vim.cmd.RustLsp("parentModule")
                    end, { desc = "Rust: Parent Module", buffer = bufnr })
                    vim.keymap.set("n", "<leader>kC", function()
                        vim.cmd.RustLsp("openCargo")
                    end, { desc = "Rust: Open Cargo.toml", buffer = bufnr })
                    vim.keymap.set("n", "<leader>kR", function()
                        vim.cmd.RustLsp("runnables")
                    end, { desc = "Rust: Runnables (Run)", buffer = bufnr })
                    vim.keymap.set("n", "<leader>kT", function()
                        vim.cmd.RustLsp("testables")
                    end, { desc = "Rust: Testables (Test)", buffer = bufnr })
                    vim.keymap.set("n", "<leader>km", function()
                        vim.cmd.RustLsp("expandMacro")
                    end, { desc = "Rust: Expand Macro", buffer = bufnr })
                    vim.keymap.set("n", "<leader>ko", function()
                        vim.cmd.RustLsp("openDocs")
                    end, { desc = "Rust: Open Docs.rs", buffer = bufnr })
                    vim.keymap.set("n", "<leader>kF", function()
                        vim.cmd.RustLsp({ "flyCheck", "run" })
                    end, { desc = "Rust: Trigger FlyCheck", buffer = bufnr })
                    vim.keymap.set("n", "<leader>kP", function()
                        vim.cmd.RustLsp("rebuildProcMacros")
                    end, { desc = "Rust: Rebuild Proc Macros", buffer = bufnr })
                    vim.keymap.set("n", "<leader>dN", function()
                        ---@diagnostic disable-next-line: missing-fields
                        require("neotest").run.run({ strategy = "dap" })
                    end, { desc = "Rust: Debug Nearest Test", buffer = bufnr })
                end,
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}
            opts.servers.rust_analyzer =
                vim.tbl_deep_extend("force", opts.servers.rust_analyzer or {}, {
                    enabled = false,
                })
        end,
    },
    {
        "saecki/crates.nvim",
        event = { "BufRead Cargo.toml", "BufNewFile Cargo.toml" },
        keys = {
            {
                "<leader>kcu",
                function()
                    require("crates").update_crate()
                end,
                desc = "crates: Update Crate",
            },
            {
                "<leader>kcC",
                function()
                    require("crates").upgrade_crate()
                end,
                desc = "crates: Upgrade Crate",
            },
            {
                "<leader>kcx",
                function()
                    require("crates").expand_plain_crate_to_inline_table()
                end,
                desc = "crates: Expand Crate to Inline Table",
            },
            {
                "<leader>kcp",
                function()
                    require("crates").show_popup()
                end,
                desc = "crates: Show Popup",
            },
            {
                "<leader>kcf",
                function()
                    require("crates").show_features_popup()
                end,
                desc = "crates: Show Features",
            },
            {
                "<leader>kcd",
                function()
                    require("crates").show_dependencies_popup()
                end,
                desc = "crates: Show Dependencies",
            },
            {
                "<leader>kct",
                function()
                    require("crates").toggle()
                end,
                desc = "crates: Toggle Feature",
            },
            {
                "<leader>kcr",
                function()
                    require("crates").reload()
                end,
                desc = "crates: Reload Crates",
            },
        },
        opts = {
            lsp = {
                enabled = true,
                actions = true,
                completion = true,
                hover = true,
            },
            completion = {
                crates = {
                    enabled = true,
                    max_results = 8,
                    min_chars = 3,
                },
                blink = {
                    use_custom_kind = true,
                },
            },
            popup = {
                border = "single",
            },
        },
    },
    {
        "mfussenegger/nvim-dap",
        ft = "rust",
        dependencies = { "nvim-neotest/nvim-nio" },
        opts = function()
            local ok, dap = pcall(require, "dap")
            if not ok then
                return
            end
            local function tauri_get_binary()
                ---@type string
                local cargo_toml = vim.fn.findfile("src-tauri/Cargo.toml", vim.fn.getcwd() .. ";")
                if cargo_toml == "" then
                    return nil
                end
                local ok_read, lines = pcall(vim.fn.readfile, cargo_toml)
                if not ok_read then
                    return nil
                end
                local name = nil
                local current_section = ""
                for _, line in ipairs(lines) do
                    local section = line:match("^%[+([^%]]+)%]")
                    if section then
                        current_section = section
                    end
                    if current_section == "package" then
                        local n = line:match('^name%s*=%s*"([^"]+)"')
                        if n then
                            name = n
                            break
                        end
                    end
                end
                if name then
                    local dir = vim.fn.fnamemodify(cargo_toml, ":h")
                    local standard = dir .. "/target/debug/" .. name
                    if vim.fn.executable(standard) == 1 then
                        return standard
                    end
                    local target_root = dir .. "/target"
                    local handle = vim.uv.fs_scandir(target_root)
                    if handle then
                        while true do
                            local entry, etype = vim.uv.fs_scandir_next(handle)
                            if not entry then
                                break
                            end
                            if
                                etype == "directory"
                                and entry ~= "debug"
                                and entry ~= "release"
                                and not entry:match("^%.")
                            then
                                local cross = target_root .. "/" .. entry .. "/debug/" .. name
                                if vim.fn.executable(cross) == 1 then
                                    return cross
                                end
                            end
                        end
                    end
                end
                return nil
            end
            local function cargo_get_binary()
                local cargo_toml = vim.fn.findfile("Cargo.toml", vim.fn.getcwd() .. ";")
                if cargo_toml == "" then
                    return nil
                end
                local ok_read, lines = pcall(vim.fn.readfile, cargo_toml)
                if not ok_read then
                    return nil
                end
                local name = nil
                local current_section = ""
                for _, line in ipairs(lines) do
                    local section = line:match("^%[+([^%]]+)%]")
                    if section then
                        current_section = section
                    end
                    if current_section == "package" then
                        local n = line:match('^name%s*=%s*"([^"]+)"')
                        if n then
                            name = n:gsub("-", "_")
                            break
                        end
                    end
                end
                if name then
                    local dir = vim.fn.fnamemodify(cargo_toml, ":h")
                    local candidates = {
                        dir .. "/target/debug/" .. name,
                        dir .. "/target/debug/" .. name:gsub("_", "-"),
                    }
                    for _, c in ipairs(candidates) do
                        if vim.fn.executable(c) == 1 then
                            return c
                        end
                    end
                    return dir .. "/target/debug/" .. name
                end
                return nil
            end

            dap.configurations.rust = dap.configurations.rust or {}
            -- Cegah duplikasi jika dipanggil berulang
            local has_tauri = false
            for _, cfg in ipairs(dap.configurations.rust) do
                if cfg.name == "Debug Tauri App" then
                    has_tauri = true
                    break
                end
            end

            if not has_tauri then
                table.insert(dap.configurations.rust, 1, {
                    name = "Debug Tauri App",
                    type = "codelldb",
                    request = "launch",
                    program = function()
                        if not dap.adapters["codelldb"] then
                            vim.notify(
                                "codelldb adapter belum dikonfigurasi.",
                                vim.log.levels.ERROR,
                                { title = "nvim-dap" }
                            )
                            return vim.fn.input(
                                "Path ke binary Tauri: ",
                                vim.fn.getcwd() .. "/src-tauri/target/debug/",
                                "file"
                            )
                        end
                        local binary = tauri_get_binary()
                        return binary
                            or vim.fn.input(
                                "Path ke binary Tauri: ",
                                vim.fn.getcwd() .. "/src-tauri/target/debug/",
                                "file"
                            )
                    end,
                    cwd = vim.fn.getcwd() .. "/src-tauri",
                    stopOnEntry = false,
                })
                table.insert(dap.configurations.rust, {
                    name = "Launch Rust (codelldb)",
                    type = "codelldb",
                    request = "launch",
                    program = function()
                        if not dap.adapters["codelldb"] then
                            vim.notify(
                                "codelldb adapter belum dikonfigurasi.",
                                vim.log.levels.ERROR,
                                { title = "nvim-dap" }
                            )
                            return vim.fn.input(
                                "Path ke binary Rust: ",
                                vim.fn.getcwd() .. "/target/debug/",
                                "file"
                            )
                        end
                        local binary = cargo_get_binary()
                        if binary and vim.fn.executable(binary) == 1 then
                            return binary
                        end
                        return vim.fn.input(
                            "Path ke binary Rust: ",
                            binary or vim.fn.getcwd() .. "/target/debug/",
                            "file"
                        )
                    end,
                    cwd = "${workspaceFolder}",
                    stopOnEntry = false,
                })
            end
        end,
    },
}
