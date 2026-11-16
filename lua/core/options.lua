local opt = vim.opt

-- Buffer & File
opt.undofile = true
opt.undolevels = 10000
opt.swapfile = false
opt.writebackup = false

-- Keamanan ekstra jika sesi sudo / root / sudoedit fallback
if vim.env.SUDO_USER or (vim.uv.getuid and vim.uv.getuid() == 0) then
    opt.undofile = false
    opt.shada = ""
    opt.shadafile = "NONE"
    opt.modeline = false
    opt.clipboard = ""
end
opt.cmdheight = 1
opt.updatetime = 300
opt.timeoutlen = 300
opt.confirm = true
opt.autowrite = true
opt.sessionoptions = "buffers,curdir,tabpages,winsize,help,skiprtp,globals"

-- Display & Line Numbers
opt.number = true
opt.relativenumber = true
opt.numberwidth = 4
opt.scrolloff = 10
opt.sidescrolloff = 8
opt.winminwidth = 5
opt.laststatus = 3
opt.cursorline = true
opt.signcolumn = "yes"
opt.showtabline = 2
opt.pumheight = 15
opt.showmode = false
opt.conceallevel = 2
opt.smoothscroll = true

-- Indentation (smartindent removed: syntax/treesitter indent handles indentation properly)
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.shiftround = true
opt.expandtab = true
opt.breakindent = true

-- Search & Ripgrep
opt.ignorecase = true
opt.smartcase = true
opt.grepformat = "%f:%l:%c:%m"
opt.grepprg = "rg --vimgrep"

-- Completion & Window Split
opt.completeopt = "menuone,noselect,noinsert"
opt.clipboard = "unnamedplus"
opt.linebreak = true
opt.wrap = true
opt.whichwrap = "bs<>[]hl"
opt.spelllang = { "en", "id" }
opt.splitbelow = true
opt.splitright = true
opt.splitkeep = "screen"
opt.winborder = "single" -- border float seragam & tajam untuk semua window float native

-- Native Code Folding (Neovim 0.12 Treesitter foldexpr)
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true
opt.foldtext = ""
opt.fillchars = {
    eob = " ",
    fold = " ",
    foldopen = "",
    foldsep = " ",
    foldclose = "",
    diff = "╱",
}

-- Messages & Diff
opt.formatoptions = "jcroqlnt"
-- Hindari flag 'W' di shortmess agar notifikasi write di noice tetap muncul
opt.shortmess:append({ I = true, c = true, C = true })
opt.diffopt:append("linematch:60")
opt.jumpoptions = "view"
