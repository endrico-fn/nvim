return {
	"neovim/nvim-lspconfig",
	opts = function(_, opts)
		opts.servers = opts.servers or {}
		opts.servers.cssls = vim.tbl_deep_extend("force", opts.servers.cssls or {}, {
			-- JANGAN tambah "astro": Astro LSP sudah embed CSS service sendiri.
			-- Double-attach cssls → crash "Cannot read properties of null (validProperties)"
			settings = {
				css = {
					validate = true,
					lint = { unknownAtRules = "ignore" },
				},
				scss = {
					validate = true,
					lint = { unknownAtRules = "ignore" },
				},
				less = {
					validate = true,
					lint = { unknownAtRules = "ignore" },
				},
			},
		})
	end,
}
