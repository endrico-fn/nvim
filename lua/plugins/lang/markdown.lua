return {
    {
        "MeanderingProgrammer/render-markdown.nvim",
        ft = { "markdown", "markdown.mdx" },
        init = function()
            vim.filetype.add({
                extension = { mdx = "markdown.mdx" },
            })
        end,
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
            -- Jangan render markdown di dalam code block (misal contoh template ```markdown ... ```)
            nested = false,
            code = { sign = false, width = "block", right_pad = 1 },
            heading = { sign = false, icons = {} },
            checkbox = { enabled = true },
            -- Parser latex tidak bisa diinstall: tree-sitter generate di-SIGKILL
            -- (OOM — RAM 3.4GiB, swap penuh). Install `:TSInstall latex` saat
            -- ada headroom memori, lalu hapus baris ini.
            latex = { enabled = false },
        },
    },
    {
        "iamcco/markdown-preview.nvim",
        cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
        ft = { "markdown" },
        build = "cd app && npx --yes yarn install",
    },
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}
            opts.servers.marksman = opts.servers.marksman or {}
        end,
    },
}
