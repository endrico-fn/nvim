return {
    check = function()
        require("util.sysdeps").check_health()

        local health = vim.health
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
            health.warn("uv tidak ditemukan di PATH (disarankan pasang via pacman -Syu uv)")
        end

        local ruff_path = vim.fn.exepath("ruff")
        local mason_bin = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin")
        local is_mason_ruff = ruff_path ~= "" and ruff_path:sub(1, #mason_bin) == mason_bin
        if ruff_path ~= "" and not is_mason_ruff then
            local ruff_ver = vim.fn.system({ ruff_path, "--version" }):gsub("%s+$", "")
            health.ok("ruff (native): " .. ruff_ver)
        elseif is_mason_ruff then
            health.info(
                "ruff memakai fallback Mason ("
                    .. ruff_path
                    .. "); disarankan pasang via pacman -Syu ruff"
            )
        else
            health.warn("ruff tidak ditemukan (pasang via pacman -Syu ruff atau Mason)")
        end
    end,
}
