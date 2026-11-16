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

--- Returns the path inside Mason's `packages/` directory if it exists on disk,
--- avoiding eager loading of `mason-registry` at startup.
---@param pkg string
---@param ... string
---@return string|nil
function M.mason_pkg_path(pkg, ...)
    local p = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "packages", pkg, ...)
    return vim.uv.fs_stat(p) and p or nil
end

--- Returns the project-root for `fname` by walking up from the file looking for
--- `markers`. Integrates ~/Projects (monorepos) and ~/srcpx (scripting tools).
---@param fname? string|number
---@param markers? string[]
---@return string|nil
function M.root_dir(fname, markers)
    local mlist = markers or {}
    local has_js_marker = vim.tbl_contains(mlist, "package.json")
        or vim.tbl_contains(mlist, "tsconfig.json")
        or vim.tbl_contains(mlist, "jsconfig.json")

    local combined = vim.list_extend({}, mlist)
    if has_js_marker then
        for _, m in ipairs(MONOREPO_MARKERS) do
            if not vim.tbl_contains(combined, m) then
                table.insert(combined, m)
            end
        end
    end

    -- Konteks ~/srcpx: deteksi marker scripting tool
    if type(fname) == "string" and fname:find(srcpx_dir, 1, true) == 1 then
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
    if type(fname) == "string" and fname:find(srcpx_dir, 1, true) == 1 then
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

--- Finds project-local TypeScript SDK (`typescript/lib`) including pnpm/Yarn PnP.
---@param fname string|number
---@return string|nil
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
    for _, node_modules in
        ipairs(vim.fs.find("node_modules", {
            path = root,
            upward = false,
            limit = 1,
            type = "directory",
        }) or {})
    do
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

--- Fallback tsdk dari paket Mason `vtsls` tanpa memicu require("mason-registry").
---@return string|nil
function M.vtsls_tsdk()
    local candidates = {
        M.mason_pkg_path(
            "vtsls",
            "node_modules",
            "@vtsls",
            "language-server",
            "node_modules",
            "typescript",
            "lib"
        ),
        M.mason_pkg_path("vtsls", "node_modules", "typescript", "lib"),
    }
    for _, lib in ipairs(candidates) do
        if lib and vim.uv.fs_stat(vim.fs.joinpath(lib, "tsserver.js")) then
            return lib
        end
    end
    return nil
end

return M
