local function format_size(bytes, is_dir)
    if is_dir or not bytes then
        return "    -   "
    end
    if bytes == 0 then
        return "    0 B "
    end
    local units = { "B ", "KB", "MB", "GB" }
    local i = 1
    local b = bytes
    while b >= 1024 and i < #units do
        b = b / 1024
        i = i + 1
    end
    if i == 1 then
        return string.format("%5d B ", b)
    end
    return string.format("%5.1f %s", b, units[i])
end

local function get_type(item)
    if item.dir then
        return "dir "
    elseif item.type == "link" then
        return "link"
    end
    return "file"
end

local function explorer_table_format(item, picker)
    local ret = Snacks.picker.format.file(item, picker)

    local has_preview = picker.preview and picker.preview.win and picker.preview.win.enabled
    if has_preview then
        return ret
    end

    local win = picker.list and picker.list.win and picker.list.win.win
    if win and vim.api.nvim_win_is_valid(win) then
        if vim.api.nvim_win_get_width(win) < 70 then
            return ret
        end
    end

    local stat = item.file and vim.uv.fs_stat(item.file)
    local f_type = get_type(item)
    local f_size = format_size(stat and stat.size, item.dir)
    local f_time = stat and stat.mtime and os.date("%Y-%m-%d %H:%M", stat.mtime.sec)
        or "                "

    local type_hl = item.dir and "Directory" or (item.type == "link" and "Special" or "Comment")
    local size_hl = (not item.dir and stat and stat.size > 0) and "Number" or "Comment"

    local meta = {
        { "  " },
        { f_type, type_hl },
        { "  " },
        { f_size, size_hl },
        { "  " },
        { f_time, "Comment" },
        { "  " },
    }

    local git_entry = nil
    for _, r in ipairs(ret) do
        if r.virt_text_pos == "right_align" then
            git_entry = r
            break
        end
    end

    if git_entry then
        for i = #meta, 1, -1 do
            table.insert(git_entry.virt_text, 1, meta[i])
        end
    else
        local m = vim.deepcopy(meta)
        table.insert(m, { "   " })
        table.insert(ret, {
            col = 0,
            virt_text = m,
            virt_text_pos = "right_align",
            hl_mode = "combine",
        })
    end

    return ret
end

return {
    {
        "folke/snacks.nvim",
        version = "*",
        priority = 1000,
        lazy = false,
        keys = {
            -- Explorer
            {
                "<leader>e",
                function()
                    Snacks.explorer({
                        layout = { preset = "default", backdrop = false },
                        jump = { close = true },
                    })
                end,
                desc = "File Explorer (Float)",
            },
            {
                "<leader>E",
                function()
                    Snacks.explorer({ layout = { preset = "sidebar" } })
                end,
                desc = "File Explorer (Sidebar)",
            },

            -- Files (<leader>f* files & buffers only)
            {
                "<leader>ff",
                function()
                    Snacks.picker.files()
                end,
                desc = "Find Files",
            },
            {
                "<leader>fg",
                function()
                    Snacks.picker.git_files()
                end,
                desc = "Git Files",
            },
            {
                "<leader>fr",
                function()
                    Snacks.picker.recent()
                end,
                desc = "Recent Files",
            },
            {
                "<leader>fb",
                function()
                    Snacks.picker.buffers()
                end,
                desc = "Buffers",
            },
            {
                "<leader>fc",
                function()
                    Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
                end,
                desc = "Find Config File",
            },

            -- Search & Pickers (<leader>s*)
            {
                "<leader>sg",
                function()
                    Snacks.picker.grep()
                end,
                desc = "Live Grep",
            },
            {
                "<leader>sw",
                function()
                    Snacks.picker.grep_word()
                end,
                desc = "Grep Word Under Cursor",
            },
            {
                "<leader>s/",
                function()
                    Snacks.picker.search_history()
                end,
                desc = "Search History",
            },
            {
                "<leader>sC",
                function()
                    Snacks.picker.commands()
                end,
                desc = "Commands",
            },
            {
                "<leader>sk",
                function()
                    Snacks.picker.keymaps()
                end,
                desc = "Keymaps",
            },
            {
                "<leader>sj",
                function()
                    Snacks.picker.jumps()
                end,
                desc = "Jumplist",
            },
            {
                "<leader>sH",
                function()
                    Snacks.picker.highlights()
                end,
                desc = "Highlights",
            },
            {
                "<leader>st",
                function()
                    Snacks.picker.todo_comments()
                end,
                desc = "Todo Comments",
            },
            {
                "<leader>/",
                function()
                    Snacks.picker.lines()
                end,
                desc = "Fuzzy in Buffer",
            },
            {
                "<leader>su",
                function()
                    Snacks.picker.undo()
                end,
                desc = "Undo History",
            },
            {
                "<leader>sp",
                function()
                    Snacks.picker.projects()
                end,
                desc = "Projects",
            },
            {
                "<leader>sh",
                function()
                    Snacks.picker.help()
                end,
                desc = "Help Tags",
            },
            {
                "<leader>sm",
                function()
                    Snacks.picker.marks()
                end,
                desc = "Marks",
            },
            {
                "<leader>sd",
                function()
                    Snacks.picker.diagnostics({ filter = { buf = 0 } })
                end,
                desc = "Document Diagnostics",
            },
            {
                "<leader>sD",
                function()
                    Snacks.picker.diagnostics()
                end,
                desc = "Workspace Diagnostics",
            },
            {
                "<leader>sq",
                function()
                    Snacks.picker.qflist()
                end,
                desc = "Quickfix List",
            },
            {
                "<leader>sr",
                function()
                    Snacks.picker.resume()
                end,
                desc = "Resume Last Picker",
            },

            -- LSP Pickers
            {
                "<leader>sl",
                function()
                    Snacks.picker.lsp_symbols()
                end,
                desc = "LSP Document Symbols",
            },
            {
                "<leader>sS",
                function()
                    Snacks.picker.lsp_workspace_symbols()
                end,
                desc = "LSP Workspace Symbols",
            },
            {
                "<leader>ci",
                function()
                    Snacks.picker.lsp_incoming_calls()
                end,
                desc = "LSP Incoming Calls",
            },
            {
                "<leader>um",
                function()
                    Snacks.picker.colorschemes()
                end,
                desc = "Colorscheme Preview",
            },

            -- Git Pickers
            {
                "<leader>gS",
                function()
                    Snacks.picker.git_status()
                end,
                desc = "Git Status",
            },
            {
                "<leader>gd",
                function()
                    Snacks.picker.git_diff()
                end,
                desc = "Git Diff",
            },
            {
                "<leader>gl",
                function()
                    Snacks.picker.git_log()
                end,
                desc = "Git Log",
            },
            {
                "<leader>gL",
                function()
                    Snacks.picker.git_log_file()
                end,
                desc = "Git Log File",
            },

            -- Image, Notifications & UI
            {
                "<leader>uI",
                function()
                    Snacks.image.hide()
                end,
                desc = "Snacks: Hide All Images",
            },
            {
                "<leader>un",
                function()
                    Snacks.notifier.show_history()
                end,
                desc = "Notification History",
            },
            {
                "<leader>uD",
                function()
                    Snacks.notifier.hide()
                end,
                desc = "Dismiss All Notifications",
            },
            {
                "<leader>uz",
                function()
                    Snacks.zen()
                end,
                desc = "Toggle Zen Mode",
            },
            {
                "<leader>uZ",
                function()
                    Snacks.zen.zoom()
                end,
                desc = "Toggle Zoom Window",
            },
            {
                "]]",
                function()
                    Snacks.words.jump(vim.v.count1)
                end,
                desc = "Next Reference",
                mode = { "n", "t" },
            },
            {
                "[[",
                function()
                    Snacks.words.jump(-vim.v.count1)
                end,
                desc = "Prev Reference",
                mode = { "n", "t" },
            },
            {
                "<c-/>",
                function()
                    Snacks.terminal.toggle(nil, { win = { position = "float" } })
                end,
                desc = "Toggle Terminal (Float)",
                mode = { "n", "t" },
            },
            {
                "<c-_>",
                function()
                    Snacks.terminal.toggle(nil, { win = { position = "float" } })
                end,
                desc = "which_key_ignore",
                mode = { "n", "t" },
            },
            {
                "<leader>Tf",
                function()
                    Snacks.terminal.toggle(nil, { win = { position = "float" } })
                end,
                desc = "Terminal: Float",
            },
            {
                "<leader>Th",
                function()
                    Snacks.terminal.toggle(nil, { win = { position = "bottom", height = 0.35 } })
                end,
                desc = "Terminal: Bottom Split",
            },
            {
                "<leader>Tv",
                function()
                    Snacks.terminal.toggle(nil, { win = { position = "right", width = 0.4 } })
                end,
                desc = "Terminal: Vertical Split",
            },
        },
        opts = {
            dashboard = {
                enabled = true,
                preset = {
                    header = [[
███╗   ██╗  ███████╗   ██████╗   ██╗   ██╗  ██╗  ███╗   ███╗
████╗  ██║  ██╔════╝  ██╔═══██╗  ██║   ██║  ██║  ████╗ ████║
██╔██╗ ██║  █████╗    ██║   ██║  ██║   ██║  ██║  ██╔████╔██║
██║╚██╗██║  ██╔══╝    ██║   ██║  ╚██╗ ██╔╝  ██║  ██║╚██╔╝██║
██║ ╚████║  ███████╗  ╚██████╔╝   ╚████╔╝   ██║  ██║ ╚═╝ ██║
╚═╝  ╚═══╝  ╚══════╝   ╚═════╝     ╚═══╝    ╚═╝  ╚═╝     ╚═╝]],
                    keys = {
                        {
                            icon = " ",
                            key = "n",
                            desc = "New File",
                            action = ":ene | startinsert",
                        },
                        {
                            icon = " ",
                            key = "f",
                            desc = "Find File",
                            action = ":lua Snacks.picker.files()",
                        },
                        {
                            icon = " ",
                            key = "r",
                            desc = "Recent Files",
                            action = ":lua Snacks.picker.recent()",
                        },
                        {
                            icon = " ",
                            key = "c",
                            desc = "Config Neovim",
                            action = ":lua Snacks.picker.files({ cwd = vim.fn.stdpath('config') })",
                        },
                        {
                            icon = "⭯ ",
                            key = "s",
                            desc = "Select Session",
                            action = ":lua require('persistence').select()",
                        },
                        { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
                        { icon = "󱌢 ", key = "m", desc = "Mason", action = ":Mason" },
                        { icon = " ", key = "q", desc = "Quit", action = ":qa" },
                    },
                },
                sections = {
                    { section = "header" },
                    { section = "keys", gap = 1, padding = 1 },
                    function()
                        local quotes = {
                            "Life is absurd, and that is precisely what makes it so beautiful. – Albert Camus",
                            "Those who cannot remember the past are condemned to repeat it. – George Santayana",
                            "The only way to deal with this life meaninglessly is to find meaning. – Viktor Frankl",
                            "We do not remember days, we remember moments. – Cesare Pavese",
                            "In three words I can sum up everything I've learned about life: it goes on. – Robert Frost",
                            "The only way to do great work is to love what you do. – Steve Jobs",
                            "Innovation distinguishes between a leader and a follower. – Steve Jobs",
                        }
                        return {
                            align = "center",
                            padding = 1,
                            text = { { quotes[math.random(#quotes)], hl = "comment" } },
                        }
                    end,
                    { section = "startup" },
                },
            },
            indent = {
                enabled = true,
                indent = {
                    enabled = true,
                    char = "¦",
                    only_scope = false,
                    hl = "SnacksIndent",
                },
                animate = {
                    enabled = true,
                    style = "out",
                    duration = { step = 20, total = 500 },
                },
                scope = {
                    enabled = true,
                    char = "¦",
                    underline = false,
                    hl = "SnacksIndentScope",
                },
            },
            scope = { enabled = true },
            input = { enabled = true },
            notifier = {
                enabled = true,
                timeout = 5000,
                width = { min = 40, max = 0.7 },
                style = "compact",
            },
            image = {
                enabled = true,
                resolve = function(path, src)
                    local ok, api = pcall(require, "obsidian.api")
                    if ok and api.path_is_note(path) then
                        return api.resolve_attachment_path(src)
                    end
                end,
            },
            bigfile = {
                enabled = true,
                notify = true,
                size = 1.5 * 1024 * 1024,
                line_length = 1000,
            },
            quickfile = { enabled = true },
            statuscolumn = {
                enabled = true,
                left = { "mark", "sign" },
                right = { "fold", "git" },
                folds = { open = true, git_hl = false },
            },
            scroll = {
                enabled = true,
                animate = {
                    duration = { step = 10, total = 200 },
                    easing = "linear",
                },
            },
            words = {
                enabled = true,
                debounce = 200,
                notify_jump = false,
                notify_end = true,
            },
            zen = {
                enabled = true,
                toggles = { dim = true, git_signs = false },
                show = { statusline = false, tabline = false },
                win = { style = "zen" },
            },
            terminal = {
                enabled = true,
                win = { style = "terminal" },
            },
            styles = {
                float = {
                    backdrop = false,
                    wo = {
                        winhighlight = "Normal:SnacksNormal,NormalNC:SnacksNormalNC,FloatBorder:SnacksPickerBorder",
                    },
                },
                terminal = {
                    border = "single",
                    title = "  Terminal ",
                    title_pos = "center",
                    height = 0.85,
                    width = 0.85,
                    backdrop = false,
                    wo = {
                        winhighlight = "Normal:SnacksNormal,NormalNC:SnacksNormalNC,FloatBorder:FloatBorder,FloatTitle:FloatTitle",
                    },
                },
            },
            picker = {
                enabled = true,
                layout = { backdrop = false },
                win = {
                    input = {
                        wo = {
                            winhighlight = "Normal:SnacksPickerInput,NormalNC:SnacksPickerInput,FloatBorder:SnacksPickerInputBorder,FloatTitle:SnacksPickerInputTitle",
                        },
                    },
                    list = {
                        wo = {
                            winhighlight = "Normal:SnacksPickerList,NormalNC:SnacksPickerList,FloatBorder:SnacksPickerListBorder,FloatTitle:SnacksPickerListTitle",
                        },
                    },
                    preview = {
                        wo = {
                            winhighlight = "Normal:SnacksPickerPreview,NormalNC:SnacksPickerPreview,FloatBorder:SnacksPickerPreviewBorder,FloatTitle:SnacksPickerPreviewTitle",
                        },
                    },
                },
                icons = {
                    git = {
                        enabled = true,
                        commit = "󰜘 ",
                        staged = "✓ ",
                        added = " ",
                        deleted = " ",
                        ignored = " ",
                        modified = " ",
                        renamed = "➜ ",
                        unmerged = " ",
                        untracked = "★ ",
                    },
                },
                sources = {
                    explorer = {
                        hidden = true,
                        git_status = true,
                        git_status_open = true,
                        git_untracked = true,
                        format = explorer_table_format,
                        formatters = {
                            file = { git_status_hl = true },
                        },
                    },
                },
            },
            explorer = { enabled = true },
        },
    },

    {
        "echasnovski/mini.icons",
        lazy = true,
        init = function()
            package.preload["nvim-web-devicons"] = function()
                require("mini.icons").mock_nvim_web_devicons()
                return package.loaded["nvim-web-devicons"]
            end
        end,
        opts = {
            style = "default",
            file = {
                [".eslintrc.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
                [".node-version"] = { glyph = "", hl = "MiniIconsGreen" },
                [".prettierrc"] = { glyph = "", hl = "MiniIconsPurple" },
                [".yarnrc.yml"] = { glyph = "", hl = "MiniIconsBlue" },
                ["eslint.config.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
                ["package.json"] = { glyph = "", hl = "MiniIconsGreen" },
                ["tsconfig.json"] = { glyph = "", hl = "MiniIconsAzure" },
                ["tsconfig.build.json"] = { glyph = "", hl = "MiniIconsAzure" },
                ["yarn.lock"] = { glyph = "", hl = "MiniIconsBlue" },
            },
        },
    },

    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "echasnovski/mini.icons" },
        event = "UIEnter",
        init = function()
            if vim.fn.argc(-1) == 0 then
                vim.o.statusline = " "
            end
            vim.api.nvim_create_autocmd({ "DirChanged", "BufFilePost" }, {
                group = vim.api.nvim_create_augroup("lualine_root_invalidate", { clear = true }),
                callback = function(ev)
                    if vim.api.nvim_buf_is_valid(ev.buf) then
                        vim.b[ev.buf].cached_root = nil
                    else
                        for _, b in ipairs(vim.api.nvim_list_bufs()) do
                            if vim.api.nvim_buf_is_valid(b) then
                                vim.b[b].cached_root = nil
                            end
                        end
                    end
                end,
            })
        end,
        opts = function()
            local c = require("theme.cryptnight.colors").get_colors()
            local lualine_theme = require("theme.cryptnight.lualine")
            local colors = {
                fg = c.fg,
                fg_dim = c.line_number,
                yellow = c.dark_yellow,
                cyan = c.blue,
                green = c.light_green,
                orange = c.ui_orange,
                violet = c.pink,
            }
            local icons = {
                git = { added = " ", modified = " ", removed = " " },
                diagnostics = { Error = "󰅚 ", Warn = "󰀪 ", Hint = "󰌶 ", Info = "󰋽 " },
            }
            local conditions = {
                buffer_not_empty = function()
                    return vim.api.nvim_buf_get_name(0) ~= ""
                end,
                hide_in_width = function()
                    return vim.fn.winwidth(0) > 80
                end,
            }

            local function get_winbar_title(is_active)
                local buf = vim.api.nvim_get_current_buf()
                local ft = vim.bo[buf].filetype
                local bt = vim.bo[buf].buftype

                if ft == "OverseerList" or ft == "overseer" then
                    return "  Tasks"
                elseif ft == "OverseerOutput" then
                    local task_id = vim.b[buf].overseer_task
                    if task_id then
                        local ok, task_list = pcall(require, "overseer.task_list")
                        if ok then
                            local task = task_list.get(task_id)
                            if task and task.name then
                                return "  " .. task.name
                            end
                        end
                    end
                    return "  Task Output"
                elseif bt == "terminal" then
                    return "  Terminal"
                end

                local file = vim.api.nvim_buf_get_name(buf)
                if file == "" then
                    return " [No Name]"
                end
                local modified = vim.bo[buf].modified and " ●" or ""
                local readonly = (is_active and vim.bo[buf].readonly) and " 󰌾" or ""
                return " " .. vim.fn.fnamemodify(file, ":t") .. modified .. readonly
            end

            return {
                options = {
                    theme = lualine_theme,
                    globalstatus = true,
                    component_separators = { left = "", right = "" },
                    section_separators = { left = "", right = "" },
                    disabled_filetypes = {
                        statusline = { "snacks_dashboard" },
                        winbar = {
                            "snacks_dashboard",
                            "snacks_picker_input",
                            "snacks_picker_list",
                            "trouble",
                            "snacks_terminal",
                        },
                    },
                },
                winbar = {
                    lualine_a = {
                        {
                            function()
                                return get_winbar_title(true)
                            end,
                            color = { fg = colors.cyan, bg = "NONE", gui = "bold" },
                            padding = { left = 1, right = 0 },
                        },
                    },
                    lualine_b = {
                        {
                            "filetype",
                            icon_only = true,
                            padding = { left = 1, right = 1 },
                            color = { fg = c.accent_blue, bg = "NONE", gui = "bold" },
                        },
                        {
                            function()
                                local aerial = package.loaded["aerial"]
                                if not aerial then
                                    return ""
                                end
                                local data = aerial.get_location(true)
                                if type(data) ~= "table" or #data == 0 then
                                    return ""
                                end
                                local parts = {}
                                for _, item in ipairs(data) do
                                    table.insert(parts, (item.icon or "") .. " " .. item.name)
                                end
                                return "  " .. table.concat(parts, " › ")
                            end,
                            color = { fg = colors.fg_dim, bg = "NONE" },
                            padding = { left = 0, right = 1 },
                        },
                    },
                },
                inactive_winbar = {
                    lualine_a = {
                        {
                            function()
                                return get_winbar_title(false)
                            end,
                            color = { fg = colors.fg_dim, bg = "NONE" },
                            padding = { left = 0, right = 1 },
                        },
                    },
                    lualine_b = {
                        {
                            "filetype",
                            icon_only = true,
                            padding = { left = 0, right = 1 },
                            color = { fg = colors.fg_dim, bg = "NONE" },
                        },
                    },
                },
                sections = {
                    lualine_a = {
                        {
                            "mode",
                            fmt = function(str)
                                return " " .. str
                            end,
                            padding = { left = 1, right = 1 },
                        },
                    },
                    lualine_b = {
                        { "branch", icon = "", color = { fg = colors.violet, gui = "bold" } },
                        {
                            "diff",
                            symbols = icons.git,
                            diff_color = {
                                added = { fg = colors.green },
                                modified = { fg = colors.yellow },
                                removed = { fg = c.red },
                            },
                            cond = conditions.hide_in_width,
                        },
                    },
                    lualine_c = {
                        {
                            function()
                                local buf = vim.api.nvim_get_current_buf()
                                local root = vim.b[buf].cached_root
                                if root == nil then
                                    local fname = vim.api.nvim_buf_get_name(buf)
                                    root = require("util.root").root_dir(fname) or false
                                    vim.b[buf].cached_root = root
                                end
                                return root and (" " .. vim.fs.basename(root))
                                    or (" " .. vim.fs.basename(vim.uv.cwd()))
                            end,
                            color = { fg = colors.cyan, gui = "bold" },
                            padding = { left = 1, right = 1 },
                        },
                        {
                            function()
                                local path = vim.fn.expand("%:p")
                                if path == "" then
                                    return ""
                                end
                                local buf = vim.api.nvim_get_current_buf()
                                local root = vim.b[buf].cached_root
                                local cwd = vim.uv.cwd()

                                if root and path:find(root, 1, true) == 1 then
                                    path = path:sub(#root + 2)
                                elseif cwd and path:find(cwd, 1, true) == 1 then
                                    path = path:sub(#cwd + 2)
                                end

                                local parts = vim.split(path, "[\\/]")
                                if #parts > 3 then
                                    parts = { parts[1], "…", parts[#parts - 1], parts[#parts] }
                                end
                                return table.concat(parts, "/")
                            end,
                            color = { fg = colors.fg },
                        },
                    },
                    lualine_x = {
                        { "overseer", label = "", colored = true },
                        {
                            "diagnostics",
                            symbols = {
                                error = icons.diagnostics.Error,
                                warn = icons.diagnostics.Warn,
                                info = icons.diagnostics.Info,
                                hint = icons.diagnostics.Hint,
                            },
                        },
                        {
                            function()
                                local buf = vim.api.nvim_get_current_buf()
                                if vim.treesitter.highlighter.active[buf] then
                                    return " "
                                end
                                return ""
                            end,
                            color = { fg = colors.green },
                        },
                        {
                            "filesize",
                            cond = conditions.buffer_not_empty,
                            color = { fg = colors.fg },
                        },
                        {
                            require("lazy.status").updates,
                            cond = require("lazy.status").has_updates,
                            color = { fg = colors.orange },
                        },
                    },
                    lualine_y = {
                        { "searchcount", color = { fg = colors.yellow } },
                        {
                            function()
                                local macro = vim.fn.reg_recording()
                                if macro == "" then
                                    return ""
                                end
                                return "󰛫 " .. macro
                            end,
                            color = { fg = colors.orange, gui = "bold" },
                        },
                        { "location", color = { fg = colors.fg, gui = "bold" } },
                    },
                    lualine_z = {
                        {
                            "progress",
                            fmt = function()
                                return "%P/%L"
                            end,
                        },
                    },
                },
                inactive_sections = {
                    lualine_a = {
                        {
                            function()
                                local file = vim.api.nvim_buf_get_name(0)
                                if file == "" then
                                    return " [No Name]"
                                end
                                return " " .. vim.fn.fnamemodify(file, ":t")
                            end,
                            color = { fg = colors.fg_dim, bg = "NONE" },
                            padding = { left = 1, right = 1 },
                        },
                    },
                    lualine_c = {
                        { "filetype", icon_only = true, color = { fg = colors.fg_dim } },
                    },
                    lualine_y = {
                        { "location", color = { fg = colors.fg_dim } },
                    },
                    lualine_z = {
                        {
                            "progress",
                            fmt = function()
                                return "%P/%L"
                            end,
                        },
                    },
                },
                extensions = { "lazy", "quickfix", "man" },
            }
        end,
    },

    {
        "akinsho/bufferline.nvim",
        event = { "BufReadPost", "BufNewFile" },
        dependencies = { "echasnovski/mini.icons" },
        -- Note: <Tab> / <S-Tab> removed cleanly so native <C-i> jumplist works unobstructed.
        keys = {
            { "[b", "<cmd>BufferLineCyclePrev<CR>", desc = "Prev Buffer" },
            { "]b", "<cmd>BufferLineCycleNext<CR>", desc = "Next Buffer" },
            { "[B", "<cmd>BufferLineMovePrev<CR>", desc = "Move Buffer Left" },
            { "]B", "<cmd>BufferLineMoveNext<CR>", desc = "Move Buffer Right" },
            { "<leader>bp", "<cmd>BufferLineTogglePin<CR>", desc = "Pin Buffer" },
            { "<leader>bP", "<cmd>BufferLinePick<CR>", desc = "Pick Buffer" },
            { "<leader>bo", "<cmd>BufferLineCloseOthers<CR>", desc = "Close Other Buffers" },
            { "<leader>br", "<cmd>BufferLineCloseRight<CR>", desc = "Close Buffers Right" },
            { "<leader>bl", "<cmd>BufferLineCloseLeft<CR>", desc = "Close Buffers Left" },
            {
                "<leader>bd",
                function()
                    if Snacks and Snacks.bufdelete then
                        Snacks.bufdelete()
                    else
                        vim.cmd("bdelete")
                    end
                end,
                desc = "Close Buffer",
            },
        },
        opts = function()
            local function close_buf(bufnr)
                if Snacks and Snacks.bufdelete then
                    Snacks.bufdelete(bufnr)
                else
                    vim.cmd("bdelete! " .. bufnr)
                end
            end

            return {
                options = {
                    mode = "buffers",
                    always_show_bufferline = false,
                    numbers = function(opts)
                        return opts.raise(opts.ordinal)
                    end,
                    style_preset = require("bufferline").style_preset.no_italic,
                    close_command = close_buf,
                    right_mouse_command = close_buf,
                    buffer_close_icon = "✗",
                    show_close_icon = false,
                    diagnostics = "nvim_lsp",
                    diagnostics_indicator = function(_, _, diag)
                        local icons =
                            { error = " ", warning = " ", info = " ", hint = "󰌵 " }
                        local ret = {}
                        for _, level in ipairs({ "error", "warning", "info", "hint" }) do
                            if diag[level] and diag[level] > 0 then
                                table.insert(ret, icons[level] .. diag[level])
                            end
                        end
                        return table.concat(ret, " ")
                    end,
                    separator_style = { "", "" },
                    enforce_regular_tabs = true,
                    sort_by = "insert_after_current",
                    offsets = {
                        {
                            filetype = "snacks_layout_box",
                            text = function()
                                return "󰉓 " .. vim.fs.basename(vim.uv.cwd())
                            end,
                            highlight = "Directory",
                            text_align = "left",
                            separator = true,
                        },
                    },
                    custom_filter = function(bufnr)
                        local ft = vim.bo[bufnr].filetype
                        if ft == "qf" or ft == "gitcommit" or ft:find("^snacks_") then
                            return false
                        end
                        return true
                    end,
                    pick = {
                        alphabet = "asdfjklghweruio",
                    },
                },
            }
        end,
    },

    {
        "stevearc/aerial.nvim",
        event = { "LspAttach", "BufReadPost" },
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "echasnovski/mini.icons",
        },
        keys = {
            { "<leader>aa", "<cmd>AerialToggle!<cr>", desc = "Aerial (Symbol Outline)" },
            { "<leader>af", "<cmd>AerialNavToggle<cr>", desc = "Aerial Nav Float" },
            { "[S", "<cmd>AerialPrev<cr>", desc = "Aerial: Prev Symbol" },
            { "]S", "<cmd>AerialNext<cr>", desc = "Aerial: Next Symbol" },
        },
        opts = {
            layout = {
                min_width = 22,
                win_opts = {
                    winhl = "Normal:NormalFloat,FloatBorder:FloatBorder,SignColumn:SignColumnSB",
                    signcolumn = "yes",
                    statuscolumn = " ",
                },
            },
            close_automatic_events = { "unfocus", "switch_buffer", "unsupported" },
            filter_kind = {
                "Class",
                "Constructor",
                "Enum",
                "Function",
                "Interface",
                "Method",
                "Module",
                "Namespace",
                "Package",
                "Property",
                "Struct",
                "Trait",
                "Type",
                "TypeParameter",
            },
            highlight_on_hover = true,
            show_guides = true,
            guides = {
                mid_item = "├╴",
                last_item = "└╴",
                nested_top = "│ ",
                whitespace = "  ",
            },
            get_highlight = function(symbol, _, is_collapsed)
                if is_collapsed and symbol.children and #symbol.children > 0 then
                    return "AerialCollapsed"
                end
                return string.format("Aerial%sIcon", symbol.kind)
            end,
            nav = {
                border = "single",
                max_width = 0.45,
                win_opts = { winblend = 10 },
            },
            lsp = {
                priority = { basedpyright = 10, lua_ls = 10 },
            },
        },
        config = function(_, opts)
            require("aerial").setup(opts)
            vim.api.nvim_set_hl(0, "AerialLine", { link = "Visual" })
            vim.api.nvim_set_hl(0, "AerialCollapsed", { link = "Folded" })
            vim.api.nvim_set_hl(0, "AerialGuide", { link = "NonText" })

            local kind_hl_map = {
                Array = "Constant",
                Boolean = "Boolean",
                Class = "Type",
                Constant = "Constant",
                Constructor = "Function",
                Enum = "Type",
                EnumMember = "Constant",
                Event = "Exception",
                Field = "Identifier",
                File = "Directory",
                Function = "Function",
                Interface = "Type",
                Key = "Identifier",
                Method = "Function",
                Module = "Include",
                Namespace = "Include",
                Null = "Constant",
                Number = "Number",
                Object = "Type",
                Operator = "Operator",
                Package = "Include",
                Property = "Identifier",
                String = "String",
                Struct = "Structure",
                TypeParameter = "TypeDef",
                Variable = "Identifier",
            }
            for kind, hl in pairs(kind_hl_map) do
                vim.api.nvim_set_hl(0, "Aerial" .. kind .. "Icon", { link = hl })
            end
        end,
    },

    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        dependencies = { "echasnovski/mini.icons" },
        opts = {
            preset = "modern",
            delay = function(ctx)
                return ctx.plugin and 0 or 250
            end,
            icons = { enabled = true },
            triggers = {
                { "<auto>", mode = "nixsotc" },
                { "g", mode = { "n", "v" } },
                { "z", mode = { "n", "v" } },
            },
            win = {
                border = "single",
                padding = { 1, 2 },
                zindex = 1000,
                wo = {
                    winblend = 0,
                    winhighlight = "Normal:WhichKeyNormal,NormalNC:WhichKeyNormal,FloatBorder:WhichKeyBorder,FloatTitle:WhichKeyTitle",
                },
            },
            layout = { align = "center", spacing = 3 },
            plugins = {
                marks = true,
                registers = true,
                spelling = { enabled = true, suggestions = 15 },
                presets = {
                    operators = true,
                    motions = true,
                    text_objects = true,
                    windows = true,
                    nav = true,
                    z = true,
                    g = true,
                },
            },
            spec = {
                -- Non-leader prefixes
                { "]", group = "Next" },
                { "[", group = "Prev" },
                { "[B", desc = "Move Buffer Left" },
                { "]B", desc = "Move Buffer Right" },
                { "[H", group = "Harpoon" },
                { "]H", group = "Harpoon" },
                { "g", group = "Goto", icon = "󰮏 " },
                { "gr", group = "LSP (0.12 Builtin)", icon = "󰒋 " },
                { "gc", group = "Comment", mode = { "n", "v" } },
                { "gs", desc = "Flash Jump" },
                { "z", group = "Fold" },

                -- Textobjects (mini.ai)
                { "a", group = "around", mode = { "o", "x" } },
                { "i", group = "inside", mode = { "o", "x" } },
                { "af", desc = "Function", mode = { "o", "x" } },
                { "if", desc = "Function (inner)", mode = { "o", "x" } },
                { "ac", desc = "Class / Struct", mode = { "o", "x" } },
                { "ic", desc = "Class / Struct (inner)", mode = { "o", "x" } },
                { "ao", desc = "Block / Loop / If", mode = { "o", "x" } },
                { "io", desc = "Block / Loop / If (inner)", mode = { "o", "x" } },
                { "aa", desc = "Argument / Param", mode = { "o", "x" } },
                { "ia", desc = "Argument / Param (inner)", mode = { "o", "x" } },
                { "aq", desc = "Quote", mode = { "o", "x" } },
                { "iq", desc = "Quote (inner)", mode = { "o", "x" } },
                { "ab", desc = "Bracket () [] {}", mode = { "o", "x" } },
                { "ib", desc = "Bracket (inner)", mode = { "o", "x" } },
                { "at", desc = "Tag", mode = { "o", "x" } },
                { "it", desc = "Tag (inner)", mode = { "o", "x" } },
                { "ad", desc = "Digits", mode = { "o", "x" } },
                { "id", desc = "Digits (inner)", mode = { "o", "x" } },
                { "ae", desc = "Sub-word", mode = { "o", "x" } },
                { "ie", desc = "Sub-word (inner)", mode = { "o", "x" } },
                { "au", desc = "Function Call", mode = { "o", "x" } },
                { "iu", desc = "Function Call (inner)", mode = { "o", "x" } },

                -- Leader prefixes
                { "<leader>A", desc = "MC: Select All" },
                { "<leader>C", group = "Color", icon = "󰏘 " },
                { "<leader>D", group = "Database / SQL", icon = "󰆼 " },
                { "<leader>O", group = "Obsidian", icon = "󰎚 " },
                { "<leader>T", group = "Terminal", icon = " " },
                { "<leader>W", desc = "Save without formatting", icon = "󰆓 " },
                { "<leader>a", group = "Outline", icon = "󰉐 " },
                { "<leader>b", group = "Buffer", icon = "󰈙 " },
                { "<leader>c", group = "Code", icon = "󰛦 " },
                { "<leader>d", group = "Debug", icon = " " },
                { "<leader>f", group = "Files & Buffers", icon = "󰈞 " },
                { "<leader>g", group = "Git", icon = "󰊢 " },
                { "<leader>h", group = "Hunk", icon = "󰊢 " },
                { "<leader>k", group = "Toolchain (Buffer)", icon = "󰏖 " },
                { "<leader>kc", group = "Crates (Cargo)", icon = "󰏖 " },
                { "<leader>m", group = "Harpoon", icon = "󱠿 " },
                { "<leader>n", desc = "MC: Add Match Forward" },
                { "<leader>N", desc = "MC: Add Match Backward" },
                { "<leader>o", group = "Overseer", icon = " " },
                { "<leader>q", group = "Session", icon = "󰅶 " },
                { "<leader>r", group = "Replace & Snippets", icon = "󰛨 " },
                { "<leader>s", group = "Search", icon = "󰍉 " },
                { "<leader>t", group = "Test", icon = "󰙨 " },
                { "<leader>u", group = "UI", icon = "󰐥 " },
                { "<leader>w", group = "Windows", proxy = "<c-w>", icon = "󰁥 " },
                { "<leader>x", group = "Diagnostics / Trouble", icon = "󱖫 " },
                { "<leader>z", group = "Fold", icon = "󰁂 " },
            },
        },
    },
}
