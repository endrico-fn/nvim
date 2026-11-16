return {
	"neovim/nvim-lspconfig",
	opts = function(_, opts)
		opts.servers = opts.servers or {}
		opts.servers.buf_ls = vim.tbl_deep_extend("force", opts.servers.buf_ls or {}, {
			root_markers = { "buf.yaml", "buf.work.yaml", ".git" },
		})
	end,
}
