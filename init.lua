if vim.env.SUDO_USER or (vim.uv.getuid and vim.uv.getuid() == 0) then
    vim.g.disable_autoformat = true
    dofile(vim.fn.stdpath("config") .. "/sudoedit.lua")
    vim.notify(
        "Sudo/root session: mode terisolasi aktif (plugin, undofile, clipboard & shada dinonaktifkan)",
        vim.log.levels.WARN
    )
    return
end

vim.loader.enable()

local extra_paths = {
    vim.fn.expand("~/.local/share/fnm/aliases/default/bin"),
    vim.fn.expand("~/.local/bin"),
    vim.fn.expand(
        vim.env.CARGO_HOME and (vim.env.CARGO_HOME .. "/bin") or "~/.local/share/cargo/bin"
    ),
    vim.fn.expand(vim.env.GOPATH and (vim.env.GOPATH .. "/bin") or "~/.local/share/go/bin"),
}
for _, p in ipairs(extra_paths) do
    if vim.fn.isdirectory(p) == 1 and not (vim.env.PATH or ""):find(p, 1, true) then
        vim.env.PATH = p .. ":" .. vim.env.PATH
    end
end

local function safe_load(mod)
    local ok, err = pcall(require, mod)
    if not ok then
        vim.notify("Failed loading " .. mod .. "\n" .. err, vim.log.levels.ERROR)
    end
    return ok, err
end

if vim.env.SSH_CLIENT then
    vim.g.disable_autoformat = true
    vim.notify("SSH session: auto-format disabled (LSP tetap aktif)", vim.log.levels.WARN)
end

if vim.g.neovide then
    vim.o.guifont = "JetBrainsMono Nerd Font:h9.5"
    vim.opt.linespace = -1

    vim.g.neovide_padding_top = 8
    vim.g.neovide_padding_bottom = 8
    vim.g.neovide_padding_left = 8
    vim.g.neovide_padding_right = 8
    vim.g.neovide_cursor_vfx_mode = "wireframe"
end

safe_load("config.options")
safe_load("config.keymaps")
safe_load("config.autocmds")
safe_load("config.lazy")

require("theme.cryptnight").setup({
    transparent = false,
    italic_comments = true,
    underline_links = false,
    group_overrides = {
        Cursor = { fg = "#000000", bg = "#f2f4f8", bold = true },
        LspCodeLens = { fg = "#4c5b5f", italic = true },
    },
})
require("theme.cryptnight").load()
vim.api.nvim_exec_autocmds("ColorScheme", { pattern = "cryptnight-storm" })

local ok_lsp, lsp = pcall(require, "config.lsp")
if ok_lsp then
    lsp.setup()
end
