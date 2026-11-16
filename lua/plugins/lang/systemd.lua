return {
	"neovim/nvim-lspconfig",
	opts = function(_, opts)
		opts.servers = opts.servers or {}
		-- systemd_lsp: autocompletion + hover docs untuk systemd unit directives
		-- (ExecStart, WantedBy, After, Type, dll)
		opts.servers.systemd_lsp = opts.servers.systemd_lsp or {}
	end,
}
