return {
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}

            opts.servers.clangd = vim.tbl_deep_extend("force", opts.servers.clangd or {}, {
                mason = false,
                capabilities = {
                    offsetEncoding = { "utf-16" },
                },
                keys = {
                    {
                        "<leader>ch",
                        "<cmd>LspClangdSwitchSourceHeader<cr>",
                        "Switch Source/Header (C/C++)",
                    },
                },
                root_markers = {
                    ".clangd",
                    ".clang-tidy",
                    ".clang-format",
                    "compile_commands.json",
                    "compile_flags.txt",
                    "configure.ac",
                    "Makefile",
                    "configure.in",
                    "config.h.in",
                    "meson.build",
                    "meson_options.txt",
                    "build.ninja",
                    ".git",
                },
                cmd = {
                    "clangd",
                    "-j=2",
                    "--background-index",
                    "--background-index-priority=low",
                    "--clang-tidy",
                    "--header-insertion=iwyu",
                    "--completion-style=detailed",
                    "--function-arg-placeholders",
                    "--fallback-style=llvm",
                },
                init_options = {
                    usePlaceholders = true,
                    completeUnimported = true,
                    clangdFileStatus = true,
                },
            })
        end,
    },
    {
        "p00f/clangd_extensions.nvim",
        ft = { "c", "cpp", "objc", "objcpp" },
        opts = {
            ast = {
                role_icons = {
                    type = "",
                    declaration = "",
                    expression = "",
                    specifier = "",
                    statement = "",
                    ["template argument"] = "",
                },
                kind_icons = {
                    Compound = "",
                    Recovery = "",
                    TranslationUnit = "",
                    PackExpansion = "",
                    TemplateTypeParm = "",
                    TemplateTemplateParm = "",
                    TemplateParamObject = "",
                },
            },
        },
    },
    {
        "mfussenegger/nvim-dap",
        ft = { "c", "cpp" },
        dependencies = { "nvim-neotest/nvim-nio" },
        opts = function()
            local ok, dap = pcall(require, "dap")
            if not ok then
                return
            end
            dap.configurations.c = {
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
            dap.configurations.cpp = dap.configurations.c
        end,
    },
}
