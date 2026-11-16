local M = {}

--- Monorepo markers — only appended when the caller's markers hint at a JS/TS
--- ecosystem (to avoid unnecessary fs-walks for Rust/Go/Zig projects).
local MONOREPO_MARKERS = {
	"pnpm-workspace.yaml",
	"turbo.json",
	"rush.json",
	"lerna.json",
	"nx.json",
	"package.json",
}

local srcpx_dir = vim.fn.expand("~/srcpx")

--- Returns the project-root for `fname` by walking up from the file looking for
--- `markers`. Integrates ~/Projects (monorepos) and ~/srcpx (scripting tools).
function M.root_dir(fname, markers)
	local markers = markers or {}
	local has_js_marker = vim.tbl_contains(markers, "package.json")
		or vim.tbl_contains(markers, "tsconfig.json")
		or vim.tbl_contains(markers, "jsconfig.json")

	local combined = vim.list_extend({}, markers)
	if has_js_marker then
		for _, m in ipairs(MONOREPO_MARKERS) do
			if not vim.tbl_contains(combined, m) then
				table.insert(combined, m)
			end
		end
	end

	-- Konteks ~/srcpx: deteksi marker scripting tool
	if fname and fname:find(srcpx_dir, 1, true) == 1 then
		for _, m in ipairs({ ".srcpx-state.json", "AGENTS.md" }) do
			if not vim.tbl_contains(combined, m) then
				table.insert(combined, m)
			end
		end
	end

	local found = vim.fs.root(fname, combined)
	if found then
		return found
	end

	-- Fallback cerdas untuk subfolder ~/srcpx/<tool> jika tanpa marker
	if fname and fname:find(srcpx_dir, 1, true) == 1 then
		local rel = fname:sub(#srcpx_dir + 2)
		local tool_dir = rel:match("^([^/]+)")
		if tool_dir and tool_dir ~= "" then
			local candidate = srcpx_dir .. "/" .. tool_dir
			if vim.uv.fs_stat(candidate) then
				return candidate
			end
		end
		return srcpx_dir
	end

	return nil
end

function M.find_workspace_tsdk(fname)
	local root = vim.fs.root(fname, {
		"tsconfig.json",
		"jsconfig.json",
		"package.json",
		"pnpm-workspace.yaml",
		".git",
	})
	if not root then
		return nil
	end
	local candidates = {
		root .. "/node_modules/typescript/lib",
		root .. "/node_modules/.pnpm/typescript@*/node_modules/typescript/lib",
	}
	for _, node_modules in ipairs(vim.fs.find("node_modules", { path = root, upward = false, limit = 1, type = "directory" }) or {}) do
		table.insert(candidates, node_modules .. "/typescript/lib")
	end
	local pnp_c = root .. "/.pnp.cjs"
	if vim.uv.fs_stat(pnp_c) then
		for _, tsdk in ipairs(vim.fn.glob(root .. "/.yarn/cache/typescript-*", false, true)) do
			table.insert(candidates, tsdk .. "/node_modules/typescript/lib")
		end
	end
	for _, candidate in ipairs(candidates) do
		local expanded = vim.fn.glob(candidate, false, true)
		if #expanded > 0 then
			local ts_js = expanded[1] .. "/typescript.js"
			if vim.uv.fs_stat(ts_js) then
				return expanded[1]
			end
		end
	end
	return nil
end

--- Fallback tsdk dari paket mason vtsls (struktur npm bisa berubah —
--- resolve dinamis, jangan hardcode path).
function M.vtsls_tsdk()
	local ok, mr = pcall(require, "mason-registry")
	if not ok then
		return nil
	end
	local okp, pkg = pcall(mr.get_package, "vtsls")
	if not okp or not pkg:is_installed() then
		return nil
	end
	local candidates = {
		vim.fs.joinpath(pkg:get_install_path(), "node_modules", "@vtsls", "language-server", "node_modules", "typescript", "lib"),
		vim.fs.joinpath(pkg:get_install_path(), "node_modules", "typescript", "lib"),
	}
	for _, lib in ipairs(candidates) do
		if vim.uv.fs_stat(vim.fs.joinpath(lib, "tsserver.js")) then
			return lib
		end
	end
	return nil
end

return M
