return {
	"neovim/nvim-lspconfig",
	opts = function(_, opts)
		opts.servers = opts.servers or {}
		opts.servers.taplo = vim.tbl_deep_extend("force", opts.servers.taplo or {}, {
			root_markers = {
				".taplo.toml",
				"taplo.toml",
				"Cargo.toml",
				"pyproject.toml",
				"deno.json",
				"wrangler.toml",
				".git",
			},
		})
	end,
}
