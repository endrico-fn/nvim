return {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    lazy = true,
    ft = "markdown",
    cmd = "Obsidian",
    cond = function()
        return vim.fn.isdirectory(vim.fn.expand("~/Obsidian/enrico")) == 1
    end,

    keys = {
        {
            "<leader>On",
            function()
                vim.cmd("Obsidian quick_switch")
            end,
            desc = "Obsidian: Quick Switch",
        },
        {
            "<leader>Os",
            function()
                vim.cmd("Obsidian search")
            end,
            desc = "Obsidian: Search Vault",
        },
        {
            "<leader>ON",
            function()
                vim.cmd("Obsidian new")
            end,
            desc = "Obsidian: New Note",
        },
        {
            "<leader>Ot",
            function()
                vim.cmd("Obsidian today")
            end,
            desc = "Obsidian: Today's Note",
        },
        {
            "<leader>Oy",
            function()
                vim.cmd("Obsidian yesterday")
            end,
            desc = "Obsidian: Yesterday's Note",
        },
        {
            "<leader>Ob",
            function()
                vim.cmd("Obsidian backlinks")
            end,
            desc = "Obsidian: Backlinks",
        },
        {
            "<leader>OT",
            function()
                vim.cmd("Obsidian toc")
            end,
            desc = "Obsidian: Table of Contents",
        },
        {
            "<leader>Op",
            function()
                vim.cmd("Obsidian paste_img")
            end,
            desc = "Obsidian: Paste Image",
        },
        {
            "<leader>Oo",
            function()
                vim.cmd("Obsidian open")
            end,
            desc = "Obsidian: Open in App",
        },
        {
            "<leader>Ow",
            function()
                vim.cmd("Obsidian workspace")
            end,
            desc = "Obsidian: Switch Workspace",
        },
    },

    dependencies = {
        "nvim-lua/plenary.nvim",
    },

    ---@module 'obsidian'
    opts = {

        legacy_commands = false,

        workspaces = {
            {
                name = "enrico",
                path = "~/Obsidian/enrico",
            },
        },

        new_notes_location = "current_dir",

        link = {
            style = "wiki",
            format = "shortest",
            auto_update = true,
        },

        note_id_func = function(...)
            return require("obsidian.builtin").title_id(...)
        end,

        note_path_func = function(spec)
            local path = spec.dir / tostring(spec.id)
            return path:with_suffix(".md", true)
        end,

        note = {
            template = nil,
        },
        templates = {
            enabled = true,
            folder = "_meta/_templates",
            date_format = "YYYY-MM-DD",
            time_format = "HH:mm",
            substitutions = {

                date = function(_, suffix)
                    local format = suffix or "YYYY-MM-DD"
                    return require("obsidian.util").format_date(os.time(), format)
                end,
                time = function(_, suffix)
                    local format = suffix or "HH:mm"
                    return require("obsidian.util").format_date(os.time(), format)
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

        completion = {
            min_chars = 2,
            match_case = true,
            create_new = true,
        },

        picker = {
            name = "snacks.picker",
            note_mappings = {
                new = "<C-x>",
                insert_link = "<C-l>",
            },
            tag_mappings = {
                tag_note = "<C-x>",
                insert_tag = "<C-l>",
            },
        },

        search = {
            sort_by = "modified",
            sort_reversed = true,
            max_lines = 1000,
        },

        --- UI rendering diserahkan sepenuhnya ke render-markdown.nvim
        --- (rekomendasi resmi render-markdown.nvim untuk menghindari double-render)
        ui = {
            enable = false,
        },

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

        backlinks = {
            parse_headers = true,
        },

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

        local aug = vim.api.nvim_create_augroup("obsidian-keymaps", { clear = true })

        vim.api.nvim_create_autocmd("FileType", {
            group = aug,
            pattern = "markdown",
            desc = "Set Obsidian buffer-local keymaps",
            callback = function(args)
                local path = vim.api.nvim_buf_get_name(args.buf)
                if not path:find(vault_path, 1, true) then
                    return
                end

                local bufopts = { buffer = args.buf, silent = true, noremap = true }

                vim.keymap.set("n", "<CR>", function()
                    return require("obsidian").actions.smart_action()
                end, vim.tbl_extend(
                    "force",
                    bufopts,
                    { desc = "Obsidian: Smart Action" }
                ))

                vim.keymap.set("n", "gl", function()
                    return require("obsidian").actions.follow_link()
                end, vim.tbl_extend(
                    "force",
                    bufopts,
                    { desc = "Obsidian: Follow Link" }
                ))

                vim.keymap.set("n", "]o", function()
                    return require("obsidian").actions.nav_link(true)
                end, vim.tbl_extend(
                    "force",
                    bufopts,
                    { desc = "Obsidian: Next Link" }
                ))

                vim.keymap.set("n", "[o", function()
                    return require("obsidian").actions.nav_link(false)
                end, vim.tbl_extend(
                    "force",
                    bufopts,
                    { desc = "Obsidian: Prev Link" }
                ))

                vim.keymap.set("n", "<leader>Oc", function()
                    return require("obsidian").actions.toggle_checkbox()
                end, vim.tbl_extend(
                    "force",
                    bufopts,
                    { desc = "Obsidian: Toggle Checkbox" }
                ))
            end,
        })
    end,
}
