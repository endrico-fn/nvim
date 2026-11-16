local root_mod = require("util.root")

local function get_tauri_root(dir)
    local root = (root_mod and root_mod.root_dir(dir)) or dir or vim.uv.cwd()
    if vim.uv.fs_stat(root .. "/src-tauri") or vim.uv.fs_stat(root .. "/src-tauri/Cargo.toml") then
        return root
    end
    local found = vim.fs.find("src-tauri", { upward = true, path = dir, type = "directory" })[1]
    if found then
        return vim.fs.dirname(found)
    end
    return nil
end

local function detect_pkg_mgr(root)
    local function exists(rel)
        return vim.uv.fs_stat(root .. "/" .. rel) ~= nil
    end

    if exists("pnpm-lock.yaml") then
        return "pnpm"
    elseif exists("bun.lockb") or exists("bun.lock") then
        return "bun"
    elseif exists("yarn.lock") then
        return "yarn"
    end
    return "npm"
end

local function tauri_cmd(pkg_mgr, subcmd)
    if pkg_mgr == "npm" then
        return { "npm", "run", "tauri", "--", subcmd }
    end
    return { pkg_mgr, "tauri", subcmd }
end

return {
    name = "tauri",
    generator = function(opts, cb)
        local root = get_tauri_root(opts.dir)
        if not root then
            cb({})
            return
        end

        local pkg_mgr = detect_pkg_mgr(root)
        local tasks = {
            {
                name = "Tauri: Dev",
                desc = "Run Tauri app in dev mode (" .. pkg_mgr .. ")",
                tags = { "DEV", "TAURI" },
                builder = function()
                    return {
                        cmd = tauri_cmd(pkg_mgr, "dev"),
                        cwd = root,
                        components = { "default", { "on_output_quickfix", open = true } },
                    }
                end,
            },
            {
                name = "Tauri: Build",
                desc = "Build Tauri app release bundle (" .. pkg_mgr .. ")",
                tags = { "BUILD", "TAURI" },
                builder = function()
                    return {
                        cmd = tauri_cmd(pkg_mgr, "build"),
                        cwd = root,
                        components = { "default", { "on_output_quickfix", open = true } },
                    }
                end,
            },
            {
                name = "Tauri: Check Rust",
                desc = "Cargo check on src-tauri backend",
                tags = { "CHECK", "TAURI" },
                builder = function()
                    return {
                        cmd = {
                            "cargo",
                            "check",
                            "--manifest-path",
                            "src-tauri/Cargo.toml",
                        },
                        cwd = root,
                        components = { "default", { "on_output_quickfix", open = true } },
                    }
                end,
            },
        }

        cb(tasks)
    end,
}
