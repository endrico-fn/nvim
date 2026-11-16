return {
	"neovim/nvim-lspconfig",
	opts = function(_, opts)
		opts.servers = opts.servers or {}
		opts.servers.astro = vim.tbl_deep_extend("force", opts.servers.astro or {}, {
			init_options = {
				typescript = {
					tsdk = require("core.root").find_workspace_tsdk(vim.fn.getcwd()) or require("core.root").vtsls_tsdk(),
				},
			},
			on_new_config = function(new_config, new_root)
				-- new_root bisa directory (saat initialize) atau file (saat didOpen), coba keduanya + buf name
				local candidates = {}
				if new_root and new_root ~= "" then table.insert(candidates, new_root) end
				local bufname = vim.api.nvim_buf_get_name(0)
				if bufname and bufname ~= "" then table.insert(candidates, bufname) end
				table.insert(candidates, vim.fn.getcwd())
				for _, fname in ipairs(candidates) do
					local workspace_tsdk = require("core.root").find_workspace_tsdk(fname)
					if workspace_tsdk then
						new_config.init_options = vim.tbl_deep_extend("force", new_config.init_options or {}, {
							typescript = { tsdk = workspace_tsdk },
						})
						return
					end
				end
			end,
		})
	end,
}
