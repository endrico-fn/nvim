local M = {}

local _cached_python = nil

local function exepath_nonempty(cmd)
    local p = vim.fn.exepath(cmd)
    return (p and p ~= "") and p or nil
end

--- Validates whether a file path exists and is a regular file.
---@param path? string
---@return boolean
local function is_executable_file(path)
    if not path or path == "" then
        return false
    end
    local stat = vim.uv.fs_stat(path)
    return stat ~= nil and stat.type == "file"
end

--- Resolves the root directory of the current Python project.
---@param buf? number
---@return string
function M.get_project_root(buf)
    buf = (buf and buf ~= 0) and buf or vim.api.nvim_get_current_buf()
    local fname = vim.api.nvim_buf_get_name(buf)
    if fname and fname ~= "" then
        local ok, root_mod = pcall(require, "util.root")
        local markers = {
            "pyproject.toml",
            "uv.lock",
            "setup.py",
            "setup.cfg",
            "requirements.txt",
            "Pipfile",
            ".git",
        }
        if ok and root_mod.root_dir then
            local r = root_mod.root_dir(fname, markers)
            if r then
                return r
            end
        end
        local found = vim.fs.root(fname, markers)
        if found then
            return found
        end
        return vim.fs.dirname(fname)
    end
    return vim.fn.getcwd()
end

--- Returns the active Python executable path.
---@param opts? { refresh?: boolean, buf?: number }
---@return string
function M.get_python_path(opts)
    opts = opts or {}
    if not opts.refresh and _cached_python and is_executable_file(_cached_python) then
        return _cached_python
    end

    -- 1. Check VIRTUAL_ENV environment variable
    local venv_env = os.getenv("VIRTUAL_ENV")
    if venv_env and venv_env ~= "" then
        local candidate = venv_env .. "/bin/python"
        if is_executable_file(candidate) then
            _cached_python = candidate
            return candidate
        end
    end

    -- 2. Check local project root (.venv, venv, env, .env)
    local root = M.get_project_root(opts.buf)
    local dirs = { ".venv", "venv", "env", ".env" }
    for _, dir in ipairs(dirs) do
        local candidate = root .. "/" .. dir .. "/bin/python"
        if is_executable_file(candidate) then
            _cached_python = candidate
            return candidate
        end
    end

    -- 3. Walk cwd if different from project root
    local cwd = vim.fn.getcwd()
    if cwd ~= root then
        for _, dir in ipairs(dirs) do
            local candidate = cwd .. "/" .. dir .. "/bin/python"
            if is_executable_file(candidate) then
                _cached_python = candidate
                return candidate
            end
        end
    end

    -- 4. Fallback to system Python
    local sys_python = exepath_nonempty("python3") or exepath_nonempty("python") or "python3"
    _cached_python = sys_python
    return _cached_python
end

--- Updates the active Python path, notifies LSPs (basedpyright / ty), and fires User event.
---@param bin_path string
function M.set_python_path(bin_path)
    if not is_executable_file(bin_path) then
        vim.notify("Path Python tidak valid: " .. tostring(bin_path), vim.log.levels.ERROR, {
            title = "Python Venv",
        })
        return
    end

    _cached_python = bin_path
    local venv_dir = vim.fs.dirname(vim.fs.dirname(bin_path))
    local bin_dir = vim.fs.dirname(bin_path)

    vim.env.VIRTUAL_ENV = venv_dir
    if not (vim.env.PATH or ""):find(bin_dir, 1, true) then
        vim.env.PATH = bin_dir .. ":" .. (vim.env.PATH or "")
    end

    -- Update basedpyright LSP clients using Neovim 0.12 client:notify()
    for _, client in ipairs(vim.lsp.get_clients({ name = "basedpyright" })) do
        client.config.settings = vim.tbl_deep_extend("force", client.config.settings or {}, {
            python = { pythonPath = bin_path },
        })
        client:notify("workspace/didChangeConfiguration", {
            settings = client.config.settings,
        })
    end

    -- Restart ty if currently active so it picks up updated VIRTUAL_ENV
    if #vim.lsp.get_clients({ name = "ty" }) > 0 then
        pcall(vim.cmd, "lsp restart ty")
    end

    pcall(function()
        vim.api.nvim_exec_autocmds("User", {
            pattern = "PythonVenvChanged",
            data = {
                python = bin_path,
                venv = venv_dir,
            },
        })
    end)

    vim.notify("VirtualEnv aktif: " .. bin_path, vim.log.levels.INFO, {
        title = "Python Venv",
    })
end

--- Discovers virtual environments across project and standard directories.
---@return table[] list of { text: string, bin: string, path: string, is_active: boolean }
function M.find_venvs()
    local seen = {}
    local results = {}
    local current_bin = M.get_python_path()

    local function add_candidate(label, bin_path, base_path)
        if not is_executable_file(bin_path) or seen[bin_path] then
            return
        end
        seen[bin_path] = true
        local is_active = (bin_path == current_bin)
        table.insert(results, {
            text = (is_active and "● " or "  ") .. label,
            bin = bin_path,
            path = base_path or vim.fs.dirname(vim.fs.dirname(bin_path)),
            is_active = is_active,
        })
    end

    local venv_env = os.getenv("VIRTUAL_ENV")
    if venv_env and venv_env ~= "" then
        add_candidate(
            "Env ($VIRTUAL_ENV): " .. vim.fs.basename(venv_env),
            venv_env .. "/bin/python",
            venv_env
        )
    end

    local root = M.get_project_root()
    for _, dir in ipairs({ ".venv", "venv", "env", ".env" }) do
        local candidate_dir = root .. "/" .. dir
        local candidate_bin = candidate_dir .. "/bin/python"
        if is_executable_file(candidate_bin) then
            add_candidate("Project (" .. dir .. ")", candidate_bin, candidate_dir)
        end
    end

    local home = vim.fn.expand("~")
    local scan_roots = {
        { name = "virtualenvs", path = home .. "/.virtualenvs" },
        { name = "poetry", path = home .. "/.cache/pypoetry/virtualenvs" },
        { name = "uv", path = home .. "/.local/share/uv/tools" },
    }
    for _, src in ipairs(scan_roots) do
        if vim.fn.isdirectory(src.path) == 1 then
            local handle = vim.uv.fs_scandir(src.path)
            if handle then
                while true do
                    local name, typ = vim.uv.fs_scandir_next(handle)
                    if not name then
                        break
                    end
                    if typ == "directory" then
                        local bin = src.path .. "/" .. name .. "/bin/python"
                        if is_executable_file(bin) then
                            add_candidate(src.name .. ": " .. name, bin, src.path .. "/" .. name)
                        end
                    end
                end
            end
        end
    end

    local sys_python = exepath_nonempty("python3") or "/usr/bin/python3"
    if is_executable_file(sys_python) then
        add_candidate("System Python (python3)", sys_python, "/usr")
    end

    return results
end

--- Displays an interactive virtual environment selector.
function M.select_venv()
    local candidates = M.find_venvs()
    if #candidates == 0 then
        vim.notify("Tidak ada virtual environment Python yang ditemukan.", vim.log.levels.WARN, {
            title = "Python Venv",
        })
        return
    end

    if _G.Snacks and Snacks.picker then
        Snacks.picker({
            title = "Python Virtual Environments",
            items = candidates,
            format = function(item, _)
                local hl_label = item.is_active and "DiagnosticOk" or "SnacksPickerLabel"
                return {
                    { item.text, hl_label },
                    { "  " .. item.bin, "Comment" },
                }
            end,
            confirm = function(picker, item)
                picker:close()
                if item and item.bin then
                    M.set_python_path(item.bin)
                end
            end,
        })
    else
        vim.ui.select(candidates, {
            prompt = "Select Python Environment:",
            format_item = function(item)
                return string.format("%s  (%s)", item.text, item.bin)
            end,
        }, function(choice)
            if choice and choice.bin then
                M.set_python_path(choice.bin)
            end
        end)
    end
end

--- Returns active Python typechecker name ("ty" or "basedpyright").
---@return string
function M.active_typechecker()
    return vim.lsp.is_enabled("ty") and "ty" or "basedpyright"
end

--- Toggles Python typechecker LSP between basedpyright (default) and ty.
function M.toggle_typechecker()
    if vim.lsp.is_enabled("ty") then
        vim.lsp.enable("ty", false)
        vim.lsp.enable("basedpyright", true)
        vim.notify("Python LSP: basedpyright + ruff", vim.log.levels.INFO, {
            title = "Python LSP",
        })
        return
    end

    if vim.fn.executable("ty") ~= 1 then
        vim.notify(
            "Binary 'ty' tidak ditemukan di PATH; tetap menggunakan basedpyright.",
            vim.log.levels.WARN,
            { title = "Python LSP" }
        )
        return
    end

    vim.lsp.enable("basedpyright", false)
    vim.lsp.enable("ty", true)
    vim.notify("Python LSP: ty + ruff", vim.log.levels.INFO, {
        title = "Python LSP",
    })
end

vim.api.nvim_create_user_command("VenvSelect", function()
    M.select_venv()
end, { desc = "Select Python Virtual Environment (uv/snacks)" })

vim.api.nvim_create_user_command("VenvInfo", function()
    local path = M.get_python_path()
    local root = M.get_project_root()
    vim.notify(
        string.format(
            "Active Python: %s\nProject Root: %s\nTypechecker: %s",
            path,
            root,
            M.active_typechecker()
        ),
        vim.log.levels.INFO,
        { title = "Python Venv Info" }
    )
end, { desc = "Show active Python Virtual Environment and project root" })

vim.api.nvim_create_user_command("PyLspToggle", function()
    M.toggle_typechecker()
end, { desc = "Toggle Python typechecker (basedpyright <-> ty)" })

return M
