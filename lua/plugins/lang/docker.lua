vim.filetype.add({
	filename = {
		["docker-compose.yaml"] = "yaml.docker-compose",
		["docker-compose.yml"] = "yaml.docker-compose",
		["compose.yaml"] = "yaml.docker-compose",
		["compose.yml"] = "yaml.docker-compose",
	},
	pattern = {
		[".*docker%-compose%..*%.ya?ml"] = "yaml.docker-compose",
		[".*compose%..*%.ya?ml"] = "yaml.docker-compose",
	},
})

return {
	"neovim/nvim-lspconfig",
	opts = function(_, opts)
		opts.servers = opts.servers or {}

		opts.servers.dockerls = vim.tbl_deep_extend("force", opts.servers.dockerls or {}, {
			root_markers = {
				"Dockerfile",
				".dockerignore",
				".git",
			},
		})
	end,
}
