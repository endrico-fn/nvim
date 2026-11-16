return {
	"L3MON4D3/LuaSnip",
	build = "make install_jsregexp",
	dependencies = {
		"rafamadriz/friendly-snippets",
	},
	keys = {
		{
			"<C-l>",
			function()
				if require("luasnip").jumpable(1) then
					require("luasnip").jump(1)
				end
			end,
			mode = { "i", "s" },
			desc = "LuaSnip: Jump forward",
		},
		{
			"<C-k>",
			function()
				if require("luasnip").jumpable(-1) then
					require("luasnip").jump(-1)
				end
			end,
			mode = { "i", "s" },
			desc = "LuaSnip: Jump backward",
		},
		{
			"<C-y>",
			function()
				if require("luasnip").choice_active() then
					require("luasnip").change_choice(1)
				end
			end,
			mode = { "i", "s" },
			desc = "LuaSnip: Next choice",
		},
		{
			"<C-Y>",
			function()
				if require("luasnip").choice_active() then
					require("luasnip").change_choice(-1)
				end
			end,
			mode = { "i", "s" },
			desc = "LuaSnip: Prev choice",
		},
		{
			"<leader>rs",
			function()
				local c = vim.fn.stdpath("config")
				local luasnip_path = c .. "/luasnippets"
				local from_lua = require("luasnip.loaders.from_lua")
				if vim.fn.isdirectory(luasnip_path) == 1 then
					from_lua.load({ paths = { luasnip_path } })
				end
				vim.notify("Snippets reloaded", vim.log.levels.INFO, { title = "LuaSnip" })
			end,
			mode = { "n" },
			desc = "Reload snippets",
		},
	},
	opts = function()
		local types = require("luasnip.util.types")
		return {
			history = true,
			update_events = "TextChangedI,InsertLeave",
			delete_check_events = "TextChanged",
			enable_autosnippets = true,
			store_selection_keys = "<Tab>",
			ext_opts = {
				[types.choiceNode] = {
					active = {
						virt_text = { { "⟳", "BlinkCmpSource" } },
					},
				},
				[types.insertNode] = {
					active = {
						virt_text = { { "●", "Comment" } },
					},
				},
			},
			ft_func = require("luasnip.extras.filetype_functions").from_pos_or_filetype,
		}
	end,

	config = function(_, opts)
		require("luasnip").setup(opts)
		require("luasnip.loaders.from_lua").lazy_load({
			paths = { vim.fn.stdpath("config") .. "/luasnippets" },
		})
		require("luasnip.loaders.from_vscode").lazy_load()
	end,
}
