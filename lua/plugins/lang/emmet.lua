return {
	"neovim/nvim-lspconfig",
	opts = function(_, opts)
		opts.servers = opts.servers or {}
		opts.servers.emmet_language_server = vim.tbl_deep_extend("force", opts.servers.emmet_language_server or {}, {
			-- filetypes default lsp/emmet_language_server.lua -- tidak override
			init_options = {
				includeLanguages = {
					astro = "html",
					svelte = "html",
					vue = "html",
					["javascript.jsx"] = "javascriptreact",
					["typescript.tsx"] = "typescriptreact",
				},
				showAbbreviationSuggestions = true,
				showExpandedAbbreviation = "always",
				showSuggestionsAsSnippets = true,
			},
		})
	end,
}
