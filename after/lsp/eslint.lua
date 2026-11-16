---@type vim.lsp.Config
return {
    root_dir = function(bufnr, on_dir)
        local fname = type(bufnr) == "number" and vim.api.nvim_buf_get_name(bufnr) or bufnr
        if fname == "" then
            return
        end
        local has_eslint = vim.fs.find({
            "eslint.config.js",
            "eslint.config.mjs",
            "eslint.config.cjs",
            ".eslintrc",
            ".eslintrc.js",
            ".eslintrc.cjs",
            ".eslintrc.json",
            ".eslintrc.yaml",
            ".eslintrc.yml",
            "package.json",
        }, { path = fname, upward = true })[1]

        if has_eslint and has_eslint:match("package%.json") then
            local ok, lines = pcall(vim.fn.readfile, has_eslint)
            if not (ok and lines and table.concat(lines, "\n"):find('"eslintConfig"')) then
                has_eslint = vim.fs.find({
                    "eslint.config.js",
                    "eslint.config.mjs",
                    "eslint.config.cjs",
                    ".eslintrc",
                    ".eslintrc.js",
                    ".eslintrc.cjs",
                    ".eslintrc.json",
                }, { path = fname, upward = true })[1]
            end
        end
        if not has_eslint then
            return
        end

        local root = require("util.root").root_dir(fname, {
            "eslint.config.js",
            "eslint.config.mjs",
            "eslint.config.cjs",
            ".eslintrc",
            ".eslintrc.js",
            ".eslintrc.cjs",
            ".eslintrc.json",
            "package.json",
            ".git",
        })
        on_dir(root or vim.fn.fnamemodify(fname, ":h"))
    end,
    settings = {
        workingDirectories = { mode = "auto" },
        format = { enable = false },
        problems = { shortenToSingleLine = false },
        codeAction = {
            disableRuleComment = { enable = true, location = "separateLine" },
            showDocumentation = { enable = true },
        },
    },
}
