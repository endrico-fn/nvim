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
end

if vim.env.SUDO_USER then
    vim.g.disable_autoformat = true
    vim.notify("Sudo session: auto-format, undofile, clipboard & shada dinonaktifkan demi keamanan", vim.log.levels.WARN)
elseif vim.env.SSH_CLIENT then
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

safe_load("core.options")
safe_load("core.keymaps")
safe_load("core.autocmds")
safe_load("core.sysdeps")

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
vim.api.nvim_exec_autocmds("ColorScheme", { pattern = "cryptnight" })

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "--branch=stable",
        lazyrepo,
        lazypath,
    })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup({
    spec = {
        { import = "plugins" },
        { import = "plugins.lang" },
    },
    defaults = {
        lazy = true,
    },
    checker = {
        enabled = true, -- Otomatis mengecek pembaruan di latar belakang
        notify = true, -- Memunculkan notifikasi (akan diteruskan ke snacks.notifier)
    },
    rocks = {
        enabled = false,
    },
    change_detection = {
        enabled = true,
        notify = false,
    },
    performance = {
        cache = { enabled = true },
        rtp = {
            disabled_plugins = {
                "gzip",
                "man",
                "netrwPlugin",
                "spellfile",
                "tarPlugin",
                "tohtml",
                "tutor",
                "zipPlugin",
            },
        },
    },
    ui = {
        border = "single",
    },
})
