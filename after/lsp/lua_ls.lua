local nvim_config = vim.fn.stdpath("config")

---@type vim.lsp.Config
return {
    root_dir = function(bufnr, on_dir)
        local fname = type(bufnr) == "number" and vim.api.nvim_buf_get_name(bufnr) or bufnr
        if not fname or fname == "" then
            on_dir(nil)
            return
        end
        local root = require("util.root").root_dir(fname, {
            ".luarc.json",
            ".luarc.jsonc",
            ".stylua.toml",
            "stylua.toml",
            "selene.toml",
            ".git",
            "init.lua",
        })
        if not root and vim.uv.fs_stat(nvim_config) and fname:find(nvim_config, 1, true) == 1 then
            root = nvim_config
        end
        on_dir(root)
    end,
    settings = {
        Lua = {
            locale = "en-us",
            workspace = { checkThirdParty = false },
            completion = { callSnippet = "Replace" },
            doc = { privateName = { "^_" } },
        },
    },
}
