return {
    "neovim/nvim-lspconfig",
    init = function()
        local function toggle_typos(state)
            if state and not vim.lsp.config.typos_lsp then
                require("lazy").load({ plugins = { "nvim-lspconfig" } })
            end
            vim.lsp.enable("typos_lsp", state)
        end

        if _G.Snacks and Snacks.toggle then
            Snacks.toggle({
                name = "Typos (Spell LSP)",
                get = function()
                    return vim.lsp.is_enabled("typos_lsp")
                end,
                set = toggle_typos,
            }):map("<leader>ut")
        else
            vim.keymap.set("n", "<leader>ut", function()
                local next_state = not vim.lsp.is_enabled("typos_lsp")
                toggle_typos(next_state)
                vim.notify(
                    "Typos LSP: " .. (next_state and "ON" or "OFF"),
                    next_state and vim.log.levels.INFO or vim.log.levels.WARN,
                    { title = "UI" }
                )
            end, { desc = "Toggle Typos (Spell LSP)" })
        end
    end,
    opts = function(_, opts)
        opts.servers = opts.servers or {}
        -- typos-lsp: spell checker real-time untuk semua file.
        -- Default nonaktif (autostart = false) agar tidak bising di kata bahasa Indonesia;
        -- aktifkan on-demand via toggle <leader>ut.
        -- Config file discovery: auto-detect .typos.toml up the dir tree;
        -- fallback ke global config di nvim config dir.
        opts.servers.typos_lsp = vim.tbl_deep_extend("force", opts.servers.typos_lsp or {}, {
            autostart = false,
            init_options = {
                -- "Hint" agar tidak terlalu mencolok di antara error/warning LSP lain
                diagnosticSeverity = "Hint",
            },
            on_new_config = function(new_config, new_root)
                -- Jika project tidak punya typos config sendiri,
                -- gunakan global config dari nvim dir
                local project_cfg = vim.fs.find(
                    { ".typos.toml", "typos.toml", "_typos.toml" },
                    { path = new_root, upward = false }
                )[1]
                if not project_cfg then
                    new_config.init_options = vim.tbl_deep_extend(
                        "force",
                        new_config.init_options or {},
                        { config = vim.fn.expand("~/.config/nvim/.typos.toml") }
                    )
                end
            end,
        })
    end,
}
