return {
    "akinsho/bufferline.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
        "echasnovski/mini.icons",
    },

    keys = {
        { "[b", "<cmd>BufferLineCyclePrev<CR>", desc = "Prev Buffer" },
        { "]b", "<cmd>BufferLineCycleNext<CR>", desc = "Next Buffer" },
        { "[B", "<cmd>BufferLineMovePrev<CR>", desc = "Move Buffer Left" },
        { "]B", "<cmd>BufferLineMoveNext<CR>", desc = "Move Buffer Right" },
        { "<Tab>", "<cmd>BufferLineCycleNext<CR>", desc = "Next Buffer" },
        { "<S-Tab>", "<cmd>BufferLineCyclePrev<CR>", desc = "Prev Buffer" },
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
                numbers = function(opts)
                    -- Menampilkan nomor ordinal sebagai superscript (¹ ² ³) yang bersih
                    return opts.raise(opts.ordinal)
                end,
                style_preset = require("bufferline").style_preset.no_italic,
                close_command = close_buf,
                right_mouse_command = close_buf,
                buffer_close_icon = "✗",
                show_close_icon = false,
                diagnostics = "nvim_lsp",
                -- Deterministik & urutan konsisten (Error -> Warn -> Info -> Hint)
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
                -- Format resmi untuk mematikan karakter separator bawaan
                separator_style = { "", "" },
                enforce_regular_tabs = true,
                sort_by = "insert_after_current",
                offsets = {
                    {
                        filetype = "snacks_layout_box",
                        text = function()
                            -- Menampilkan nama root direktori proyek secara dinamis
                            return "󰉓 " .. vim.fs.basename(vim.uv.cwd())
                        end,
                        highlight = "Directory",
                        text_align = "left",
                        separator = true,
                    },
                    {
                        filetype = "DiffviewFiles",
                        text = "Diff View",
                        text_align = "center",
                        separator = true,
                    },
                },
                -- Filter buffer utilitas agar tabline tidak berantakan
                custom_filter = function(bufnr)
                    local ft = vim.bo[bufnr].filetype
                    if ft == "qf" or ft == "gitcommit" or ft:find("^snacks_") then
                        return false
                    end
                    return true
                end,
                -- Home row pick characters untuk kecepatan navigasi tangan
                pick = {
                    alphabet = "asdfjklghweruio",
                },
            },
        }
    end,
}
