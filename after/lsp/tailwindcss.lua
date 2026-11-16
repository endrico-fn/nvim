---@type vim.lsp.Config
return {
    root_dir = function(bufnr, on_dir)
        local fname = type(bufnr) == "number" and vim.api.nvim_buf_get_name(bufnr) or bufnr
        if fname == "" then
            return
        end
        local root = require("util.root").root_dir(fname, {
            "tailwind.config.js",
            "tailwind.config.ts",
            "tailwind.config.mjs",
            "tailwind.config.cjs",
            "package.json",
            ".git",
        })
        if not root then
            return
        end
        for _, cfg in ipairs({
            "tailwind.config.js",
            "tailwind.config.ts",
            "tailwind.config.mjs",
            "tailwind.config.cjs",
        }) do
            if vim.uv.fs_stat(root .. "/" .. cfg) then
                on_dir(root)
                return
            end
        end
        on_dir(root)
    end,
    filetypes = {
        "html",
        "css",
        "scss",
        "javascript",
        "typescript",
        "javascriptreact",
        "typescriptreact",
        "svelte",
        "astro",
        "vue",
    },
    settings = {
        tailwindCSS = {
            includeLanguages = {
                svelte = "html",
                astro = "html",
                vue = "html",
                typescript = "javascript",
                javascript = "javascript",
            },
            experimental = {
                classRegex = {
                    "class[=:]\\s*[\"']([^\"']*)[\"']",
                    "class:list\\s*=\\s*[\"']([^\"']*)[\"']",
                    "className[=]\\s*[\"']([^\"']*)[\"']",
                    "className[=]\\{`([^`]*)`\\}",
                    "class\\s*=\\s*[\"']([^\"']*)[\"']",
                    "class:([\\w-]+)[=\\s]",
                    { "clsx\\(([^)]*)\\)", "[\"'`]([^\"'`]*)[\"'`]" },
                    { "cx\\(([^)]*)\\)", "[\"'`]([^\"'`]*)[\"'`]" },
                    { "cn\\(([^)]*)\\)", "[\"'`]([^\"'`]*)[\"'`]" },
                    { "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*)[\"'`]" },
                    { "tv\\(([^)]*)\\)", "[\"'`]([^\"'`]*)[\"'`]" },
                    { "variant\\(([^)]*)\\)", "[\"'`]([^\"'`]*)[\"'`]" },
                    { "tw(?:Merge|Join)\\(([^)]*)\\)", "[\"'`]([^\"'`]*)[\"'`]" },
                    { "twMerge\\(([^)]*)\\)", "[\"'`]([^\"'`]*)[\"'`]" },
                },
            },
        },
    },
}
