local root_mod = require("util.root")
local venv = require("util.python")

local function get_python_root(dir)
    local markers = { "pyproject.toml", "uv.lock", "setup.py", "requirements.txt", ".git" }
    local root = (root_mod and root_mod.root_dir(dir, markers)) or dir or vim.uv.cwd()
    for _, m in ipairs(markers) do
        if vim.uv.fs_stat(root .. "/" .. m) then
            return root
        end
    end
    return root
end

return {
    name = "python",
    generator = function(opts, cb)
        local root = get_python_root(opts.dir)
        local has_uv = vim.fn.executable("uv") == 1
        local python_bin = venv.get_python_path()

        local tasks = {}

        -- 1. Run Current File
        local current_file = vim.api.nvim_buf_get_name(0)
        if current_file and current_file:match("%.py$") then
            local rel_file = vim.fn.fnamemodify(current_file, ":.")
            table.insert(tasks, {
                name = "Python: Run Current File (" .. rel_file .. ")",
                desc = "Run current Python script",
                tags = { "RUN", "PYTHON" },
                builder = function()
                    local cmd = has_uv and { "uv", "run", current_file }
                        or { python_bin, current_file }
                    return {
                        cmd = cmd,
                        cwd = root,
                        components = { "default" },
                    }
                end,
            })
        end

        -- 2. Modern uv Workflows (if uv is available)
        if has_uv and vim.uv.fs_stat(root .. "/pyproject.toml") then
            table.insert(tasks, {
                name = "uv: Sync (install dependencies)",
                desc = "Run uv sync to update environment",
                tags = { "UV", "PYTHON" },
                builder = function()
                    return {
                        cmd = { "uv", "sync" },
                        cwd = root,
                        components = { "default", { "on_output_quickfix", open = true } },
                    }
                end,
            })

            table.insert(tasks, {
                name = "uv: Lock (update uv.lock)",
                desc = "Update uv.lock without installing",
                tags = { "UV", "PYTHON" },
                builder = function()
                    return {
                        cmd = { "uv", "lock" },
                        cwd = root,
                        components = { "default" },
                    }
                end,
            })
        end

        -- 3. Pytest
        table.insert(tasks, {
            name = "Python: Run pytest",
            desc = "Run test suite with pytest",
            tags = { "TEST", "PYTHON" },
            builder = function()
                local cmd
                if has_uv and vim.uv.fs_stat(root .. "/pyproject.toml") then
                    cmd = { "uv", "run", "pytest" }
                else
                    cmd = { python_bin, "-m", "pytest" }
                end
                return {
                    cmd = cmd,
                    cwd = root,
                    components = { "default", { "on_output_quickfix", open = true } },
                }
            end,
        })

        -- 4. Ruff Check & Format
        if vim.fn.executable("ruff") == 1 then
            table.insert(tasks, {
                name = "Ruff: Check project",
                desc = "Run ruff check .",
                tags = { "CHECK", "PYTHON" },
                builder = function()
                    return {
                        cmd = { "ruff", "check", "." },
                        cwd = root,
                        components = { "default", { "on_output_quickfix", open = true } },
                    }
                end,
            })
            table.insert(tasks, {
                name = "Ruff: Format project",
                desc = "Run ruff format .",
                tags = { "FORMAT", "PYTHON" },
                builder = function()
                    return {
                        cmd = { "ruff", "format", "." },
                        cwd = root,
                        components = { "default" },
                    }
                end,
            })
        end

        cb(tasks)
    end,
}
