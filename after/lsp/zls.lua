---@type vim.lsp.Config
return {
    init_options = {
        enable_inlay_hints = true,
        enable_snippets = true,
        semantic_tokens = true,
        warn_style = true,
        highlight_builtins = true,
        build_runner = "check",
    },
}
