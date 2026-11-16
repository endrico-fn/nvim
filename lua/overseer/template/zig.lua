local root_mod = require("core.root")

local function get_zig_root(dir)
    local root = (root_mod and root_mod.root_dir(dir, { "build.zig" })) or dir or vim.uv.cwd()
    if vim.uv.fs_stat(root .. "/build.zig") then
        return root
    end
    local found = vim.fs.find("build.zig", { upward = true, path = dir, type = "file" })[1]
    if found then
        return vim.fs.dirname(found)
    end
    return nil
end

return {
    name = "zig",
    generator = function(opts, cb)
        if vim.fn.executable("zig") == 0 then
            cb({})
            return
        end

        local root = get_zig_root(opts.dir)
        if not root then
            cb({})
            return
        end

        local tasks = {
            {
                name = "Zig: Build",
                desc = "Run zig build",
                tags = { "BUILD", "ZIG" },
                builder = function()
                    return {
                        cmd = { "zig", "build" },
                        cwd = root,
                        components = { "default", { "on_output_quickfix", open = true } },
                    }
                end,
            },
        }

        cb(tasks)
    end,
}
