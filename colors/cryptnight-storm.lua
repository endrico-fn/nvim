-- Diperlukan agar :colorscheme cryptnight-storm valid.
-- Telescope colorscheme picker menyimpan vim.g.colors_name dan merestore-nya
-- via :colorscheme saat picker ditutup — tanpa file ini perintah itu error.
require("theme.cryptnight").load({ style = "storm" })
