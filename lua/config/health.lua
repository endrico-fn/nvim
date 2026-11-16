return {
    check = function()
        local health = vim.health
        health.start("config: Core Tools & Mason PATH")

        local core_bins = { "git", "rg", "fd", "tree-sitter", "curl", "unzip", "node" }
        for _, bin in ipairs(core_bins) do
            if vim.fn.executable(bin) == 1 then
                health.ok(bin .. " (" .. vim.fn.exepath(bin) .. ")")
            else
                health.warn(bin .. " tidak ditemukan di PATH")
            end
        end

        local mason_bin = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin")
        if vim.fn.isdirectory(mason_bin) == 1 and (vim.env.PATH or ""):find(mason_bin, 1, true) then
            health.ok("Mason bin aktif di PATH: " .. mason_bin)
        else
            health.info("Mason bin akan otomatis disiapkan setelah plugin Mason termuat")
        end

        health.start("python: Environment & Tooling")
        local ok_py, py_mod = pcall(require, "util.python")
        if ok_py then
            health.info("Active Python: " .. py_mod.get_python_path())
            health.info("Active Typechecker: " .. py_mod.active_typechecker())
        else
            health.warn("Modul util.python gagal dimuat")
        end

        if vim.fn.executable("uv") == 1 then
            local uv_ver = vim.fn.system({ "uv", "--version" }):gsub("%s+$", "")
            health.ok("uv: " .. uv_ver)
        else
            health.info("uv tidak ditemukan di PATH (opsional untuk manajemen venv)")
        end

        if vim.fn.executable("ruff") == 1 then
            local ruff_ver = vim.fn.system({ "ruff", "--version" }):gsub("%s+$", "")
            health.ok("ruff: " .. ruff_ver .. " (" .. vim.fn.exepath("ruff") .. ")")
        else
            health.warn("ruff belum ditemukan (otomatis dipasang lewat Mason saat sesi aktif)")
        end
    end,
}
