local Util = require("theme.cryptnight.util")

local M = {}

---@type table<string, Palette|fun(opts):Palette>
M.styles = setmetatable({}, {
	__index = function(_, style)
		return vim.deepcopy(require("theme.cryptnight.colors." .. style))
	end,
})

function M.setup(opts)
	opts = require("theme.cryptnight.config").extend(opts)

	local palette = M.styles[opts.style]
	if type(palette) == "function" then
		palette = palette(opts)
	end

	---@class ColorScheme: Palette
	local c = palette

	Util.bg = c.bg
	Util.fg = c.fg

	c.none = "NONE"
	c.normal = "NONE"

	c.bg_dark           = "#131517"
	c.bg_highlight      = "#222222"
	c.bg_popup          = "#121212"
	c.fg_gutter         = "#3b4261"
	c.fg_sidebar        = c.fg
	c.fg_float          = c.fg
	c.black             = Util.blend_bg(c.bg, 0.8, "#000000")
	c.border            = c.bg_dark
	c.border_highlight  = Util.blend_bg(c.blue, 0.8)

	c.bg_statusline = c.bg_dark
	c.bg_sidebar = opts.styles.sidebars == "transparent" and c.none
		or opts.styles.sidebars == "dark" and c.bg_dark
		or c.bg
	c.bg_float = opts.styles.floats == "transparent" and c.none
		or opts.styles.floats == "dark" and c.bg_dark
		or c.bg
	c.bg_visual         = Util.blend_bg(c.blue, 0.4)
	c.bg_search         = "#2a4140"

	c.fg_dark           = "#b0b2b6"
	c.comment           = "#4c5b5f"

	c.selection         = "#252929"
	c.line_number       = "#b0b2b6"
	c.cursor_dark_dark  = "#222222"
	c.cursor_dark       = "#2e2e2e"
	c.cursor_light      = "#b0b2b6"
	c.context           = "#2e2e2e"
	c.context_current   = "#3e605f"
	c.fold_bg           = "#1c1c1c"
	c.suggestion        = "#4c5b5f"
	c.dim_highlight     = "#2e2e2e"
	c.gray              = "#b0b2b6"
	c.medium_blue       = "#1f77ad"
	c.dark_blue         = "#284874"
	c.disabled_blue     = "#4c5b5f"
	c.medium_cyan       = "#167479"
	c.blue_green        = "#74b3a3"
	c.light_green       = "#25be6a"
	c.light_red         = "#ff6fad"
	c.dark_yellow       = "#a09d25"
	c.ui_orange         = "#f28b25"

	c.error             = c.red
	c.todo              = c.blue
	c.warning           = c.yellow
	c.info              = c.accent_blue
	c.hint              = c.accent_blue

	c.diff = {
		add             = "#4B5632",
		delete          = "#6F1313",
		change          = "#4B1818",
		text            = "#6F1313",
	}

	c.git = {
		add             = "#25be6a",
		modified        = "#f4da86",
		delete          = "#f03365",
		renamed         = "#73c991",
		untracked       = "#73c991",
		ignored         = "#4c5b5f",
		stage_mod       = "#f4da86",
		stage_del       = "#f03365",
		conflict        = "#f03365",
		submodule       = "#33B1FF",
	}

	c.rainbow = {
		c.blue, c.yellow_orange, c.blue_green, c.medium_cyan,
		c.violet, c.pink, c.orange, c.red,
	}

	c.terminal = {
		black           = c.black,
		black_bright    = c.suggestion,
		red             = c.red,
		red_bright      = Util.brighten(c.red),
		green           = c.light_green,
		green_bright    = Util.brighten(c.light_green),
		yellow          = c.yellow,
		yellow_bright   = Util.brighten(c.yellow),
		blue            = c.blue,
		blue_bright     = Util.brighten(c.blue),
		magenta         = c.pink,
		magenta_bright  = Util.brighten(c.pink),
		cyan            = c.cyan,
		cyan_bright     = Util.brighten(c.cyan),
		white           = c.fg_dark,
		white_bright    = c.fg,
	}

	opts.on_colors(c)

	return c, opts
end

function M.get_colors(opts)
	return M.setup(opts or {})
end

M.styles.storm = require("theme.cryptnight.colors.storm")

return M
