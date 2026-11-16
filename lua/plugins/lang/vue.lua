--- Resolve path ke @vue/typescript-plugin. Priority:
--- 1. Cek actual filesystem (via `vim.uv.fs_stat`) — ini lebih akurat daripada
---    `p:is_installed()` karena Mason mungkin masih menginstall (async) tapi file
---    sudah ada, atau sebaliknya path sudah dihapus manual tapi registry masih
---    mencatat sebagai installed.
--- 2. Fallback ke nil — vtsls akan jalan tanpa vue plugin, user tinggal restart
---    setelah Mason selesai install.
local function get_vue_plugin_path()
	local ok, mr = pcall(require, "mason-registry")
	if not ok then
		return nil
	end
	local ok2, pkg = pcall(mr.get_package, "vue-language-server")
	if not ok2 then
		return nil
	end
	local candidate = pkg:get_install_path() .. "/node_modules/@vue/typescript-plugin"
	if vim.uv.fs_stat(candidate) then
		return candidate
	end
	return nil
end

--- Autocmd: ketika Mason selesai menginstall vue-language-server pada sesi yang
--- sedang berjalan, restart client vtsls agar @vue/typescript-plugin ter-registrasi
--- tanpa perlu restart Neovim.
local augroup = vim.api.nvim_create_augroup("vue_plugin_install", { clear = true })
vim.api.nvim_create_autocmd("User", {
	pattern = "MasonPackageInstalled",
	group = augroup,
	callback = function(args)
		if not (args.data and args.data.package:find("^vue%-language%-server")) then
			return
		end
		vim.schedule(function()
			local vue_path = get_vue_plugin_path()
			if not vue_path then
				return
			end
			for _, client in ipairs(vim.lsp.get_clients({ name = "vtsls" })) do
				local settings = client.config.settings or {}
				settings.vtsls = settings.vtsls or {}
				settings.vtsls.tsserver = settings.vtsls.tsserver or {}
				settings.vtsls.tsserver.globalPlugins = settings.vtsls.tsserver.globalPlugins or {}

				local exists = vim.tbl_contains(
					settings.vtsls.tsserver.globalPlugins,
					{ name = "@vue/typescript-plugin" },
					{ predicate = function(a, b) return a.name == b.name end }
				)
				if not exists then
					table.insert(settings.vtsls.tsserver.globalPlugins, {
						name = "@vue/typescript-plugin",
						location = vue_path,
						languages = { "vue" },
						configNamespace = "typescript",
						enableForWorkspaceTypeScriptVersions = true,
					})
					client.config.settings = settings
					local ok = pcall(client.notify, client, "workspace/didChangeConfiguration", { settings = settings })
				if not ok then
					vim.notify("Gagal update vtsls config untuk Vue plugin. Restart Neovim.", vim.log.levels.WARN, { title = "Vue" })
				end
				end
			end
		end)
	end,
})

return {
	"neovim/nvim-lspconfig",
	opts = function(_, opts)
		opts.servers = opts.servers or {}

		opts.servers.vue_ls = vim.tbl_deep_extend("force", opts.servers.vue_ls or {}, { enabled = false })

		opts.servers.vtsls = opts.servers.vtsls ~= false and (opts.servers.vtsls or {}) or false
		if opts.servers.vtsls then
			opts.servers.vtsls.filetypes = opts.servers.vtsls.filetypes or {}
			table.insert(opts.servers.vtsls.filetypes, "vue")

			local vue_plugin_path = get_vue_plugin_path()
			if vue_plugin_path then
				opts.servers.vtsls.settings = opts.servers.vtsls.settings or {}
				opts.servers.vtsls.settings.vtsls = opts.servers.vtsls.settings.vtsls or {}
				opts.servers.vtsls.settings.vtsls.tsserver = opts.servers.vtsls.settings.vtsls.tsserver or {}
				opts.servers.vtsls.settings.vtsls.tsserver.globalPlugins = opts.servers.vtsls.settings.vtsls.tsserver.globalPlugins or {}
				table.insert(opts.servers.vtsls.settings.vtsls.tsserver.globalPlugins, {
					name = "@vue/typescript-plugin",
					location = vue_plugin_path,
					languages = { "vue" },
					configNamespace = "typescript",
					enableForWorkspaceTypeScriptVersions = true,
				})
			end
		end
	end,
}
