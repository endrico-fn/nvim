-- Ambil warna dengan opts aktif agar group_overrides / color_overrides dari
-- require("theme.cryptnight").setup({...}) di init.lua ikut ter-apply.
-- Fallback ke get_colors() tanpa opts jika config belum ter-init (mis. standalone).
local config_ok, config = pcall(require, "theme.cryptnight.config")
local c = require("theme.cryptnight.colors").get_colors(config_ok and config.options or nil)

local M = {}

M.normal = {
    a = { fg = c.bg, bg = c.blue, gui = "bold" },
    b = { fg = c.fg, bg = c.fold_bg },
    c = { fg = c.fg, bg = "NONE" },
    x = { fg = c.fg, bg = c.fold_bg },
    z = { fg = c.bg, bg = c.blue, gui = "bold" },
}

M.insert = {
    a = { fg = c.bg, bg = c.light_green, gui = "bold" },
    b = { fg = c.fg, bg = c.fold_bg },
    c = { fg = c.fg, bg = "NONE" },
}

M.visual = {
    a = { fg = c.bg, bg = c.pink, gui = "bold" },
    b = { fg = c.fg, bg = c.fold_bg },
    c = { fg = c.fg, bg = "NONE" },
}

M.replace = {
    a = { fg = c.bg, bg = c.red, gui = "bold" },
    b = { fg = c.fg, bg = c.fold_bg },
    c = { fg = c.fg, bg = "NONE" },
}

M.command = {
    a = { fg = c.bg, bg = c.yellow, gui = "bold" },
    b = { fg = c.fg, bg = c.fold_bg },
    c = { fg = c.fg, bg = "NONE" },
}

M.terminal = {
    a = { fg = c.bg, bg = c.cyan, gui = "bold" },
    b = { fg = c.fg, bg = c.fold_bg },
    c = { fg = c.fg, bg = "NONE" },
}

M.select = {
    a = { fg = c.bg, bg = c.violet, gui = "bold" },
    b = { fg = c.fg, bg = c.fold_bg },
    c = { fg = c.fg, bg = "NONE" },
    x = { fg = c.fg, bg = c.fold_bg },
    y = { fg = c.line_number, bg = c.bg_dark },
    z = { fg = c.bg, bg = c.violet, gui = "bold" },
}

M.inactive = {
    a = { fg = c.suggestion, bg = "NONE" },
    b = { fg = c.suggestion, bg = "NONE" },
    c = { fg = c.suggestion, bg = "NONE" },
    x = { fg = c.suggestion, bg = "NONE" },
    y = { fg = c.suggestion, bg = "NONE" },
    z = { fg = c.suggestion, bg = "NONE" },
}

return M
