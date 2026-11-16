return {
	"akinsho/flutter-tools.nvim",
	ft = "dart",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	opts = {
		ui = {
			border = "single",
		},
		decorations = {
			statusline = {
				app_version = true,
				device = true,
			},
		},
		lsp = {
			settings = {
				showTodos = true,
				completeFunctionCalls = true,
				analysisExcludedFolders = {
					vim.fn.expand("$HOME/.pub-cache"),
				},
				renameFilesWithClasses = "always",
				enableSnippets = true,
			},
		},
		debugger = {
			enabled = true,
		},
	},
}
