local function is_sqlite_file(path)
    local ok, handle = pcall(vim.uv.fs_open, path, "r", 438)
    if not ok or not handle then
        return false
    end
    local header = vim.uv.fs_read(handle, 16, 0)
    vim.uv.fs_close(handle)
    return header and header:find("^SQLite format 3") ~= nil
end

local function open_sqlite(dbpath)
    if vim.fn.executable("sqlite3") ~= 1 then
        vim.notify("sqlite3 CLI tidak ditemukan.", vim.log.levels.ERROR)
        return
    end
    dbpath = dbpath or vim.api.nvim_buf_get_name(0)
    if dbpath == "" then
        vim.notify("Tidak ada file database yang terbuka.", vim.log.levels.WARN)
        return
    end
    dbpath = vim.fn.fnamemodify(dbpath, ":p")
    if not is_sqlite_file(dbpath) then
        vim.notify("File bukan SQLite database.", vim.log.levels.WARN)
        return
    end
    if vim.fn.exists(":DBUIToggle") == 2 then
        vim.cmd("DBUI")
        vim.defer_fn(function()
            vim.b.dadbod_connection = "sqlite://" .. dbpath
            vim.notify(
                "SQLite: " .. vim.fn.fnamemodify(dbpath, ":t") .. " — siap",
                vim.log.levels.INFO
            )
        end, 200)
    else
        vim.notify("Gunakan :DB sqlite://" .. dbpath, vim.log.levels.INFO)
    end
end

local function setup_sqlite_tools()
    vim.filetype.add({
        extension = {
            db = "sqlite",
            sqlite = "sqlite",
            sqlite3 = "sqlite",
            sqlitedb = "sqlite",
        },
        filename = {
            ["database.sqlite"] = "sqlite",
            ["data.db"] = "sqlite",
        },
    })

    vim.api.nvim_create_autocmd("BufReadPost", {
        group = vim.api.nvim_create_augroup("sqlite_detect", { clear = true }),
        pattern = { "*.db", "*.sqlite", "*.sqlite3", "*.sqlitedb" },
        callback = function(args)
            local buf = args.buf
            local path = vim.api.nvim_buf_get_name(buf)
            if not is_sqlite_file(path) then
                return
            end
            vim.bo[buf].filetype = "sql"
            vim.b[buf].disable_autoformat = true
            vim.b[buf].sqlite_path = path
            vim.defer_fn(function()
                for _, client in ipairs(vim.lsp.get_clients({ name = "sqls", bufnr = buf })) do
                    client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
                        sqls = {
                            connections = {
                                {
                                    alias = vim.fn.fnamemodify(path, ":t"),
                                    driver = "sqlite3",
                                    dataSourceName = path,
                                },
                            },
                        },
                    })
                    client:notify(
                        "workspace/didChangeConfiguration",
                        { settings = client.settings }
                    )
                end
            end, 150)
            vim.defer_fn(function()
                local name = vim.fn.fnamemodify(path, ":t")
                vim.notify(
                    name
                        .. " — SQLite database.\n:SQLiteOpen   browse di dadbod-ui\n:SQLiteExec   query cepat",
                    vim.log.levels.INFO,
                    { title = "SQLite", timeout = 5000 }
                )
            end, 100)
        end,
    })

    vim.api.nvim_create_user_command("SQLiteOpen", function(args)
        if args.args and args.args ~= "" then
            open_sqlite(args.args)
        elseif is_sqlite_file(vim.api.nvim_buf_get_name(0)) then
            open_sqlite()
        else
            local p = vim.fn.input("SQLite database: ", vim.fn.getcwd() .. "/", "file")
            if p ~= "" then
                open_sqlite(p)
            end
        end
    end, { nargs = "?", complete = "file", desc = "Open SQLite database in dadbod-ui" })

    vim.api.nvim_create_user_command("SQLiteExec", function(args)
        if args.args == "" then
            vim.notify("Usage: SQLiteExec <query>", vim.log.levels.ERROR)
            return
        end
        local dbpath = vim.api.nvim_buf_get_name(0)
        if not is_sqlite_file(dbpath) then
            vim.notify("Buffer ini bukan SQLite database.", vim.log.levels.WARN)
            return
        end
        local result = vim.fn.system({ "sqlite3", "-header", "-column", dbpath, args.args })
        if vim.v.shell_error ~= 0 then
            vim.notify("SQLite error: " .. result, vim.log.levels.ERROR)
            return
        end
        vim.cmd("new")
        vim.api.nvim_buf_set_name(0, "sqlite://output")
        vim.bo.buftype = "nofile"
        vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(result, "\n", { plain = true }))
        vim.bo.filetype = "sql"
        vim.bo.modified = false
    end, { nargs = 1, complete = "command", desc = "Execute SQL on current SQLite database" })
end

return {
    {
        "obsidian-nvim/obsidian.nvim",
        version = "*",
        lazy = true,
        ft = "markdown",
        cmd = "Obsidian",
        cond = function()
            return vim.fn.isdirectory(vim.fn.expand("~/Obsidian/enrico")) == 1
        end,
        keys = {
            { "<leader>On", "<cmd>Obsidian quick_switch<cr>", desc = "Obsidian: Quick Switch" },
            { "<leader>Os", "<cmd>Obsidian search<cr>", desc = "Obsidian: Search Vault" },
            { "<leader>ON", "<cmd>Obsidian new<cr>", desc = "Obsidian: New Note" },
            { "<leader>Ot", "<cmd>Obsidian today<cr>", desc = "Obsidian: Today's Note" },
            { "<leader>Oy", "<cmd>Obsidian yesterday<cr>", desc = "Obsidian: Yesterday's Note" },
            { "<leader>Ob", "<cmd>Obsidian backlinks<cr>", desc = "Obsidian: Backlinks" },
            { "<leader>OT", "<cmd>Obsidian toc<cr>", desc = "Obsidian: Table of Contents" },
            { "<leader>Op", "<cmd>Obsidian paste_img<cr>", desc = "Obsidian: Paste Image" },
            { "<leader>Oo", "<cmd>Obsidian open<cr>", desc = "Obsidian: Open in App" },
            { "<leader>Ow", "<cmd>Obsidian workspace<cr>", desc = "Obsidian: Switch Workspace" },
        },
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {
            legacy_commands = false,
            workspaces = {
                { name = "enrico", path = "~/Obsidian/enrico" },
            },
            new_notes_location = "current_dir",
            link = { style = "wiki", format = "shortest", auto_update = true },
            note_id_func = function(...)
                return require("obsidian.builtin").title_id(...)
            end,
            note_path_func = function(spec)
                local path = spec.dir / tostring(spec.id)
                return path:with_suffix(".md", true)
            end,
            note = { template = nil },
            templates = {
                enabled = true,
                folder = "_meta/_templates",
                date_format = "YYYY-MM-DD",
                time_format = "HH:mm",
                substitutions = {
                    date = function(_, suffix)
                        return require("obsidian.util").format_date(
                            os.time(),
                            suffix or "YYYY-MM-DD"
                        )
                    end,
                    time = function(_, suffix)
                        return require("obsidian.util").format_date(os.time(), suffix or "HH:mm")
                    end,
                    title = function(ctx)
                        return ctx.partial_note and ctx.partial_note:display_name()
                    end,
                    id = function(ctx)
                        return ctx.partial_note and ctx.partial_note.id
                    end,
                    path = function(ctx)
                        return ctx.partial_note and tostring(ctx.partial_note.path)
                    end,
                },
            },
            daily_notes = {
                enabled = true,
                folder = "00-inbox",
                date_format = "YYYY-MM-DD",
                alias_format = nil,
                default_tags = { "daily-notes" },
                workdays_only = false,
                template = nil,
            },
            frontmatter = {
                enabled = true,
                func = function(...)
                    return require("obsidian.builtin").frontmatter(...)
                end,
                sort = { "id", "aliases", "tags", "created", "modified" },
            },
            attachments = {
                folder = "_attachments",
                confirm_img_paste = true,
                img_name_func = function()
                    return string.format("Pasted image %s", os.date("%Y%m%d%H%M%S"))
                end,
                img_text_func = function(path)
                    local name = vim.fs.basename(tostring(path))
                    local encoded_name = require("obsidian.util").urlencode(name)
                    return string.format("![%s](%s)", name, encoded_name)
                end,
            },
            completion = { min_chars = 2, match_case = true, create_new = true },
            picker = {
                name = "snacks.picker",
                note_mappings = { new = "<C-x>", insert_link = "<C-l>" },
                tag_mappings = { tag_note = "<C-x>", insert_tag = "<C-l>" },
            },
            search = { sort_by = "modified", sort_reversed = true, max_lines = 1000 },
            ui = { enable = false },
            footer = {
                enabled = true,
                format = "󰈙 {{backlinks}} bl  󰛿 {{properties}} props  󰓬 {{words}} words  󰧟 {{chars}} chars",
                hl_group = "Comment",
                separator = string.rep("─", 80),
            },
            checkbox = {
                enabled = true,
                create_new = true,
                order = { " ", "~", "!", ">", "x" },
            },
            backlinks = { parse_headers = true },
            open = {
                use_advanced_uri = false,
                func = vim.ui.open,
                schemes = { "https", "http", "file", "mailto", "obsidian" },
            },
            callbacks = {},
            open_notes_in = "current",
            log_level = vim.log.levels.INFO,
            slides = { enabled = true },
            comment = { enabled = false },
            unique_note = {
                enabled = true,
                format = "YYYYMMDDHHmmss",
                folder = "00-inbox",
                template = nil,
            },
            file = {
                ignore_filters = {
                    ".obsidian/*",
                    ".git/*",
                    "node_modules/*",
                    "__pycache__/*",
                },
            },
        },
        config = function(_, opts)
            require("obsidian").setup(opts)

            local vault_path = opts.workspaces[1].path:gsub("~", vim.fn.expand("~"))

            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("obsidian-disable-marksman", { clear = true }),
                desc = "Detach marksman LSP for Obsidian vault files",
                callback = function(args)
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if client and client.name == "marksman" then
                        local path = vim.api.nvim_buf_get_name(args.buf)
                        if path:find(vault_path, 1, true) then
                            vim.lsp.buf_detach_client(args.buf, client.id)
                        end
                    end
                end,
            })

            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup("obsidian-keymaps", { clear = true }),
                pattern = "markdown",
                desc = "Set Obsidian buffer-local keymaps",
                callback = function(args)
                    local path = vim.api.nvim_buf_get_name(args.buf)
                    if not path:find(vault_path, 1, true) then
                        return
                    end

                    local function omap(lhs, action, desc)
                        vim.keymap.set("n", lhs, function()
                            return require("obsidian").actions[action]()
                        end, {
                            buf = args.buf,
                            silent = true,
                            noremap = true,
                            desc = desc,
                        })
                    end

                    omap("<CR>", "smart_action", "Obsidian: Smart Action")
                    omap("gl", "follow_link", "Obsidian: Follow Link")
                    vim.keymap.set("n", "]o", function()
                        return require("obsidian").actions.nav_link(true)
                    end, {
                        buf = args.buf,
                        silent = true,
                        noremap = true,
                        desc = "Obsidian: Next Link",
                    })
                    vim.keymap.set("n", "[o", function()
                        return require("obsidian").actions.nav_link(false)
                    end, {
                        buf = args.buf,
                        silent = true,
                        noremap = true,
                        desc = "Obsidian: Prev Link",
                    })
                    omap("<leader>Oc", "toggle_checkbox", "Obsidian: Toggle Checkbox")
                end,
            })
        end,
    },

    {
        "MeanderingProgrammer/render-markdown.nvim",
        ft = { "markdown", "markdown.mdx" },
        keys = {
            {
                "<leader>uM",
                function()
                    require("render-markdown").toggle()
                end,
                desc = "Toggle Markdown Render",
                ft = { "markdown", "markdown.mdx" },
            },
        },
        opts = {
            nested = false,
            code = { sign = false, width = "block", right_pad = 1 },
            heading = { sign = false, icons = {} },
            checkbox = { enabled = true },
        },
    },

    {
        "tpope/vim-dadbod",
        cmd = "DB",
        init = setup_sqlite_tools,
        keys = {
            {
                "<leader>Do",
                function()
                    local p = vim.fn.input("SQLite database: ", vim.fn.getcwd() .. "/", "file")
                    if p ~= "" then
                        open_sqlite(p)
                    end
                end,
                desc = "SQLite: Open Database",
            },
            {
                "<leader>Dc",
                function()
                    if is_sqlite_file(vim.api.nvim_buf_get_name(0)) then
                        open_sqlite()
                    else
                        vim.notify("Bukan SQLite database.", vim.log.levels.WARN)
                    end
                end,
                desc = "SQLite: Open Current Buffer",
            },
        },
    },

    {
        "kristijanhusak/vim-dadbod-ui",
        cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
        dependencies = { "tpope/vim-dadbod" },
        keys = {
            { "<leader>Du", "<cmd>DBUIToggle<cr>", desc = "Toggle Database UI" },
        },
        init = function()
            local data_path = vim.fn.stdpath("data")
            vim.g.db_ui_auto_execute_table_helpers = 1
            vim.g.db_ui_save_location = data_path .. "/dadbod_ui"
            vim.g.db_ui_show_database_icon = 0
            vim.g.db_ui_tmp_query_location = data_path .. "/dadbod_ui/tmp"
            vim.g.db_ui_use_nerd_fonts = 0
            vim.g.db_ui_use_nvim_notify = 1
            vim.g.db_ui_execute_on_save = 0
        end,
    },

    {
        "saecki/crates.nvim",
        event = { "BufRead Cargo.toml", "BufNewFile Cargo.toml" },
        opts = {
            lsp = { enabled = true, actions = true, completion = true, hover = true },
            completion = {
                crates = { enabled = true, max_results = 8, min_chars = 3 },
                blink = { use_custom_kind = true },
            },
            popup = { border = "single" },
        },
    },

    {
        "mrcjkb/rustaceanvim",
        version = false,
        ft = { "rust" },
        init = function()
            vim.g.rustaceanvim = function()
                local codelldb = vim.fn.exepath("codelldb")
                local dap_cfg = { autoload_configurations = false }
                if codelldb ~= "" then
                    local sys_lib = "/usr/lib/liblldb.so"
                    local mason_lib = vim.fn.stdpath("data")
                        .. "/mason/packages/codelldb/extension/lldb/lib/liblldb.so"
                    local lib_path = vim.uv.fs_stat(sys_lib) and sys_lib or mason_lib
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
                                    allFeatures = true,
                                    loadOutDirsFromCheck = true,
                                    targetDir = vim.fn.stdpath("cache") .. "/rust-analyzer-target/",
                                },
                                procMacro = {
                                    enable = true,
                                    attributes = { enable = true },
                                },
                                server = { extraEnv = { RA_LOG = "error" } },
                                workspace = {
                                    symbol = { search = { scope = "workspace" } },
                                },
                                check = {
                                    command = "clippy",
                                    allTargets = true,
                                    extraArgs = { "--no-deps" },
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
                                cachePriming = { enable = true },
                                completion = {
                                    callable = { snippets = "fill_arguments" },
                                    postfix = { enable = true },
                                },
                                hover = { actions = { enable = true, references = true } },
                                lens = { enable = true },
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
                group = vim.api.nvim_create_augroup("rustaceanvim_actions", { clear = true }),
                callback = function(args)
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if not client or client.name ~= "rust-analyzer" then
                        return
                    end
                    vim.keymap.set({ "n", "v" }, "<leader>ca", function()
                        vim.cmd.RustLsp("codeAction")
                    end, { buf = args.buf, desc = "Rust: Code Action" })
                end,
            })
        end,
    },

    {
        "akinsho/flutter-tools.nvim",
        ft = "dart",
        cond = function()
            return vim.fn.executable("flutter") == 1 or vim.fn.executable("dart") == 1
        end,
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {
            ui = { border = "single" },
            decorations = {
                statusline = { app_version = true, device = true },
            },
            lsp = {
                settings = {
                    showTodos = true,
                    completeFunctionCalls = true,
                    analysisExcludedFolders = { vim.fn.expand("$HOME/.pub-cache") },
                    renameFilesWithClasses = "always",
                    enableSnippets = true,
                },
            },
            debugger = { enabled = true },
        },
    },
}
