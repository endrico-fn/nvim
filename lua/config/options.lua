local opt = vim.opt

-- Disable unused remote/legacy providers upfront (speeds startup & fixes :checkhealth)
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0

-- Buffer & File
opt.undofile = true
opt.undolevels = 10000
opt.swapfile = false
opt.writebackup = false

-- Extra defense if running under sudo / root
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
opt.showtabline = 1
opt.pumheight = 15
opt.showmode = false
opt.conceallevel = 2
opt.smoothscroll = true

-- Indentation (Treesitter indent handles structural indentation per-buffer)
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
opt.winborder = "single"

-- Folding defaults (foldmethod & foldexpr applied per-buffer when Treesitter starts)
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
opt.shortmess:append({ I = true, c = true, C = true })
opt.diffopt:append("linematch:60")
opt.jumpoptions = "view"

-- Custom filetypes (compose / mdx)
vim.filetype.add({
    extension = {
        mdx = "markdown.mdx",
    },
    filename = {
        ["docker-compose.yaml"] = "yaml.docker-compose",
        ["docker-compose.yml"] = "yaml.docker-compose",
        ["compose.yaml"] = "yaml.docker-compose",
        ["compose.yml"] = "yaml.docker-compose",
    },
    pattern = {
        [".*docker%-compose%..*%.ya?ml"] = "yaml.docker-compose",
        [".*compose%..*%.ya?ml"] = "yaml.docker-compose",
    },
})
