local ts = require("util.ts")

---@type vim.lsp.Config
return {
    cmd = function(dispatchers, config)
        local root = (config or {}).root_dir
        local info = ts.is_ts7_workspace(0)
        local bin = (info and info.ok and info.bin) or "tsc"
        if root then
            local local_tsgo = vim.fs.joinpath(root, "node_modules/.bin/tsgo")
            local local_tsc = vim.fs.joinpath(root, "node_modules/.bin/tsc")
            if vim.uv.fs_stat(local_tsgo) then
                bin = local_tsgo
            elseif vim.uv.fs_stat(local_tsc) then
                bin = local_tsc
            end
        end
        return vim.lsp.rpc.start({ bin, "--lsp", "--stdio" }, dispatchers)
    end,
    root_dir = function(bufnr, on_dir)
        local res = ts.is_ts7_workspace(bufnr)
        if res.ok and res.root then
            on_dir(res.root)
        end
    end,
}
