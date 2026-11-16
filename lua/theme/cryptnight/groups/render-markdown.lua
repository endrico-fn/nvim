local M = {}

function M.get(c, _)
    return {
        RenderMarkdownH1 = { fg = c.blue, bold = true },
        RenderMarkdownH2 = { fg = c.orange, bold = true },
        RenderMarkdownH3 = { fg = c.yellow, bold = true },
        RenderMarkdownH4 = { fg = c.light_green, bold = true },
        RenderMarkdownH5 = { fg = c.blue, bold = true },
        RenderMarkdownH6 = { fg = c.pink, bold = true },
        RenderMarkdownH1Bg = { bg = c.dim_highlight, bold = true },
        RenderMarkdownH2Bg = { bg = c.dim_highlight, bold = true },
        RenderMarkdownH3Bg = { bg = c.dim_highlight, bold = true },
        RenderMarkdownH4Bg = { bg = c.dim_highlight, bold = true },
        RenderMarkdownH5Bg = { bg = c.dim_highlight, bold = true },
        RenderMarkdownH6Bg = { bg = c.dim_highlight, bold = true },
    }
end

return M
