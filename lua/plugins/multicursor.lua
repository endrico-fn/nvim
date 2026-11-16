return {
	"jake-stewart/multicursor.nvim",
	keys = {
		{
			"<A-n>",
			function()
				require("multicursor-nvim").lineAddCursor(1)
			end,
			mode = { "n", "v" },
			desc = "MC: Add Down",
		},
		{
			"<A-p>",
			function()
				require("multicursor-nvim").lineAddCursor(-1)
			end,
			mode = { "n", "v" },
			desc = "MC: Add Up",
		},
		{
			"<leader>n",
			function()
				require("multicursor-nvim").matchAddCursor(1)
			end,
			mode = { "n", "v" },
			desc = "MC: Add Match Forward",
		},
		{
			"<leader>N",
			function()
				require("multicursor-nvim").matchAddCursor(-1)
			end,
			mode = { "n", "v" },
			desc = "MC: Add Match Backward",
		},
		{
			"<A-x>",
			function()
				require("multicursor-nvim").matchSkipCursor(1)
			end,
			mode = { "n", "v" },
			desc = "MC: Skip Match",
		},
		{
			"<leader>A",
			function()
				require("multicursor-nvim").matchAllAddCursors()
			end,
			mode = { "n", "v" },
			desc = "MC: Select All Matches",
		},
		{
			"<A-s>",
			function()
				require("multicursor-nvim").splitCursors()
			end,
			mode = "v",
			desc = "MC: Split Lines",
		},
		{
			"<A-a>",
			function()
				require("multicursor-nvim").alignCursors()
			end,
			mode = { "n", "v" },
			desc = "MC: Align Cursors",
		},
		{
			"<A-[>",
			function()
				require("multicursor-nvim").nextCursor()
			end,
			mode = { "n", "v" },
			desc = "MC: Next Cursor",
		},
		{
			"<A-]>",
			function()
				require("multicursor-nvim").prevCursor()
			end,
			mode = { "n", "v" },
			desc = "MC: Prev Cursor",
		},
		{
			"<A-d>",
			function()
				require("multicursor-nvim").deleteCursor()
			end,
			mode = { "n", "v" },
			desc = "MC: Delete Cursor",
		},
		{
			"<A-e>",
			function()
				local mc = require("multicursor-nvim")
				if mc.cursorsEnabled() then
					mc.disableCursors()
				else
					mc.enableCursors()
				end
			end,
			mode = "n",
			desc = "MC: Toggle Enabled",
		},
		{
			"<Esc>",
			function()
				local mc = require("multicursor-nvim")
				if mc.hasCursors() then
					mc.clearCursors()
				else
					vim.cmd("nohlsearch")
				end
			end,
			mode = "n",
			desc = "MC: Clear Cursors / Highlight",
		},
		{
			"I",
			function()
				require("multicursor-nvim").insertVisual()
			end,
			mode = "v",
			desc = "MC: Insert Visual",
		},
		{
			"A",
			function()
				require("multicursor-nvim").appendVisual()
			end,
			mode = "v",
			desc = "MC: Append Visual",
		},
	},

	config = function()
		local mc = require("multicursor-nvim")

		mc.setup()

		local function set_mc_highlights()
			vim.api.nvim_set_hl(0, "MultiCursorCursor", { link = "Cursor" })
			vim.api.nvim_set_hl(0, "MultiCursorVisual", { link = "Visual" })
			vim.api.nvim_set_hl(0, "MultiCursorSign", { link = "SignColumn" })
			-- Mengubah warna kursor non-aktif menjadi seperti komentar agar beda dari kursor aktif
			vim.api.nvim_set_hl(0, "MultiCursorDisabledCursor", { link = "Comment" })
			vim.api.nvim_set_hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
			vim.api.nvim_set_hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
		end

		set_mc_highlights()
		vim.api.nvim_create_autocmd("ColorScheme", {
			group = vim.api.nvim_create_augroup("mc_hl", { clear = true }),
			callback = set_mc_highlights,
		})
	end,
}
