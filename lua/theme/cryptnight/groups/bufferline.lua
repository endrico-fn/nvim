local M = {}

function M.get(c, opts)
    local tab_bg = opts.transparent and c.none or c.bg
    local fill_bg = opts.transparent and c.bg or c.bg_dark

    return {
        BufferLineFill = { bg = fill_bg },
        BufferLineBufferSelected = { fg = c.fg, bg = tab_bg },

        BufferLineNumbersSelected = { fg = c.fg, bg = tab_bg, bold = true },
        BufferLineTabSeparator = { link = "BufferLineFill" },
        BufferLineTabSeparatorSelected = { link = "BufferLineFill" },
        BufferLineTabSeparatorVisible = { link = "BufferLineFill" },
        BufferLineOffsetSeparator = { link = "BufferLineFill" },
        BufferLineSeparator = { link = "BufferLineFill" },
    }
end

return M
