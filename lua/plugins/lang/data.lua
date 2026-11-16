return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"b0o/SchemaStore.nvim",
	},
	opts = function(_, opts)
		opts.servers = opts.servers or {}

		opts.servers.jsonls = vim.tbl_deep_extend("force", opts.servers.jsonls or {}, {
			before_init = function(_, config)
				config.settings = config.settings or {}
				config.settings.json = config.settings.json or {}
				config.settings.json.schemas = config.settings.json.schemas or {}
				vim.list_extend(config.settings.json.schemas, require("schemastore").json.schemas())
			end,
			filetypes = { "json", "jsonc", "json5" },
			settings = {
				json = {
					format = { enable = false },
					validate = { enable = true },
				},
			},
		})

		opts.servers.yamlls = vim.tbl_deep_extend("force", opts.servers.yamlls or {}, {
			before_init = function(_, config)
				config.settings = config.settings or {}
				config.settings.yaml = config.settings.yaml or {}
				config.settings.yaml.schemas = vim.tbl_deep_extend(
					"force",
					config.settings.yaml.schemas or {},
					require("schemastore").yaml.schemas()
				)
			end,
			settings = {
				redhat = { telemetry = { enabled = false } },
				yaml = {
					keyOrdering = false,
					-- Formatting via conform (yamlfmt) — single source
					format = { enable = false },
					validate = true,
					completion = true,
					schemaStore = { enable = false, url = "" },
					customTags = {
						"!reference sequence",
						"!secret scalar",
						"!vault scalar",
						"!vault sequence",
						"!vault mapping",
						"!include scalar",
						"!include mapping",
						"!extends scalar",
						"!extends mapping",
						"!binary scalar",
					},
				},
			},
		})
	end,
}
