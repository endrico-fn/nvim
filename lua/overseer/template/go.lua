local root_mod = require("core.root")

local function get_go_root(dir)
    local root = (root_mod and root_mod.root_dir(dir, { "go.mod" })) or dir or vim.uv.cwd()
    if vim.uv.fs_stat(root .. "/go.mod") then
        return root
    end
    local found = vim.fs.find("go.mod", { upward = true, path = dir, type = "file" })[1]
    if found then
        return vim.fs.dirname(found)
    end
    return nil
end

return {
    name = "go",
    generator = function(opts, cb)
        if vim.fn.executable("go") == 0 then
            cb({})
            return
        end

        local root = get_go_root(opts.dir)
        if not root then
            cb({})
            return
        end

        local tasks = {
            {
                name = "Go: Build",
                desc = "Build all Go packages",
                tags = { "BUILD", "GO" },
                builder = function()
                    return {
                        cmd = { "go", "build", "./..." },
                        cwd = root,
                        components = { "default", { "on_output_quickfix", open = true } },
                    }
                end,
            },
            {
                name = "Go: Run",
                desc = "Run main Go package",
                tags = { "RUN", "GO" },
                builder = function()
                    return {
                        cmd = { "go", "run", "." },
                        cwd = root,
                        components = { "default" },
                    }
                end,
            },
            {
                name = "Go: Vet",
                desc = "Run go vet ./...",
                tags = { "CHECK", "GO" },
                builder = function()
                    return {
                        cmd = { "go", "vet", "./..." },
                        cwd = root,
                        components = { "default", { "on_output_quickfix", open = true } },
                    }
                end,
            },
            {
                name = "Go: Tidy",
                desc = "Run go mod tidy",
                tags = { "GO" },
                builder = function()
                    return {
                        cmd = { "go", "mod", "tidy" },
                        cwd = root,
                        components = { "default" },
                    }
                end,
            },
        }

        cb(tasks)
    end,
}
