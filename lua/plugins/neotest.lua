return {
	"nvim-neotest/neotest",
	dependencies = {
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"marilari88/neotest-vitest",
		"nvim-neotest/neotest-python",
		"fredrikaverpil/neotest-golang",
		"lawrence-laz/neotest-zig",
		"nvim-neotest/neotest-plenary",
	},
	keys = {
		{
			"<leader>tr",
			function()
				require("neotest").run.run()
			end,
			desc = "Run Nearest",
		},
		{
			"<leader>tf",
			function()
				require("neotest").run.run(vim.fn.expand("%"))
			end,
			desc = "Run File",
		},
		{
			"<leader>ts",
			function()
				require("neotest").summary.toggle()
			end,
			desc = "Toggle Summary",
		},
		{
			"<leader>dn",
			function()
				require("neotest").run.run({ strategy = "dap", suite = false })
			end,
			desc = "Debug Nearest Test",
		},
		{
			"<leader>tS",
			function()
				require("neotest").run.stop()
			end,
			desc = "Stop",
		},
		{
			"<leader>tT",
			function()
				require("neotest").run.run({ suite = true })
			end,
			desc = "Run All Tests",
		},
		{
			"<leader>to",
			function()
				require("neotest").output.open({ enter = true, auto_close = true })
			end,
			desc = "Show Output",
		},
		{
			"<leader>ta",
			function()
				require("neotest").run.attach()
			end,
			desc = "Attach",
		},
		{
			"<leader>tl",
			function()
				require("neotest").run.run_last()
			end,
			desc = "Run Last",
		},
		{
			"<leader>tO",
			function()
				require("neotest").output_panel.toggle()
			end,
			desc = "Output Panel",
		},
		{
			"<leader>tw",
			function()
				require("neotest").watch.toggle(vim.fn.expand("%"))
			end,
			desc = "Toggle Watch",
		},
	},
	opts = {
		consumers = {},
		adapters = {
			["neotest-vitest"] = {},
			["rustaceanvim.neotest"] = {},
			["neotest-zig"] = {},
			["neotest-python"] = {
				runner = "pytest",
				dap = { justMyCode = false },
				-- Sinkronisasi python path dengan virtualenv aktif
				python = function()
					return require("core.venv").get_python_path()
				end,
			},
			["neotest-golang"] = {
				go_test_args = { "-p=1", "-count=1" },
				testify_enabled = false,
				runner = "gotestsum",
			},
			["neotest-plenary"] = {},
		},
		status = { virtual_text = true },
		output = { open_on_run = true },
		quickfix = {
			open = function()
				if require("lazy.core.config").plugins["trouble.nvim"] ~= nil then
					require("trouble").open({ mode = "quickfix", focus = false })
				else
					vim.cmd("copen")
				end
			end,
		},
	},
	config = function(_, opts)
		local neotest_ns = vim.api.nvim_create_namespace("neotest")
		vim.diagnostic.config({
			virtual_text = {
				format = function(diagnostic)
					local message = diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
					return message
				end,
			},
		}, neotest_ns)

		opts.consumers.overseer = require("neotest.consumers.overseer")

		if require("lazy.core.config").plugins["trouble.nvim"] ~= nil then
			opts.consumers.trouble = function(client)
				-- consumer_client (neotest >= 2026-08) melarang READ listeners;
				-- assignment langsung sudah append per-consumer-name tanpa
				-- menimpa consumer lain (mis. overseer).
				client.listeners.results = function(adapter_id, results, partial)
					if partial then
						return
					end
					local tree = assert(client:get_position(nil, { adapter = adapter_id }))
					local failed = 0
					for pos_id, result in pairs(results) do
						if result.status == "failed" and tree:get_key(pos_id) then
							failed = failed + 1
						end
					end
					vim.schedule(function()
						local trouble = require("trouble")
						if trouble.is_open() then
							trouble.refresh()
							if failed == 0 then
								trouble.close()
							end
						end
					end)
					return {}
				end
			end
		end

		if opts.adapters then
			local adapters = {}
			for name, config in pairs(opts.adapters) do
				if type(name) == "number" then
					if type(config) == "string" then
						config = require(config)
					end
					table.insert(adapters, config)
				else
					local adapter = require(name)
					if type(adapter) == "table" and type(adapter.setup) == "function" then
						adapter.setup(config)
						table.insert(adapters, adapter)
					elseif type(adapter) == "function" then
						table.insert(adapters, adapter(config))
					else
						table.insert(adapters, adapter)
					end
				end
			end
			opts.adapters = adapters
		end

		require("neotest").setup(opts)
	end,
}
