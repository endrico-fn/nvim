-- ~/.config/nvim/sudoedit.lua
-- Konfigurasi minimal, terisolasi, dan aman untuk sudoedit (tanpa plugin, tanpa kebocoran data)

local opt = vim.opt

-- ============================================================================
-- 1. KEAMANAN DATA & PRIVASI (Cegah kebocoran data sensitif ke disk user)
-- ============================================================================
opt.undofile = false -- JANGAN simpan riwayat undo ke ~/.local/state/nvim/undo/
opt.swapfile = false -- Tidak membuat file .swp di disk
opt.backup = false -- Tidak membuat file backup
opt.writebackup = false
opt.shada = "" -- JANGAN simpan riwayat command/search/register ke main.shada
opt.shadafile = "NONE" -- Pastikan ShaDa benar-benar dinonaktifkan
opt.modeline = false -- Cegah eksekusi modeline berbahaya dari file yang diedit
opt.exrc = false -- Cegah eksekusi .nvim.lua / .exrc lokal di direktori kerja
opt.secure = true -- Batasi perintah berbahaya dari file eksternal
opt.loadplugins = false -- Jangan load plugin startup otomatis
opt.clipboard = "" -- JANGAN sync otomatis ke clipboard desktop (Wayland/X11)

-- ============================================================================
-- 2. TAMPILAN & KENYAMANAN EDITOR
-- ============================================================================
opt.number = true
opt.relativenumber = false
opt.cursorline = true
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.wrap = true
opt.signcolumn = "no"
opt.termguicolors = true

-- Statusline sederhana & informatif: [File] [Modified] [RO] [Line/Col]
opt.laststatus = 2
opt.statusline = " %f %m%r %= %l/%L:%c "

-- Syntax highlighting & indent bawaan Neovim (tanpa LSP/Treesitter eksternal)
vim.cmd("syntax on")
vim.cmd("filetype plugin indent on")

-- Keymap dasar bantuan
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { silent = true, desc = "Clear highlight" })
