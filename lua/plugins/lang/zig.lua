return {
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}
            opts.servers.zls = vim.tbl_deep_extend("force", opts.servers.zls or {}, {
                init_options = {
                    enable_inlay_hints = true,
                    enable_snippets = true,
                    semantic_tokens = true,
                    warn_style = true,
                    highlight_builtins = true,
                    build_runner = "check",
                },
                keys = {
                    {
                        "<leader>kz",
                        function()
                            vim.cmd("terminal zig build")
                        end,
                        desc = "Zig: Build",
                    },
                },
            })
        end,
    },
    {
        "mfussenegger/nvim-dap",
        ft = "zig",
        dependencies = { "nvim-neotest/nvim-nio" },
        opts = function()
            local ok, dap = pcall(require, "dap")
            if not ok then
                return
            end
            dap.configurations.zig = dap.configurations.zig or {}
            if #dap.configurations.zig == 0 then
                dap.configurations.zig[1] = {
                    name = "Launch Zig",
                    type = "codelldb",
                    request = "launch",
                    program = function()
                        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
                    end,
                    cwd = "${workspaceFolder}",
                    stopOnEntry = false,
                    args = {},
                }
            end
        end,
    },
}
