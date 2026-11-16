return {
	"neovim/nvim-lspconfig",
	opts = function(_, opts)
		opts.servers = opts.servers or {}
		opts.servers.bashls = vim.tbl_deep_extend("force", opts.servers.bashls or {}, {
			root_markers = { ".git", ".srcpx-state.json", "AGENTS.md", "Makefile" },
			settings = {
				bashIde = {
					-- Nonaktifkan shellcheck internal bashls agar tidak duplikat diagnostik dengan nvim-lint
					shellcheckPath = "",
				},
			},
		})
	end,
}
