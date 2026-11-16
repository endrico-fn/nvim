local function is_sqlite(path)
    local ok, handle = pcall(vim.uv.fs_open, path, "r", 438)
    if not ok or not handle then
        return false
    end
    local header = vim.uv.fs_read(handle, 16, 0)
    vim.uv.fs_close(handle)
    return header and header:find("^SQLite format 3") ~= nil
end

---@type vim.lsp.Config
return {
    before_init = function(_, config)
        local buf = vim.api.nvim_get_current_buf()
        if not buf or not vim.api.nvim_buf_is_valid(buf) then
            return
        end
        local dbpath = vim.b[buf].sqlite_path or vim.api.nvim_buf_get_name(buf)
        if not dbpath or dbpath == "" then
            return
        end
        local is_ext = vim.endswith(dbpath, ".db")
            or vim.endswith(dbpath, ".sqlite")
            or vim.endswith(dbpath, ".sqlite3")
            or vim.endswith(dbpath, ".sqlitedb")
        if not is_ext or not is_sqlite(dbpath) then
            return
        end
        config.settings = vim.tbl_deep_extend("force", config.settings or {}, {
            sqls = {
                connections = {
                    {
                        alias = vim.fn.fnamemodify(dbpath, ":t"),
                        driver = "sqlite3",
                        dataSourceName = dbpath,
                    },
                },
            },
        })
    end,
}
