local M = {}

local _ts7_cache = {}

local function read_package_json(root)
    local pkg_path = root .. "/package.json"
    local f = io.open(pkg_path, "r")
    if not f then
        return nil
    end
    local raw = f:read("*a")
    f:close()
    local ok, decoded = pcall(vim.json.decode, raw)
    return ok and type(decoded) == "table" and decoded or nil
end

local function has_pkg_dep(pkg, name)
    if not pkg then
        return false
    end
    local deps = pkg.dependencies
    local dev_deps = pkg.devDependencies
    return (type(deps) == "table" and deps[name] ~= nil)
        or (type(dev_deps) == "table" and dev_deps[name] ~= nil)
end

local function exepath_nonempty(cmd)
    local p = vim.fn.exepath(cmd)
    return (p and p ~= "") and p or nil
end

local function detect_ts7_major(bin)
    local ok, res = pcall(function()
        return vim.system({ bin, "--version" }, { text = true }):wait(1200)
    end)
    if not ok or not res or res.code ~= 0 or not res.stdout then
        return nil
    end
    local major = res.stdout:match("(%d+)%.%d+")
    return major and tonumber(major) or nil
end

--- Clears cached TypeScript 7 workspace detection results (e.g. after npm install).
---@param root? string
function M.clear_ts7_cache(root)
    if root then
        _ts7_cache[root] = nil
    else
        _ts7_cache = {}
    end
end

--- Silently detects whether `bufnr` belongs to a TypeScript >= 7 workspace
--- suitable for native `tsc --lsp` / `tsgo --lsp` (excluded for Vue/Astro/Svelte).
---@param bufnr? number
---@return { ok: boolean, root?: string, bin?: string }
function M.is_ts7_workspace(bufnr)
    bufnr = (bufnr and bufnr ~= 0) and bufnr or vim.api.nvim_get_current_buf()
    local ft = vim.bo[bufnr].filetype
    if ft == "vue" or ft == "astro" or ft == "svelte" then
        return { ok = false }
    end

    local fname = vim.api.nvim_buf_get_name(bufnr)
    if not fname or fname == "" then
        fname = vim.uv.cwd() or ""
    end

    local root = require("util.root").root_dir(fname, {
        "tsconfig.json",
        "jsconfig.json",
        "package.json",
        ".git",
    })
    if not root then
        return { ok = false }
    end

    if _ts7_cache[root] ~= nil then
        return _ts7_cache[root]
    end

    local pkg = read_package_json(root)
    if
        has_pkg_dep(pkg, "vue")
        or has_pkg_dep(pkg, "astro")
        or has_pkg_dep(pkg, "svelte")
        or has_pkg_dep(pkg, "nuxt")
    then
        _ts7_cache[root] = { ok = false }
        return _ts7_cache[root]
    end

    local candidates = {}
    local local_tsgo = root .. "/node_modules/.bin/tsgo"
    local local_tsc = root .. "/node_modules/.bin/tsc"
    if vim.uv.fs_stat(local_tsgo) then
        table.insert(candidates, local_tsgo)
    end
    if vim.uv.fs_stat(local_tsc) then
        table.insert(candidates, local_tsc)
    end
    local global_tsgo = exepath_nonempty("tsgo")
    if global_tsgo then
        table.insert(candidates, global_tsgo)
    end
    local global_tsc = exepath_nonempty("tsc")
    if global_tsc then
        table.insert(candidates, global_tsc)
    end

    for _, bin in ipairs(candidates) do
        local major = detect_ts7_major(bin)
        if major and major >= 7 then
            _ts7_cache[root] = { ok = true, root = root, bin = bin }
            return _ts7_cache[root]
        end
    end

    _ts7_cache[root] = { ok = false }
    return _ts7_cache[root]
end

--- Finds the inner bounds (0-indexed row, start_col, end_col) of class/className under cursor.
local function find_class_attr_at_cursor(buf)
    local row, col0 = unpack(vim.api.nvim_win_get_cursor(0))
    row = row - 1
    local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
    local col1 = col0 + 1

    for _, pat in ipairs({
        'className%s*=%s*"([^"]*)"',
        'class%s*=%s*"([^"]*)"',
        "className%s*=%s*'([^']*)'",
        "class%s*=%s*'([^']*)'",
    }) do
        local init = 1
        while true do
            local s, e, inner = line:find(pat, init)
            if not s then
                break
            end
            if col1 >= s and col1 <= e then
                local inner_s = line:find(inner, s, true)
                if inner_s then
                    return row, inner_s - 1, row, inner_s - 1 + #inner
                end
            end
            init = e + 1
        end
    end
    return nil
end

--- Sorts Tailwind classes via native `@/tailwindCSS/sortSelection` LSP request
--- (with Visual selection or cursor `class=`/`className=` extraction, or Conform fallback).
function M.sort_tailwind_classes()
    local buf = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients({ name = "tailwindcss", bufnr = buf })
    local client = clients[1]

    if not client then
        local ok_conf, conform = pcall(require, "conform")
        if ok_conf then
            conform.format({ bufnr = buf })
        else
            vim.notify(
                "tailwindcss LSP belum terpasang di buffer ini",
                vim.log.levels.WARN,
                { title = "Tailwind" }
            )
        end
        return
    end

    local mode = vim.fn.mode()
    local sr, sc, er, ec
    if mode == "v" or mode == "V" or mode == "\22" then
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
            "nx",
            false
        )
        local p1 = vim.fn.getpos("'<")
        local p2 = vim.fn.getpos("'>")
        sr, sc = p1[2] - 1, p1[3] - 1
        er, ec = p2[2] - 1, p2[3]
    else
        sr, sc, er, ec = find_class_attr_at_cursor(buf)
    end

    if not sr then
        local ok_conf, conform = pcall(require, "conform")
        if ok_conf then
            conform.format({ bufnr = buf })
        else
            vim.notify(
                "Arahkan kursor ke atribut class/className atau pilih teks visual.",
                vim.log.levels.INFO,
                {
                    title = "Tailwind",
                }
            )
        end
        return
    end

    local text = table.concat(vim.api.nvim_buf_get_text(buf, sr, sc, er, ec, {}), "\n")
    local params = vim.tbl_extend("error", vim.lsp.util.make_text_document_params(buf), {
        classLists = { text },
    })

    client:request("@/tailwindCSS/sortSelection", params, function(err, result)
        if err then
            vim.notify(
                "Tailwind sort error: " .. (err.message or tostring(err)),
                vim.log.levels.ERROR,
                {
                    title = "Tailwind",
                }
            )
            return
        end
        if not result or type(result.classLists) ~= "table" or not result.classLists[1] then
            return
        end
        if not vim.api.nvim_buf_is_valid(buf) then
            return
        end
        local lines = vim.split(result.classLists[1], "\n", { plain = true })
        pcall(vim.api.nvim_buf_set_text, buf, sr, sc, er, ec, lines)
    end, buf)
end

--- Registers buffer-local TypeScript / vtsls keymaps cleanly without leaking across filetypes.
---@param buf? number
function M.setup_ts_ftplugin(buf)
    buf = (buf and buf ~= 0) and buf or vim.api.nvim_get_current_buf()
    local lsp = require("config.lsp")
    local opts = { buf = buf, silent = true, noremap = true }

    vim.keymap.set("n", "gR", function()
        lsp.execute({
            command = "typescript.findAllFileReferences",
            arguments = { vim.uri_from_bufnr(buf) },
            open = true,
        })
    end, vim.tbl_extend("force", opts, { desc = "TS: File References" }))

    vim.keymap.set("n", "<leader>cD", function()
        local win = vim.api.nvim_get_current_win()
        local params = vim.lsp.util.make_position_params(win, "utf-16")
        lsp.execute({
            command = "typescript.goToSourceDefinition",
            arguments = { params.textDocument.uri, params.position },
            open = true,
        })
    end, vim.tbl_extend("force", opts, { desc = "TS: Goto Source Definition" }))

    vim.keymap.set(
        "n",
        "<leader>cO",
        lsp["source.organizeImports"],
        vim.tbl_extend("force", opts, { desc = "TS: Organize Imports" })
    )
    vim.keymap.set(
        "n",
        "<leader>cM",
        lsp["source.addMissingImports.ts"],
        vim.tbl_extend("force", opts, { desc = "TS: Add Missing Imports" })
    )
    vim.keymap.set(
        "n",
        "<leader>cF",
        lsp["source.fixAll.ts"],
        vim.tbl_extend("force", opts, { desc = "TS: Fix All" })
    )
    vim.keymap.set("n", "<leader>cV", function()
        lsp.execute({ command = "typescript.selectTypeScriptVersion" })
    end, vim.tbl_extend("force", opts, { desc = "TS: Select Workspace Version" }))
end

--- Registers buffer-local Tailwind class sorting keymap cleanly.
---@param buf? number
function M.setup_tailwind_ftplugin(buf)
    buf = (buf and buf ~= 0) and buf or vim.api.nvim_get_current_buf()
    vim.keymap.set({ "n", "v" }, "<leader>cs", function()
        M.sort_tailwind_classes()
    end, { buf = buf, silent = true, noremap = true, desc = "Tailwind: Sort Classes" })
end

return M
