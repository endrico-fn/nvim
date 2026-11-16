return {
    "nvim-lualine/lualine.nvim",
    dependencies = {
        "echasnovski/mini.icons",
    },
    event = "UIEnter",
    init = function()
        if vim.fn.argc(-1) == 0 then
            vim.o.statusline = " "
        end
    end,
    opts = function()
        local c = require("theme.cryptnight.colors").get_colors()
        local colors = {
            bg = c.bg_dark,
            fg = c.fg,
            fg_dim = c.line_number,
            yellow = c.dark_yellow,
            cyan = c.blue,
            green = c.light_green,
            orange = c.ui_orange,
            magenta = c.violet,
            blue = c.accent_blue,
            red = c.red,
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
        -- Cache noice module to avoid require() on every render
        local noice_ok, noice = pcall(require, "noice")
        local noice_status = noice_ok and noice.api.status or nil

        -- Helper untuk title winbar (mengenali Overseer, Terminal, dsb agar tidak [No Name])
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
                globalstatus = true,
                -- Warna komponen sudah di-set manual di bawah — tidak perlu theme terpisah.
                -- Jika ingin theme otomatis, set theme = require("theme.cryptnight.lualine")
                -- dan hapus color={...} dari tiap komponen.
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
                        color = { fg = colors.blue, bg = "NONE", gui = "bold" },
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
                            local sep = " › "
                            for _, item in ipairs(data) do
                                table.insert(parts, (item.icon or "") .. " " .. item.name)
                            end
                            return "  " .. table.concat(parts, sep)
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
                            local map = {
                                ["NORMAL"] = "NORMAL",
                                ["INSERT"] = "INSERT",
                                ["VISUAL"] = "VISUAL",
                                ["V-LINE"] = "V-LINE",
                                ["V-BLOCK"] = "V-BLOCK",
                                ["REPLACE"] = "REPLACE",
                                ["COMMAND"] = "COMMAND",
                                ["TERMINAL"] = "TERMINAL",
                            }
                            return " " .. (map[str] or str:sub(1, 3):upper())
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
                            removed = { fg = colors.red },
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
                                root = require("core.root").root_dir(fname) or false
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
                    {
                        "overseer",
                        label = "",
                        colored = true,
                    },
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
                            local ok, parser =
                                pcall(vim.treesitter.get_parser, buf, nil, { error = false })
                            if ok and parser then
                                return " "
                            end
                            return ""
                        end,
                        color = { fg = colors.green },
                    },
                    { "filesize", cond = conditions.buffer_not_empty, color = { fg = colors.fg } },
                    {
                        function()
                            if not noice_status then
                                return ""
                            end
                            return noice_status.command.get()
                        end,
                        cond = function()
                            return noice_status and noice_status.command.has()
                        end,
                        color = { fg = colors.orange },
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
                    {
                        "location",
                        color = { fg = colors.fg, gui = "bold" },
                    },
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
}
