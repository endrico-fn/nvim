local function get_args(config)
    local default_args = type(config.args) == "table" and table.concat(config.args, " ") or ""
    config = vim.deepcopy(config)
    local cached_args = nil
    config.args = function()
        if not cached_args then
            cached_args = vim.fn.expand(vim.fn.input("Run with args: ", default_args))
        end
        return require("dap.utils").splitstr(cached_args)
    end
    return config
end

local function setup_language_daps(dap)
    -- JS/TS adapters (pwa-node, chrome, msedge)
    local js_filetypes = {
        "typescript",
        "javascript",
        "typescriptreact",
        "javascriptreact",
        "svelte",
        "vue",
    }
    if not dap.adapters["pwa-node"] then
        dap.adapters["pwa-node"] = {
            type = "server",
            host = "localhost",
            port = "${port}",
            executable = { command = "js-debug-adapter", args = { "${port}" } },
        }
    end
    dap.adapters["node"] = dap.adapters["pwa-node"]
    dap.adapters["node-terminal"] = dap.adapters["pwa-node"]

    for _, adapter_type in ipairs({ "chrome", "msedge" }) do
        local pwa_type = "pwa-" .. adapter_type
        if not dap.adapters[pwa_type] then
            dap.adapters[pwa_type] = {
                type = "server",
                host = "localhost",
                port = "${port}",
                executable = { command = "js-debug-adapter", args = { "${port}" } },
            }
        end
        if not dap.adapters[adapter_type] then
            dap.adapters[adapter_type] = function(cb, config)
                config.type = pwa_type
                local native = dap.adapters[pwa_type]
                if type(native) == "function" then
                    native(cb, config)
                else
                    cb(native)
                end
            end
        end
    end

    local ok_vscode, vscode = pcall(require, "dap.ext.vscode")
    if ok_vscode then
        vscode.type_to_filetypes["node"] = js_filetypes
        vscode.type_to_filetypes["pwa-node"] = js_filetypes
    end

    local ts_runtime = function()
        return vim.fn.executable("tsx") == 1 and "tsx" or "ts-node"
    end
    for _, language in ipairs(js_filetypes) do
        if not dap.configurations[language] then
            local is_ts = language:find("typescript") ~= nil
            dap.configurations[language] = {
                {
                    type = "pwa-node",
                    request = "launch",
                    name = "Launch file",
                    program = "${file}",
                    cwd = "${workspaceFolder}",
                    sourceMaps = true,
                    runtimeExecutable = is_ts and ts_runtime or nil,
                    skipFiles = { "<node_internals>/**", "node_modules/**" },
                    resolveSourceMapLocations = { "${workspaceFolder}/**", "!**/node_modules/**" },
                },
                {
                    type = "pwa-node",
                    request = "attach",
                    name = "Attach",
                    processId = require("dap.utils").pick_process,
                    cwd = "${workspaceFolder}",
                    sourceMaps = true,
                    runtimeExecutable = is_ts and ts_runtime or nil,
                    skipFiles = { "<node_internals>/**", "node_modules/**" },
                    resolveSourceMapLocations = { "${workspaceFolder}/**", "!**/node_modules/**" },
                },
            }
        end
    end

    -- C / C++
    dap.configurations.c = dap.configurations.c
        or {
            {
                type = "codelldb",
                request = "launch",
                name = "Launch file",
                program = function()
                    return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
                end,
                cwd = "${workspaceFolder}",
            },
            {
                type = "codelldb",
                request = "attach",
                name = "Attach to process",
                pid = require("dap.utils").pick_process,
                cwd = "${workspaceFolder}",
            },
        }
    dap.configurations.cpp = dap.configurations.cpp or dap.configurations.c

    -- Zig
    dap.configurations.zig = dap.configurations.zig
        or {
            {
                name = "Launch Zig",
                type = "codelldb",
                request = "launch",
                program = function()
                    return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
                end,
                cwd = "${workspaceFolder}",
                stopOnEntry = false,
                args = {},
            },
        }

    -- Rust / Tauri
    local function read_cargo_pkg_name(cargo_toml)
        local ok_read, lines = pcall(vim.fn.readfile, cargo_toml)
        if not ok_read then
            return nil
        end
        local current_section = ""
        for _, line in ipairs(lines) do
            local section = line:match("^%[+([^%]]+)%]")
            if section then
                current_section = section
            end
            if current_section == "package" then
                local n = line:match('^name%s*=%s*"([^"]+)"')
                if n then
                    return n
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
        local raw_name = read_cargo_pkg_name(cargo_toml)
        if not raw_name then
            return nil
        end
        local name = raw_name:gsub("-", "_")
        local dir = vim.fn.fnamemodify(cargo_toml, ":h")
        for _, c in ipairs({
            dir .. "/target/debug/" .. name,
            dir .. "/target/debug/" .. raw_name,
        }) do
            if vim.fn.executable(c) == 1 then
                return c
            end
        end
        return dir .. "/target/debug/" .. name
    end

    local function tauri_get_binary()
        local cargo_toml = vim.fn.findfile("src-tauri/Cargo.toml", vim.fn.getcwd() .. ";")
        if cargo_toml == "" then
            return nil
        end
        local name = read_cargo_pkg_name(cargo_toml)
        if not name then
            return nil
        end
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
        return nil
    end

    dap.configurations.rust = dap.configurations.rust
        or {
            {
                name = "Debug Tauri App",
                type = "codelldb",
                request = "launch",
                program = function()
                    return tauri_get_binary()
                        or vim.fn.input(
                            "Path ke binary Tauri: ",
                            vim.fn.getcwd() .. "/src-tauri/target/debug/",
                            "file"
                        )
                end,
                cwd = vim.fn.getcwd() .. "/src-tauri",
                stopOnEntry = false,
            },
            {
                name = "Launch Rust (codelldb)",
                type = "codelldb",
                request = "launch",
                program = function()
                    local binary = cargo_get_binary()
                    if binary and vim.fn.executable(binary) == 1 then
                        return binary
                    end
                    return vim.fn.input(
                        "Path ke binary Rust: ",
                        binary or (vim.fn.getcwd() .. "/target/debug/"),
                        "file"
                    )
                end,
                cwd = "${workspaceFolder}",
                stopOnEntry = false,
            },
        }
end

return {
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            "nvim-lua/plenary.nvim",
            {
                "rcarriga/nvim-dap-ui",
                opts = {
                    icons = { expanded = " ", collapsed = " ", current_frame = " " },
                    controls = { enabled = false },
                    floating = {
                        border = "single",
                        mappings = { close = { "q", "<Esc>" } },
                    },
                    layouts = {
                        {
                            elements = {
                                { id = "scopes", size = 0.35 },
                                { id = "breakpoints", size = 0.20 },
                                { id = "stacks", size = 0.25 },
                                { id = "watches", size = 0.20 },
                            },
                            size = 40,
                            position = "left",
                        },
                        {
                            elements = {
                                { id = "repl", size = 0.5 },
                                { id = "console", size = 0.5 },
                            },
                            size = 12,
                            position = "bottom",
                        },
                    },
                },
            },
            "nvim-neotest/nvim-nio",
            { "theHamsta/nvim-dap-virtual-text", opts = {} },
            {
                "jay-babu/mason-nvim-dap.nvim",
                dependencies = "mason.nvim",
                opts = {
                    automatic_installation = true,
                    handlers = {
                        function(config)
                            require("mason-nvim-dap").default_setup(config)
                        end,
                        python = function() end,
                    },
                    ensure_installed = {},
                },
            },
            "jbyuki/one-small-step-for-vimkind",
        },
        keys = {
            {
                "<F5>",
                function()
                    require("dap").continue()
                end,
                desc = "Debug: Start/Continue",
            },
            {
                "<F10>",
                function()
                    require("dap").step_over()
                end,
                desc = "Debug: Step Over",
            },
            {
                "<F11>",
                function()
                    require("dap").step_into()
                end,
                desc = "Debug: Step Into",
            },
            {
                "<F12>",
                function()
                    require("dap").step_out()
                end,
                desc = "Debug: Step Out",
            },
            {
                "<leader>db",
                function()
                    require("dap").toggle_breakpoint()
                end,
                desc = "Toggle Breakpoint",
            },
            {
                "<leader>dc",
                function()
                    require("dap").continue()
                end,
                desc = "Continue",
            },
            {
                "<leader>di",
                function()
                    require("dap").step_into()
                end,
                desc = "Step Into",
            },
            {
                "<leader>do",
                function()
                    require("dap").step_out()
                end,
                desc = "Step Out",
            },
            {
                "<leader>dO",
                function()
                    require("dap").step_over()
                end,
                desc = "Step Over",
            },
            {
                "<leader>dt",
                function()
                    require("dap").terminate()
                end,
                desc = "Terminate",
            },
            {
                "<leader>du",
                function()
                    require("dapui").toggle()
                end,
                desc = "DAP UI",
            },
            {
                "<leader>de",
                function()
                    require("dapui").eval()
                end,
                mode = { "n", "x" },
                desc = "Eval",
            },
            {
                "<leader>dB",
                function()
                    require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
                end,
                desc = "Conditional Breakpoint",
            },
            {
                "<leader>dl",
                function()
                    require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
                end,
                desc = "Log Point",
            },
            {
                "<leader>dr",
                function()
                    require("dap").restart()
                end,
                desc = "Restart",
            },
            {
                "<leader>da",
                function()
                    require("dap").continue({ before = get_args })
                end,
                desc = "Run with Args",
            },
            {
                "<leader>dC",
                function()
                    require("dap").run_to_cursor()
                end,
                desc = "Run to Cursor",
            },
            {
                "<leader>dg",
                function()
                    require("dap").goto_()
                end,
                desc = "Go to Line (No Execute)",
            },
            {
                "<leader>dj",
                function()
                    require("dap").down()
                end,
                desc = "Stack Down",
            },
            {
                "<leader>dk",
                function()
                    require("dap").up()
                end,
                desc = "Stack Up",
            },
            {
                "<leader>dL",
                function()
                    require("dap").run_last()
                end,
                desc = "Run Last",
            },
            {
                "<leader>dp",
                function()
                    require("dap").pause()
                end,
                desc = "Pause",
            },
            {
                "<leader>dR",
                function()
                    require("dap").repl.toggle()
                end,
                desc = "Toggle REPL",
            },
            {
                "<leader>ds",
                function()
                    require("dap").session()
                end,
                desc = "Session",
            },
            {
                "<leader>dw",
                function()
                    require("dap.ui.widgets").hover()
                end,
                desc = "Widgets",
            },
        },
        config = function()
            local dap = require("dap")
            local dapui = require("dapui")

            local vscode = require("dap.ext.vscode")
            ---@diagnostic disable-next-line: duplicate-set-field
            vscode.json_decode = function(str)
                return vim.json.decode(str, { skip_comments = true })
            end

            vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

            local icons = {
                Stopped = { "󰁕 ", "DiagnosticWarn", "DapStoppedLine" },
                Breakpoint = { " ", "DiagnosticError" },
                BreakpointCondition = { " ", "DiagnosticError" },
                BreakpointRejected = { " ", "DiagnosticError" },
                LogPoint = { ". ", "DiagnosticInfo" },
            }
            for name, sign in pairs(icons) do
                vim.fn.sign_define("Dap" .. name, {
                    text = sign[1],
                    texthl = sign[2],
                    linehl = sign[3],
                    numhl = sign[3],
                })
            end

            do
                local codelldb = vim.fn.exepath("codelldb")
                if codelldb == "" then
                    local mason_codelldb =
                        vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin", "codelldb")
                    if vim.uv.fs_stat(mason_codelldb) then
                        codelldb = mason_codelldb
                    end
                end
                if codelldb ~= "" and not dap.adapters.codelldb then
                    dap.adapters.codelldb = {
                        type = "server",
                        port = "${port}",
                        executable = { command = codelldb, args = { "--port", "${port}" } },
                    }
                end
            end

            dap.adapters.nlua = function(callback, conf)
                local adapter = {
                    type = "server",
                    host = conf.host or "127.0.0.1",
                    port = conf.port or 8086,
                }
                if conf.start_neovim then
                    local dap_run = dap.run
                    local osv_started = false
                    ---@diagnostic disable-next-line: duplicate-set-field
                    dap.run = function(c)
                        if osv_started then
                            return
                        end
                        osv_started = true
                        adapter.port = c.port
                        adapter.host = c.host
                    end
                    require("osv").run_this()
                    dap.run = dap_run
                end
                callback(adapter)
            end
            dap.configurations.lua = {
                {
                    type = "nlua",
                    request = "attach",
                    name = "Run this file",
                    start_neovim = {},
                },
                {
                    type = "nlua",
                    request = "attach",
                    name = "Attach to running Neovim instance (port = 8086)",
                    port = 8086,
                },
            }

            setup_language_daps(dap)

            local dap_ended = false
            dap.listeners.after.event_initialized["dapui_config"] = function()
                dap_ended = false
                dapui.open()
            end
            dap.listeners.before.event_terminated["dapui_config"] = function()
                if not dap_ended then
                    dap_ended = true
                    dapui.close()
                end
            end
            dap.listeners.before.event_exited["dapui_config"] = function()
                if not dap_ended then
                    dap_ended = true
                    dapui.close()
                end
            end
        end,
    },

    {
        "mfussenegger/nvim-dap-python",
        ft = "python",
        dependencies = {
            "mfussenegger/nvim-dap",
            "nvim-neotest/nvim-nio",
        },
        config = function()
            local ok, dap_python = pcall(require, "dap-python")
            if not ok then
                return
            end
            local mason_debugpy = vim.fs.joinpath(
                vim.fn.stdpath("data"),
                "mason",
                "packages",
                "debugpy",
                "venv",
                "bin",
                "python"
            )
            local sys_py = vim.fn.exepath("python3")
            local adapter_bin = (vim.uv.fs_stat(mason_debugpy) and mason_debugpy)
                or (sys_py ~= "" and sys_py or "python3")

            dap_python.setup(adapter_bin)
            dap_python.test_runner = "pytest"
            dap_python.resolve_python = function()
                return require("util.python").get_python_path()
            end
        end,
    },

    {
        "leoluz/nvim-dap-go",
        ft = "go",
        dependencies = {
            "mfussenegger/nvim-dap",
            "nvim-neotest/nvim-nio",
        },
        opts = {
            delve = { initialize_timeout_sec = 30 },
        },
    },

    {
        "nvim-neotest/neotest",
        dependencies = {
            "nvim-neotest/nvim-nio",
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
            "marilari88/neotest-vitest",
            "nvim-neotest/neotest-python",
            "fredrikaverpil/neotest-golang",
            "lawrence-laz/neotest-zig",
            "nvim-neotest/neotest-plenary",
        },
        keys = {
            {
                "<leader>tr",
                function()
                    require("neotest").run.run()
                end,
                desc = "Run Nearest",
            },
            {
                "<leader>tf",
                function()
                    require("neotest").run.run(vim.fn.expand("%"))
                end,
                desc = "Run File",
            },
            {
                "<leader>ts",
                function()
                    require("neotest").summary.toggle()
                end,
                desc = "Toggle Summary",
            },
            {
                "<leader>dn",
                function()
                    require("neotest").run.run({ strategy = "dap", suite = false })
                end,
                desc = "Debug Nearest Test",
            },
            {
                "<leader>tS",
                function()
                    require("neotest").run.stop()
                end,
                desc = "Stop",
            },
            {
                "<leader>tT",
                function()
                    require("neotest").run.run({ suite = true })
                end,
                desc = "Run All Tests",
            },
            {
                "<leader>to",
                function()
                    require("neotest").output.open({ enter = true, auto_close = true })
                end,
                desc = "Show Output",
            },
            {
                "<leader>ta",
                function()
                    require("neotest").run.attach()
                end,
                desc = "Attach",
            },
            {
                "<leader>tl",
                function()
                    require("neotest").run.run_last()
                end,
                desc = "Run Last",
            },
            {
                "<leader>tO",
                function()
                    require("neotest").output_panel.toggle()
                end,
                desc = "Output Panel",
            },
            {
                "<leader>tw",
                function()
                    require("neotest").watch.toggle(vim.fn.expand("%"))
                end,
                desc = "Toggle Watch",
            },
        },
        opts = {
            consumers = {},
            adapters = {
                ["neotest-vitest"] = {},
                ["rustaceanvim.neotest"] = {},
                ["neotest-zig"] = {},
                ["neotest-python"] = {
                    runner = "pytest",
                    dap = { justMyCode = false },
                    python = function()
                        return require("util.python").get_python_path()
                    end,
                },
                ["neotest-golang"] = {
                    go_test_args = { "-p=1", "-count=1" },
                    testify_enabled = false,
                    runner = "gotestsum",
                },
                ["neotest-plenary"] = {},
            },
            status = { virtual_text = true },
            output = { open_on_run = true },
            quickfix = {
                open = function()
                    if require("lazy.core.config").plugins["trouble.nvim"] ~= nil then
                        require("trouble").open({ mode = "quickfix", focus = false })
                    else
                        vim.cmd("copen")
                    end
                end,
            },
        },
        config = function(_, opts)
            local neotest_ns = vim.api.nvim_create_namespace("neotest")
            vim.diagnostic.config({
                virtual_text = {
                    format = function(diagnostic)
                        return diagnostic.message
                            :gsub("\n", " ")
                            :gsub("\t", " ")
                            :gsub("%s+", " ")
                            :gsub("^%s+", "")
                    end,
                },
            }, neotest_ns)

            opts.consumers.overseer = require("neotest.consumers.overseer")

            if require("lazy.core.config").plugins["trouble.nvim"] ~= nil then
                opts.consumers.trouble = function(client)
                    client.listeners.results = function(adapter_id, results, partial)
                        if partial then
                            return
                        end
                        local tree = assert(client:get_position(nil, { adapter = adapter_id }))
                        local failed = 0
                        for pos_id, result in pairs(results) do
                            if result.status == "failed" and tree:get_key(pos_id) then
                                failed = failed + 1
                            end
                        end
                        vim.schedule(function()
                            local trouble = require("trouble")
                            if trouble.is_open() then
                                trouble.refresh()
                                if failed == 0 then
                                    trouble.close()
                                end
                            end
                        end)
                        return {}
                    end
                end
            end

            if opts.adapters then
                local adapters = {}
                for name, config in pairs(opts.adapters) do
                    if type(name) == "number" then
                        if type(config) == "string" then
                            config = require(config)
                        end
                        table.insert(adapters, config)
                    else
                        local adapter = require(name)
                        if type(adapter) == "table" and type(adapter.setup) == "function" then
                            adapter.setup(config)
                            table.insert(adapters, adapter)
                        elseif type(adapter) == "function" then
                            table.insert(adapters, adapter(config))
                        else
                            table.insert(adapters, adapter)
                        end
                    end
                end
                opts.adapters = adapters
            end

            require("neotest").setup(opts)
        end,
    },

    {
        "stevearc/overseer.nvim",
        cmd = {
            "OverseerRun",
            "OverseerToggle",
            "OverseerTaskAction",
            "OverseerBuild",
            "OverseerClearCache",
        },
        keys = {
            { "<leader>or", "<cmd>OverseerRun<cr>", desc = "Run Task" },
            { "<leader>ot", "<cmd>OverseerToggle<cr>", desc = "Task List" },
            { "<leader>oa", "<cmd>OverseerTaskAction<cr>", desc = "Task Action" },
            { "<leader>ob", "<cmd>OverseerBuild<cr>", desc = "Build Project" },
            { "<leader>oc", "<cmd>OverseerClearCache<cr>", desc = "Clear Task Cache" },
        },
        opts = {
            task_list = {
                max_history = 10,
                default_detail = 1,
                direction = "bottom",
                height = 12,
                border = "single",
                keymaps = {
                    ["<C-j>"] = false,
                    ["<C-k>"] = false,
                },
            },
            form = {
                win_opts = { border = "single" },
            },
        },
    },
}
