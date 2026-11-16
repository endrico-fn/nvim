--- Format ukuran file human-readable (B, KB, MB, GB) dengan lebar tetap 8 karakter
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
    else
        return string.format("%5.1f %s", b, units[i])
    end
end

--- Format tipe item (4 karakter: dir , link, file)
local function get_type(item)
    if item.dir then
        return "dir "
    elseif item.type == "link" then
        return "link"
    else
        return "file"
    end
end

--- Custom table formatter untuk Snacks.explorer (Solusi 3: Hybrid Table + Preview)
--- Menampilkan tabel [Type] [Size] [Datetime] [Git] saat window float lebar dan preview tertutup.
--- Otomatis menyembunyikan kolom metadata saat preview terbuka (tombol 'P') atau di sidebar sempit.
local function explorer_table_format(item, picker)
    local ret = Snacks.picker.format.file(item, picker)

    -- Sembunyikan kolom tabel jika panel preview sedang terbuka (diberi ruang penuh untuk preview)
    local has_preview = picker.preview and picker.preview.win and picker.preview.win.enabled
    if has_preview then
        return ret
    end

    -- Sembunyikan kolom tabel di sidebar sempit (<leader>E dengan lebar < 70) agar nama file tidak terpotong
    local win = picker.list and picker.list.win and picker.list.win.win
    if win and vim.api.nvim_win_is_valid(win) then
        local width = vim.api.nvim_win_get_width(win)
        if width < 70 then
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
        -- Masukkan kolom meta di depan git status icon
        for i = #meta, 1, -1 do
            table.insert(git_entry.virt_text, 1, meta[i])
        end
    else
        -- Jika tidak ada perubahan git, buat virt_text rata kanan dengan padding penyeimbang icon git
        local m = vim.deepcopy(meta)
        table.insert(m, { "   " }) -- 3 spasi penyeimbang lebar git icon (2) + spasi (1)
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
    "folke/snacks.nvim",
    version = "*",
    priority = 1000,
    lazy = false,
    --- Untuk image preview di Obsidian vault
    --- Dokumentasi: https://github.com/obsidian-nvim/obsidian.nvim/wiki/Images
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

        -- Find / Files
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

        -- Search / Grep
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

        -- Diagnostics & Helpers
        {
            "<leader>fh",
            function()
                Snacks.picker.help()
            end,
            desc = "Help Tags",
        },
        {
            "<leader>fm",
            function()
                Snacks.picker.marks()
            end,
            desc = "Marks",
        },
        {
            "<leader>fd",
            function()
                Snacks.picker.diagnostics({ filter = { buf = 0 } })
            end,
            desc = "Document Diagnostics",
        },
        {
            "<leader>fD",
            function()
                Snacks.picker.diagnostics()
            end,
            desc = "Workspace Diagnostics",
        },
        {
            "<leader>fq",
            function()
                Snacks.picker.qflist()
            end,
            desc = "Quickfix List",
        },
        {
            "<leader>fR",
            function()
                Snacks.picker.resume()
            end,
            desc = "Resume Last Picker",
        },

        -- LSP & UI
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

        -- Git
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
        {
            "<leader>gb",
            function()
                Snacks.git.blame_line()
            end,
            desc = "Git Blame Line",
        },

        -- Image & UI
        {
            "<leader>uI",
            function()
                local ok, snacks = pcall(require, "snacks")
                if ok then
                    snacks.image.hide()
                end
            end,
            desc = "Snacks: Hide All Images",
        },
        {
            "<leader>un",
            function()
                local ok, snacks = pcall(require, "snacks")
                if ok then
                    snacks.notifier.show_history()
                end
            end,
            desc = "Notification History",
        },
        {
            "<leader>uD",
            function()
                local ok, snacks = pcall(require, "snacks")
                if ok then
                    snacks.notifier.hide()
                end
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
                    { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
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
                enabled = vim.fn.has("nvim-0.10") == 1,
                style = "out",
                duration = {
                    step = 20,
                    total = 500,
                },
            },
            scope = {
                enabled = true,
                char = "¦",
                underline = false,
                hl = "SnacksIndentScope",
            },
        },
        input = { enabled = true },
        notifier = {
            enabled = true,
            timeout = 5000,
            width = { min = 40, max = 0.7 },
            style = "compact",
            filter = function(notif)
                -- Redam false-positive warning dari Noice saat menggunakan GUI Neovide
                if notif.msg and notif.msg:find("You're using a GUI that uses ext_") then
                    return false
                end
                return true
            end,
        },

        --- Image viewer — satu-satunya backend image yg didukung resmi oleh obsidian.nvim
        image = {
            enabled = true,
            -- Kitty terminal protocol (kamu pakai kitty ✅)
            -- Juga support Sixel, iTerm2, dan fallback ke floating window

            --- Resolve attachment path untuk Obsidian vault
            --- API bisa berubah di masa depan (lihat wiki obsidian.nvim)
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
            size = 1.5 * 1024 * 1024, -- 1.5MB
            line_length = 1000,
        },

        quickfile = {
            enabled = true,
        },

        statuscolumn = {
            enabled = true,
            left = { "mark", "sign" },
            right = { "fold", "git" },
            folds = {
                open = true,
                git_hl = false,
            },
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
            toggles = {
                dim = true,
                git_signs = false,
            },
            show = {
                statusline = false,
                tabline = false,
            },
            win = { style = "zen" },
        },

        terminal = {
            enabled = true,
            win = {
                style = "terminal",
            },
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
            layout = {
                backdrop = false,
            },
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
                        file = {
                            git_status_hl = true,
                        },
                    },
                },
            },
        },

        explorer = {
            enabled = true,
        },
    },
}
