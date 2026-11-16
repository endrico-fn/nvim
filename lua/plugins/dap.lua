--- Returns a copy of `config` whose `args` prompts the user once per Neovim
--- session (cached). Avoids re-prompting on `run_last` or repeated invocations.
---@param config table  # {type?: string, args?: string[] | (fun(): string[]?)}
local function get_args(config)
	local default_args = type(config.args) == "table" and table.concat(config.args, " ") or ""
	config = vim.deepcopy(config)
	local cached_args = nil
	config.args = function()
		if not cached_args then
			cached_args = vim.fn.expand(vim.fn.input("Run with args: ", default_args))
		end
		return require("dap.utils").splitstr(cached_args)
	end
	return config
end

return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{
			"rcarriga/nvim-dap-ui",
			opts = {
				icons = { expanded = " ", collapsed = " ", current_frame = " " },
				controls = { enabled = false },
				floating = {
					border = "single",
					mappings = { close = { "q", "<Esc>" } },
				},
				layouts = {
					{
						elements = {
							{ id = "scopes", size = 0.35 },
							{ id = "breakpoints", size = 0.20 },
							{ id = "stacks", size = 0.25 },
							{ id = "watches", size = 0.20 },
						},
						size = 40,
						position = "left",
					},
					{
						elements = {
							{ id = "repl", size = 0.5 },
							{ id = "console", size = 0.5 },
						},
						size = 12,
						position = "bottom",
					},
				},
			},
		},
		"nvim-neotest/nvim-nio",
		{ "theHamsta/nvim-dap-virtual-text", opts = {} },
		{
			"jay-babu/mason-nvim-dap.nvim",
			dependencies = "mason.nvim",
			opts = {
				automatic_installation = false, -- pakai ensure_installed di mason.lua saja
				handlers = {
					function(config)
						require("mason-nvim-dap").default_setup(config)
					end,
					python = function() end, -- python di-handle via venv-selector / debugpy custom di python.lua
				},
				ensure_installed = {},
			},
		},
		"jbyuki/one-small-step-for-vimkind",
	},
	keys = {
		{
			"<F5>",
			function()
				require("dap").continue()
			end,
			desc = "Debug: Start/Continue",
		},
		{
			"<F10>",
			function()
				require("dap").step_over()
			end,
			desc = "Debug: Step Over",
		},
		{
			"<F11>",
			function()
				require("dap").step_into()
			end,
			desc = "Debug: Step Into",
		},
		{
			"<leader>db",
			function()
				require("dap").toggle_breakpoint()
			end,
			desc = "Toggle Breakpoint",
		},
		{
			"<leader>dc",
			function()
				require("dap").continue()
			end,
			desc = "Continue",
		},
		{
			"<leader>di",
			function()
				require("dap").step_into()
			end,
			desc = "Step Into",
		},
		{
			"<leader>do",
			function()
				require("dap").step_out()
			end,
			desc = "Step Out",
		},
		{
			"<leader>dO",
			function()
				require("dap").step_over()
			end,
			desc = "Step Over",
		},
		{
			"<leader>dt",
			function()
				require("dap").terminate()
			end,
			desc = "Terminate",
		},
		{
			"<leader>du",
			function()
				require("dapui").toggle()
			end,
			desc = "DAP UI",
		},
		{
			"<leader>de",
			function()
				require("dapui").eval()
			end,
			mode = { "n", "x" },
			desc = "Eval",
		},
		{
			"<F12>",
			function()
				require("dap").step_out()
			end,
			desc = "Debug: Step Out",
		},
		{
			"<leader>dB",
			function()
				require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end,
			desc = "Conditional Breakpoint",
		},
		{
			"<leader>dl",
			function()
				require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
			end,
			desc = "Log Point",
		},
		{
			"<leader>dr",
			function()
				require("dap").restart()
			end,
			desc = "Restart",
		},
		{
			"<leader>da",
			function()
				require("dap").continue({ before = get_args })
			end,
			desc = "Run with Args",
		},
		{
			"<leader>dC",
			function()
				require("dap").run_to_cursor()
			end,
			desc = "Run to Cursor",
		},
		{
			"<leader>dg",
			function()
				require("dap").goto_()
			end,
			desc = "Go to Line (No Execute)",
		},
		{
			"<leader>dj",
			function()
				require("dap").down()
			end,
			desc = "Stack Down",
		},
		{
			"<leader>dk",
			function()
				require("dap").up()
			end,
			desc = "Stack Up",
		},
		{
			"<leader>dL",
			function()
				require("dap").run_last()
			end,
			desc = "Run Last",
		},
		{
			"<leader>dpa",
			function()
				require("dap").pause()
			end,
			desc = "Pause",
		},
		{
			"<leader>dR",
			function()
				require("dap").repl.toggle()
			end,
			desc = "Toggle REPL",
		},
		{
			"<leader>ds",
			function()
				require("dap").session()
			end,
			desc = "Session",
		},
		{
			"<leader>dw",
			function()
				require("dap.ui.widgets").hover()
			end,
			desc = "Widgets",
		},
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")

		-- JS/TS adapters (pwa-node, chrome, msedge) defined in plugins/lang/typescript.lua

		local vscode = require("dap.ext.vscode")
		---@diagnostic disable-next-line: duplicate-set-field
		vscode.json_decode = function(str)
			local ok, result = pcall(vim.json.decode, str)
			if ok then
				return result
			end
			local ok2, sanitized = pcall(require("plenary.json").json_strip_comments, str)
			if ok2 then
				return vim.json.decode(sanitized)
			end
			return vim.json.decode(str)
		end

		vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

		local icons = {
			Stopped = { "󰁕 ", "DiagnosticWarn", "DapStoppedLine" },
			Breakpoint = { " ", "DiagnosticError" },
			BreakpointCondition = { " ", "DiagnosticError" },
			BreakpointRejected = { " ", "DiagnosticError" },
			LogPoint = { ". ", "DiagnosticInfo" },
		}

		for name, sign in pairs(icons) do
			vim.fn.sign_define("Dap" .. name, {
				text = sign[1],
				texthl = sign[2],
				linehl = sign[3],
				numhl = sign[3],
			})
		end

		-- Central codelldb adapter — single source untuk zig/c/cpp (+ fallback rust)
		-- R5: konsolidasi dari rust.lua/zig.lua/clangd.lua. Rust tetap override via rustaceanvim.get_codelldb_adapter.
		do
			local codelldb = vim.fn.exepath("codelldb")
			if codelldb == "" then
				local mason_codelldb = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin", "codelldb")
				if vim.uv.fs_stat(mason_codelldb) then
					codelldb = mason_codelldb
				end
			end
			if codelldb ~= "" and not dap.adapters.codelldb then
				dap.adapters.codelldb = {
					type = "server",
					port = "${port}",
					executable = { command = codelldb, args = { "--port", "${port}" } },
				}
			end
		end

		-- nlua adapter + Lua configs (from lua.lua, uses osv)
		dap.adapters.nlua = function(callback, conf)
			local adapter = {
				type = "server",
				host = conf.host or "127.0.0.1",
				port = conf.port or 8086,
			}
			if conf.start_neovim then
				local dap_run = dap.run --[[@as fun(table)]]
				local osv_started = false
				---@diagnostic disable-next-line: duplicate-set-field
				dap.run = function(c)
					if osv_started then
						return
					end
					osv_started = true
					adapter.port = c.port
					adapter.host = c.host
				end
				require("osv").run_this()
				dap.run = dap_run
			end
			callback(adapter)
		end
		dap.configurations.lua = {
			{
				type = "nlua",
				request = "attach",
				name = "Run this file",
				start_neovim = {},
			},
			{
				type = "nlua",
				request = "attach",
				name = "Attach to running Neovim instance (port = 8086)",
				port = 8086,
			},
		}

		-- Guard: event_terminated dan event_exited bisa fire untuk session yang
		-- sama, sehingga dapui.close() berpotensi dipanggil dua kali. Flag ini
		-- memastikan hanya sekali per session. Direset saat session baru dimulai.
		local dap_ended = false
		dap.listeners.after.event_initialized["dapui_config"] = function()
			dap_ended = false
			dapui.open()
		end
		dap.listeners.before.event_terminated["dapui_config"] = function()
			if not dap_ended then
				dap_ended = true
				dapui.close()
			end
		end
		dap.listeners.before.event_exited["dapui_config"] = function()
			if not dap_ended then
				dap_ended = true
				dapui.close()
			end
		end
	end,
}
