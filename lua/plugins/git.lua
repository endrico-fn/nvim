return {
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPre", "BufNewFile" },
        keys = {
            {
                "<leader>gg",
                function()
                    Snacks.lazygit()
                end,
                desc = "LazyGit",
            },
            {
                "<leader>gD",
                function()
                    require("gitsigns").diffthis("~")
                end,
                desc = "Diff Buffer vs HEAD~1",
            },
        },
        opts = {
            signs = {
                add = { text = "▎" },
                change = { text = "▎" },
                delete = { text = " " },
                topdelete = { text = " " },
                changedelete = { text = "▎" },
                untracked = { text = "▎" },
            },
            signcolumn = true,
            watch_gitdir = { follow_files = true },
            current_line_blame = false,
            current_line_blame_opts = {
                virt_text = true,
                virt_text_pos = "eol",
                delay = 600,
            },
            preview_config = { border = "single" },
            on_attach = function(bufnr)
                local gs = require("gitsigns")
                local function map(mode, l, r, desc, opts)
                    opts = opts or {}
                    opts.buf = bufnr
                    opts.desc = "gitsigns: " .. desc
                    vim.keymap.set(mode, l, r, opts)
                end

                map("n", "]h", function()
                    if vim.wo.diff then
                        return "]h"
                    end
                    vim.schedule(function()
                        gs.nav_hunk("next")
                    end)
                    return "<Ignore>"
                end, "Next Hunk", { expr = true })

                map("n", "[h", function()
                    if vim.wo.diff then
                        return "[h"
                    end
                    vim.schedule(function()
                        gs.nav_hunk("prev")
                    end)
                    return "<Ignore>"
                end, "Prev Hunk", { expr = true })

                map("n", "<leader>hp", gs.preview_hunk, "Preview Hunk")
                map("n", "<leader>hP", gs.preview_hunk_inline, "Preview Hunk Inline")
                map({ "n", "v" }, "<leader>hs", gs.stage_hunk, "Stage Hunk")
                map("n", "<leader>hS", gs.stage_buffer, "Stage Buffer")
                map({ "n", "v" }, "<leader>hr", gs.reset_hunk, "Reset Hunk")
                map("n", "<leader>hR", gs.reset_buffer, "Reset Buffer")
                map("n", "<leader>hu", function()
                    gs.stage_hunk({ undo = true })
                end, "Undo Stage Hunk")
                map("n", "<leader>hb", gs.blame_line, "Blame Line")
                map("n", "<leader>hB", gs.toggle_current_line_blame, "Toggle Line Blame")
                map("n", "<leader>hd", gs.diffthis, "Diff This")
                map("n", "<leader>hw", gs.toggle_word_diff, "Toggle Word Diff")
                map("n", "<leader>hx", gs.toggle_deleted, "Show/Toggle Deleted")

                map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Select Hunk (Inner)")
                map({ "o", "x" }, "ah", ":<C-U>Gitsigns select_hunk<CR>", "Select Hunk (Around)")
            end,
        },
    },

    {
        "pwntester/octo.nvim",
        cmd = "Octo",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "echasnovski/mini.icons",
        },
        opts = {
            picker = "snacks",
            default_remote = { "upstream", "origin" },
            default_merge_method = "squash",
            enable_builtin = true,
            reaction_viewer_hint_icon = " ",
            user_icon = " ",
            timeline_indent = 2,
            use_timeline_icons = true,
            gh_cmd = "gh",
            ui = { use_statuscolumn = true, use_foldtext = true },
            mappings = {
                pull_request = {
                    checkout_pr = { lhs = "<localleader>po", desc = "checkout PR" },
                    merge_pr = { lhs = "<localleader>pm", desc = "merge commit PR" },
                    show_pr_diff = { lhs = "<localleader>pd", desc = "show PR diff" },
                    approve_pr = { lhs = "<localleader>pa", desc = "approve PR" },
                },
                issue = {
                    close_issue = { lhs = "<localleader>ic", desc = "close issue" },
                    reopen_issue = { lhs = "<localleader>io", desc = "reopen issue" },
                },
            },
        },
        keys = {
            { "<leader>gi", "<cmd>Octo issue list<cr>", desc = "Issues" },
            { "<leader>gp", "<cmd>Octo pr list<cr>", desc = "Pull Requests" },
            { "<leader>go", "<cmd>Octo repo list<cr>", desc = "Repos" },
        },
    },
}
