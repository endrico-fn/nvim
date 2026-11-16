local Util = require("theme.cryptnight.util")

local M = {}

function M.get(c, opts)
    local ret = {
        ["@comment"] = "Comment",
        ["@comment.error"] = { fg = c.error, bold = true },
        ["@comment.warning"] = { fg = c.yellow_orange, bold = true },
        ["@comment.note"] = { fg = c.blue_green, bold = true },
        ["@comment.todo"] = "Todo",
        ["@comment.info"] = { fg = c.info },
        ["@comment.hint"] = { fg = c.hint },
        ["@comment.documentation"] = { fg = c.comment, italic = true },

        ["@annotation"] = { fg = c.yellow },
        ["@attribute"] = { fg = c.yellow },
        ["@attribute.builtin"] = { fg = c.blue_green },

        ["@boolean"] = { fg = c.light_red },
        ["@character"] = { fg = c.orange },
        ["@character.special"] = "SpecialChar",
        ["@character.printf"] = "SpecialChar",

        ["@constant"] = { fg = c.accent_blue },
        ["@constant.builtin"] = { fg = c.blue },
        ["@constant.macro"] = { fg = c.blue_green },

        ["@constructor"] = { fg = c.blue },
        ["@constructor.tsx"] = { fg = c.blue_green },
        ["@constructor.python"] = { fg = c.blue_green },

        ["@function"] = "Function",
        ["@function.builtin"] = { fg = c.blue_green },
        ["@function.call"] = "@function",
        ["@function.macro"] = { fg = c.blue_green },
        ["@function.method"] = "Function",
        ["@function.method.call"] = "@function.method",

        ["@keyword"] = { fg = c.blue, style = opts.styles.keywords },
        ["@keyword.debug"] = "Debug",
        ["@keyword.conditional"] = "Conditional",
        ["@keyword.conditional.ternary"] = "@keyword.conditional",
        ["@keyword.repeat"] = "Repeat",
        ["@keyword.return"] = "@keyword",
        ["@keyword.exception"] = "Exception",
        ["@keyword.import"] = "Include",
        ["@keyword.storage"] = "StorageClass",
        ["@keyword.type"] = { fg = c.blue },
        ["@keyword.function"] = { fg = c.pink, style = opts.styles.functions },
        ["@keyword.directive"] = "PreProc",
        ["@keyword.directive.define"] = "Define",
        ["@keyword.operator"] = "@operator",
        ["@keyword.modifier"] = { fg = c.pink },
        ["@keyword.coroutine"] = "@keyword",

        ["@label"] = { fg = c.cyan },

        ["@markup"] = "@none",
        ["@markup.strong"] = { bold = true, fg = c.blue },
        ["@markup.emphasis"] = { italic = true },
        ["@markup.italic"] = { italic = true },
        ["@markup.underline"] = { underline = true, fg = c.yellow_orange },
        ["@markup.strikethrough"] = { strikethrough = true },
        ["@markup.heading"] = "Title",
        ["@markup.environment"] = "Macro",
        ["@markup.environment.name"] = "Type",
        ["@markup.raw"] = { fg = c.fg },
        ["@markup.raw.markdown"] = { fg = c.orange },
        ["@markup.raw.markdown_inline"] = { fg = c.orange },
        ["@markup.raw.block"] = "@markup.raw",
        ["@markup.link"] = { fg = c.cyan },
        ["@markup.link.label"] = { fg = c.cyan, underline = opts.underline_links },
        ["@markup.link.label.symbol"] = "Identifier",
        ["@markup.link.url"] = "Underlined",
        ["@markup.list"] = { fg = c.cyan },
        ["@markup.list.checked"] = { fg = c.blue_green },
        ["@markup.list.unchecked"] = { fg = c.blue },
        ["@markup.list.markdown"] = { fg = c.orange, bold = true },
        ["@markup.quote"] = { fg = c.suggestion, italic = true },
        ["@markup.math"] = "Special",

        ["@module"] = { fg = c.blue_green },
        ["@module.builtin"] = { fg = c.red },

        ["@none"] = {},
        ["@conceal"] = {},
        ["@spell"] = {},
        ["@nospell"] = {},

        ["@number"] = "Number",
        ["@number.float"] = "Float",

        ["@operator"] = { fg = c.fg },

        ["@property"] = { fg = c.cyan },

        ["@punctuation.bracket"] = { fg = c.fg },
        ["@punctuation.delimiter"] = "Delimiter",
        ["@punctuation.special"] = { fg = c.fg },
        ["@punctuation.special.markdown"] = { fg = c.orange },

        ["@string"] = "String",
        ["@string.documentation"] = { fg = c.blue_green, italic = true },
        ["@string.escape"] = { fg = c.orange, bold = true },
        ["@string.regexp"] = { fg = c.orange },
        ["@string.special"] = { fg = c.orange },
        ["@string.special.path"] = { fg = c.cyan },
        ["@string.special.url"] = "Underlined",

        ["@structure"] = { fg = c.cyan },

        ["@tag"] = { fg = c.blue },
        ["@tag.builtin"] = { fg = c.blue },
        ["@tag.delimiter"] = { fg = c.gray },
        ["@tag.delimiter.tsx"] = { fg = Util.blend_bg(c.blue, 0.7) },
        ["@tag.attribute"] = { fg = c.cyan },
        ["@tag.tsx"] = { fg = c.red },
        ["@tag.javascript"] = { fg = c.red },

        ["@type"] = "Type",
        ["@type.builtin"] = { fg = c.accent_blue },
        ["@type.qualifier"] = { fg = c.blue },
        ["@type.definition"] = "Typedef",

        ["@variable"] = { fg = c.cyan, style = opts.styles.variables },
        ["@variable.builtin"] = { fg = c.cyan },
        ["@variable.member"] = { fg = c.cyan },
        ["@variable.parameter"] = { fg = c.cyan },
        ["@variable.parameter.builtin"] = { fg = c.cyan },
        ["@variable.parameter.reference"] = { fg = c.cyan },

        ["@diff.plus"] = "DiffAdd",
        ["@diff.minus"] = "DiffDelete",
        ["@diff.delta"] = "DiffChange",
    }

    for i, color in ipairs(c.rainbow) do
        ret["@markup.heading." .. i .. ".markdown"] = { fg = color, bold = true }
    end

    return ret
end

return M
