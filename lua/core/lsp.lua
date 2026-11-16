local M = {}

--- Execute a workspace command via the first LSP client matching `opts.filter`.
--- When `opts.open` is true the request is sent asynchronously via schedule.
function M.execute(opts)
	local filter = opts.filter
	local clients
	if filter then
		clients = vim.lsp.get_clients({ name = filter, bufnr = 0 })
		if #clients == 0 then
			clients = vim.lsp.get_clients({ name = filter })
		end
	else
		clients = vim.lsp.get_clients({ bufnr = 0 })
		if #clients == 0 then
			clients = vim.lsp.get_clients()
		end
	end

	local client
	for _, c in ipairs(clients) do
		if c.server_capabilities.executeCommandProvider then
			client = c
			break
		end
	end
	client = client or clients[1]
	if not client then
		return
	end

	if opts.open then
		-- Async request — tidak blocking. hasil ditangani di callback.
		client:request("workspace/executeCommand", {
			command = opts.command,
			arguments = opts.arguments,
		}, function(err, result)
			if not err and result and opts.title then
				vim.notify(opts.title .. " completed", vim.log.levels.INFO)
			end
		end)
	else
		client:exec_cmd({
			command = opts.command,
			arguments = opts.arguments,
		})
	end
end

--- Trigger a code-action by kind. Returns a closure so each key maps to its own
--- callable — clearer stack traces than a metatable-based dispatch.
local function code_action_by_kind(kind)
	return function()
		local params = vim.lsp.util.make_range_params(0, "utf-16")
		params.context = {
			diagnostics = vim.diagnostic.get(0),
			only = { kind },
			triggerKind = 2,
		}
		vim.lsp.buf.code_action(params)
	end
end

--- Known code-action kinds used across the config.
--- Add new entries here instead of relying on dynamic dispatch.
M["source.organizeImports"] = code_action_by_kind("source.organizeImports")
M["source.addMissingImports.ts"] = code_action_by_kind("source.addMissingImports.ts")
M["source.fixAll.ts"] = code_action_by_kind("source.fixAll.ts")

return M
