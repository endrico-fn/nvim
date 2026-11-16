return {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
        opts.servers = opts.servers or {}

        local nvim_config = vim.fn.stdpath("config")
        opts.servers.lua_ls = vim.tbl_deep_extend("force", opts.servers.lua_ls or {}, {
            root_markers = { ".luarc.json", ".luarc.jsonc", ".git", "stylua.toml", "init.lua" },
            on_new_config = function(new_config, new_root)
                if not new_root and vim.uv.fs_stat(nvim_config) then
                    new_config.root_dir = nvim_config
                end
            end,
            settings = {
                Lua = {
                    locale = "en-us",
                    workspace = {
                        checkThirdParty = false,
                    },
                    completion = {
                        callSnippet = "Replace",
                    },
                    doc = { privateName = { "^_" } },
                },
            },
        })
    end,
}
