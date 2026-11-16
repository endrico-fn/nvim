return {
	"neovim/nvim-lspconfig",
	opts = function(_, opts)
		opts.servers = opts.servers or {}
		opts.servers.html = vim.tbl_deep_extend("force", opts.servers.html or {}, {
			filetypes = { "html", "jsp" },
			settings = {
				css = {
					validate = true,
				},
				javascript = {
					format = { enable = false },
				},
			},
		})
	end,
}
