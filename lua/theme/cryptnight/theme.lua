local M = {}

function M.setup(opts)
	opts = require("theme.cryptnight.config").extend(opts)

	local colors = require("theme.cryptnight.colors").setup(opts)
	local groups = require("theme.cryptnight.groups").setup(colors, opts)

	if vim.g.colors_name then
		vim.cmd("hi clear")
	end

	vim.o.termguicolors = true
	vim.g.colors_name = "cryptnight-" .. opts.style

	for group, hl in pairs(groups) do
		hl = type(hl) == "string" and { link = hl } or hl
		vim.api.nvim_set_hl(0, group, hl)
	end

	if opts.terminal_colors then
		M.terminal(colors)
	end

	return colors, groups, opts
end

function M.terminal(colors)
	local t = colors.terminal
	vim.g.terminal_color_0 = t.black
	vim.g.terminal_color_8 = t.black_bright
	vim.g.terminal_color_7 = t.white
	vim.g.terminal_color_15 = t.white_bright
	vim.g.terminal_color_1 = t.red
	vim.g.terminal_color_9 = t.red_bright
	vim.g.terminal_color_2 = t.green
	vim.g.terminal_color_10 = t.green_bright
	vim.g.terminal_color_3 = t.yellow
	vim.g.terminal_color_11 = t.yellow_bright
	vim.g.terminal_color_4 = t.blue
	vim.g.terminal_color_12 = t.blue_bright
	vim.g.terminal_color_5 = t.magenta
	vim.g.terminal_color_13 = t.magenta_bright
	vim.g.terminal_color_6 = t.cyan
	vim.g.terminal_color_14 = t.cyan_bright
end

function M.terminal_legacy(colors)
	for i = 0, 15 do
		_G["terminal_color_" .. i] = nil
	end
	return M.terminal(colors)
end

return M
