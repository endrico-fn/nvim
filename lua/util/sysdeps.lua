local M = {}

local SNOOZE_SECONDS = 24 * 60 * 60
local NS_ID = vim.api.nvim_create_namespace("sysdeps_ui")

--------------------------------------------------------------------------------
-- Dependency Definitions
--------------------------------------------------------------------------------

--- Layer 1: Pacman packages
local PACKAGES = {
    -- Core Toolchain
    { id = "git", label = "git", cmd = "git --version", pkg = "git", tier = "core" },
    {
        id = "cc",
        label = "C compiler (cc)",
        cmd = "cc --version",
        pkg = "base-devel",
        tier = "core",
    },
    { id = "make", label = "make", cmd = "make --version", pkg = "base-devel", tier = "core" },
    {
        id = "tree-sitter",
        label = "tree-sitter CLI",
        cmd = "tree-sitter --version",
        pkg = "tree-sitter-cli",
        tier = "core",
    },
    { id = "curl", label = "curl", cmd = "curl --version", pkg = "curl", tier = "core" },
    { id = "tar", label = "tar", cmd = "tar --version", pkg = "tar", tier = "core" },
    { id = "unzip", label = "unzip", cmd = "unzip -v", pkg = "unzip", tier = "core" },
    {
        id = "node",
        label = "Node.js",
        cmd = "node --version",
        pkg = (vim.fn.executable("fnm") == 1) and "fnm (fnm install --lts)" or "nodejs",
        tier = "core",
    },
    {
        id = "npm",
        label = "npm",
        cmd = "npm --version",
        pkg = (vim.fn.executable("fnm") == 1) and "fnm (fnm install --lts)" or "npm",
        tier = "core",
    },
    { id = "python", label = "Python 3", cmd = "python3 --version", pkg = "python", tier = "core" },
    { id = "uv", label = "uv (Python)", cmd = "uv --version", pkg = "uv", tier = "lang" },
    { id = "ruff", label = "ruff (Python)", cmd = "ruff --version", pkg = "ruff", tier = "lang" },
    { id = "rg", label = "ripgrep", cmd = "rg --version", pkg = "ripgrep", tier = "core" },
    { id = "fd", label = "fd", cmd = "fd --version", pkg = "fd", tier = "core" },

    -- Language Runtimes
    { id = "rustup", label = "rustup", cmd = "rustup --version", pkg = "rustup", tier = "lang" },
    { id = "go", label = "Go", cmd = "go version", pkg = "go", tier = "lang" },

    -- Optional Tools & Git Helpers
    {
        id = "lazygit",
        label = "LazyGit",
        cmd = "lazygit --version",
        pkg = "lazygit",
        tier = "optional",
    },
    {
        id = "gh",
        label = "GitHub CLI (gh)",
        cmd = "gh --version",
        pkg = "github-cli",
        tier = "optional",
    },
    {
        id = "protoc",
        label = "protoc",
        cmd = "protoc --version",
        pkg = "protobuf",
        tier = "optional",
    },
    {
        id = "sqlite3",
        label = "sqlite3",
        cmd = "sqlite3 --version",
        pkg = "sqlite",
        tier = "optional",
    },
    { id = "zig", label = "Zig", cmd = "zig version", pkg = "zig", tier = "optional" },
}

--- External / Manual tools (reported in :SysDepsCheck, never auto-installed)
local MANUAL = {
    { label = "Dart / Flutter", cmd = "dart --version", hint = "AUR (flutter-bin) / manual" },
    {
        label = "Docker",
        cmd = "docker --version",
        hint = "sudo pacman -Syu docker",
    },
}

--- Layer 2: Post-install toolchain steps
local function build_steps()
    local steps = {
        {
            id = "rust-toolchain",
            label = "Rust toolchain (stable)",
            needs = "rustup --version",
            check = "rustc --version",
            run = "rustup default stable",
        },
        {
            id = "rust-components",
            label = "rust-analyzer + rust-src",
            needs = "rustc --version",
            check = 'rust-analyzer --version && test -d "$(rustc --print sysroot)/lib/rustlib/src"',
            run = "rustup component add rust-analyzer rust-src",
        },
    }
    for _, target in ipairs(vim.g.sysdeps_rust_targets or {}) do
        local q = vim.fn.shellescape(target)
        table.insert(steps, {
            id = "rust-target-" .. target,
            label = "Rust target " .. target,
            needs = "rustc --version",
            check = "rustup target list --installed | grep -qx " .. q,
            run = "rustup target add " .. q,
        })
    end
    return steps
end

--------------------------------------------------------------------------------
-- Snooze System
--------------------------------------------------------------------------------

local function snooze_path()
    return vim.fn.stdpath("state") .. "/sysdeps_snooze.json"
end

local function is_snoozed(signature)
    local ok, lines = pcall(vim.fn.readfile, snooze_path())
    if not ok then
        return false
    end
    local ok2, data = pcall(vim.json.decode, table.concat(lines, "\n"))
    if not ok2 or type(data) ~= "table" then
        return false
    end
    return data.signature == signature and (os.time() - (data.ts or 0)) < SNOOZE_SECONDS
end

local function snooze(signature)
    pcall(vim.fn.mkdir, vim.fn.stdpath("state"), "p")
    pcall(
        vim.fn.writefile,
        { vim.json.encode({ signature = signature, ts = os.time() }) },
        snooze_path()
    )
end

--------------------------------------------------------------------------------
-- Status Checker (Async & Fast)
--------------------------------------------------------------------------------

local function extract_version(output)
    if not output or #output == 0 then
        return nil
    end
    for line in output:gmatch("[^\r\n]+") do
        if not line:match("^%s*info:") then
            local ver = line:match("(%d+%.%d+[%d%.%w-]*)")
            if ver then
                return ver
            end
        end
    end
    return nil
end

---@param cmd string
---@param cb fun(ok: boolean, ver: string|nil)
local function run_check(cmd, cb)
    local ok = pcall(
        vim.system,
        { "sh", "-c", "{ " .. cmd .. "; } 2>&1" },
        { timeout = 5000 },
        function(res)
            vim.schedule(function()
                local ver = nil
                if res.code == 0 and res.stdout and #res.stdout > 0 then
                    ver = extract_version(res.stdout)
                end
                cb(res.code == 0, ver)
            end)
        end
    )
    if not ok then
        vim.schedule(function()
            cb(false, nil)
        end)
    end
end

--- Collect status across tools
---@param cb fun(status: table)
---@param opts? { all?: boolean, manual?: boolean }
function M.get_status(cb, opts)
    opts = opts or {}
    local tiers = { core = true, lang = true, optional = opts.all or false }

    local status = {
        deps = {},
        steps = {},
        manual = {},
        missing = {},
        pending = {},
        pkgs = {},
        total = 0,
        ready = 0,
    }
    local jobs = {}

    for _, item in ipairs(PACKAGES) do
        if tiers[item.tier] then
            table.insert(jobs, { cmd = item.cmd, item = item, bucket = status.deps })
        end
    end
    for _, item in ipairs(build_steps()) do
        table.insert(jobs, { cmd = item.check, item = item, bucket = status.steps })
    end
    if opts.manual then
        for _, item in ipairs(MANUAL) do
            table.insert(jobs, { cmd = item.cmd, item = item, bucket = status.manual })
        end
    end

    local remaining = #jobs

    local function finish()
        local seen_pkg = {}
        for _, group in ipairs({ status.deps, status.steps, status.manual }) do
            table.sort(group, function(a, b)
                return a.index < b.index
            end)
        end

        for _, r in ipairs(status.deps) do
            status.total = status.total + 1
            if r.ok then
                status.ready = status.ready + 1
            else
                table.insert(status.missing, r.item)
                if not seen_pkg[r.item.pkg] then
                    seen_pkg[r.item.pkg] = true
                    table.insert(status.pkgs, r.item.pkg)
                end
            end
        end

        for _, r in ipairs(status.steps) do
            status.total = status.total + 1
            if r.ok then
                status.ready = status.ready + 1
            else
                table.insert(status.pending, r.item)
            end
        end

        status.needs_action = (#status.missing + #status.pending) > 0
        local ids = {}
        for _, it in ipairs(status.missing) do
            table.insert(ids, it.id)
        end
        for _, it in ipairs(status.pending) do
            table.insert(ids, it.id)
        end
        table.sort(ids)
        status.signature = table.concat(ids, ",")
        cb(status)
    end

    if remaining == 0 then
        return finish()
    end

    for i, job in ipairs(jobs) do
        run_check(job.cmd, function(ok, ver)
            table.insert(job.bucket, { item = job.item, ok = ok, ver = ver, index = i })
            remaining = remaining - 1
            if remaining == 0 then
                finish()
            end
        end)
    end
end

--- Synchronous status check (for headless tests or pre-flight gate)
---@param opts? { all?: boolean, manual?: boolean }
---@return table|nil
function M.get_status_sync(opts)
    local out
    M.get_status(function(s)
        out = s
    end, opts)
    vim.wait(30000, function()
        return out ~= nil
    end, 20)
    return out
end

--------------------------------------------------------------------------------
-- Preflight & Pre-Plugin Gate
--------------------------------------------------------------------------------

function M.preflight()
    return {
        pacman = vim.fn.executable("pacman") == 1,
        sudo = vim.fn.executable("sudo") == 1,
        git = vim.fn.executable("git") == 1,
    }
end

--- Blocking gate executed in init.lua BEFORE lazy.setup().
--- Prevents Treesitter, Mason, and LuaSnip from throwing background build errors
--- on fresh systems where compilers or runtimes are missing.
function M.pre_plugin_gate()
    -- Skip if headless (CLI automation) or explicitly disabled
    if #vim.api.nvim_list_uis() == 0 or vim.g.sysdeps_disable then
        return
    end

    local pf = M.preflight()
    if not (pf.pacman and pf.sudo) then
        return
    end

    -- Fast synchronous check of essential tool binaries
    -- Auto-resolve fnm path if available
    local fnm_bin = vim.fn.expand("~/.local/share/fnm/aliases/default/bin")
    if vim.fn.isdirectory(fnm_bin) == 1 and not (vim.env.PATH or ""):find(fnm_bin, 1, true) then
        vim.env.PATH = fnm_bin .. ":" .. vim.env.PATH
    end

    local critical_checks = {
        { id = "git", bin = "git", label = "git", pkg = "git" },
        { id = "fnm", bin = "fnm", label = "fnm", pkg = "fnm" },
        { id = "cc", bin = "cc", label = "gcc / cc", pkg = "base-devel" },
        { id = "make", bin = "make", label = "make", pkg = "base-devel" },
        {
            id = "tree-sitter",
            bin = "tree-sitter",
            label = "tree-sitter CLI",
            pkg = "tree-sitter-cli",
        },
        { id = "unzip", bin = "unzip", label = "unzip", pkg = "unzip" },
        { id = "node", bin = "node", label = "Node.js", pkg = "nodejs" },
        { id = "npm", bin = "npm", label = "npm", pkg = "npm" },
        { id = "python", bin = "python3", label = "Python 3", pkg = "python" },
        { id = "go", bin = "go", label = "Go", pkg = "go" },
        { id = "rustup", bin = "rustup", label = "Rustup", pkg = "rustup" },
    }

    local missing_items = {}
    local missing_objs = {}
    local missing_pkgs = {}
    local seen_pkg = {}
    local ids = {}

    for _, it in ipairs(critical_checks) do
        if vim.fn.executable(it.bin) == 0 then
            table.insert(missing_items, it.label)
            table.insert(missing_objs, it)
            table.insert(ids, it.id)
            if not seen_pkg[it.pkg] then
                seen_pkg[it.pkg] = true
                table.insert(missing_pkgs, it.pkg)
            end
        end
    end

    -- If all critical tools are installed, pass immediately (< 1ms overhead)
    if #missing_items == 0 then
        return
    end

    table.sort(ids)
    local signature = table.concat(ids, ",")
    if is_snoozed(signature) then
        return
    end

    local prompt_msg = table.concat({
        "Essential development tools are missing on your system.",
        "Plugins (Treesitter, Mason, LuaSnip) require these tools to compile parsers and install language servers.",
        "",
        "Missing tools  : " .. table.concat(missing_items, ", "),
        "Pacman packages: " .. table.concat(missing_pkgs, " "),
        "",
        "Disarankan jalankan bootstrap.sh lebih dulu (satu sumber instalasi host).",
        "Install missing tools now via pacman before loading plugins?",
    }, "\n")

    -- Default = "Continue anyway" (2), bukan "Install now". Gate ini bertugas
    -- MEMERIKSA, bukan menjadi installer kedua yang bersaing dengan bootstrap.sh.
    local choice = vim.fn.confirm(
        prompt_msg,
        "&Install now (pacman)\n&Continue anyway (may cause plugin errors)\n&Skip for 24h",
        2,
        "Warning"
    )

    if choice == 1 then
        -- Generate and execute full installation script in terminal
        local status = {
            pkgs = missing_pkgs,
            pending = {},
            missing = missing_objs,
        }
        -- Check if rustup needs toolchain setup
        if vim.tbl_contains(missing_pkgs, "rustup") or vim.fn.executable("rustc") == 0 then
            table.insert(status.pending, {
                id = "rust-toolchain",
                label = "Rust toolchain (stable)",
                needs = "rustup --version",
                check = "rustc --version",
                run = "rustup default stable",
            })
            table.insert(status.pending, {
                id = "rust-components",
                label = "rust-analyzer + rust-src",
                needs = "rustc --version",
                check = 'rust-analyzer --version && test -d "$(rustc --print sysroot)/lib/rustlib/src"',
                run = "rustup component add rust-analyzer rust-src",
            })
        end

        local script_lines = M.build_script(status)
        local script_path = vim.fn.tempname() .. ".sh"
        vim.fn.writefile(script_lines, script_path)
        vim.cmd("!bash " .. vim.fn.shellescape(script_path))
        pcall(os.remove, script_path)
    elseif choice == 3 then
        snooze(signature)
    end
end

--------------------------------------------------------------------------------
-- Script Generator (Clean Live-Log Installer)
--------------------------------------------------------------------------------

---@param status table
---@return string[] lines
function M.build_script(status)
    local sq = vim.fn.shellescape
    local L = {
        "#!/usr/bin/env bash",
        "set -u",
        "FAILED=0",
        "RESULTS=()",
        'ok()   { RESULTS+=("  [OK]    $1"); }',
        'skip() { RESULTS+=("  [SKIP]  $1 (already configured)"); }',
        'fail() { RESULTS+=("  [FAIL]  $1"); FAILED=1; }',
        "",
        "# Styling helpers",
        'if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then',
        '  C_BOLD="\\033[1m"; C_GREEN="\\033[32m"; C_RED="\\033[31m"; C_CYAN="\\033[36m"; C_RESET="\\033[0m"',
        "else",
        '  C_BOLD=""; C_GREEN=""; C_RED=""; C_CYAN=""; C_RESET=""',
        "fi",
        "echo",
    }

    local step_idx = 1
    local total_steps = (#status.pkgs > 0 and 1 or 0) + #status.pending

    if #status.pkgs > 0 then
        local pk = table.concat(status.pkgs, " ")
        vim.list_extend(L, {
            ('echo -e "${C_CYAN}━━ [%d/%d] Installing System Packages via Pacman ━━━━━━━━━━━━━━━━━━━━${C_RESET}"'):format(
                step_idx,
                total_steps
            ),
            "if [ -f /var/lib/pacman/db.lck ]; then",
            '  echo -e "${C_RED}==> Pacman database is locked (/var/lib/pacman/db.lck). Wait for other package managers to finish or remove stale lockfile.${C_RESET}"',
            "fi",
            ('echo -e "\\$ sudo pacman -Syu --needed %s"'):format(pk),
            ("if sudo pacman -Syu --needed %s; then ok %s; else"):format(pk, sq("pacman: " .. pk)),
            ("  fail %s"):format(sq("pacman: " .. pk)),
            "  echo -e \"${C_RED}==> If you encounter 404 or stale database errors, run 'sudo pacman -Syu' and retry.${C_RESET}\"",
            "fi",
            "echo",
        })
        step_idx = step_idx + 1
    end

    for _, step in ipairs(status.pending) do
        local label = sq(step.label)
        vim.list_extend(L, {
            ('echo -e "${C_CYAN}━━ [%d/%d] %s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"'):format(
                step_idx,
                total_steps,
                step.label
            ),
            ("if { %s; } >/dev/null 2>&1; then"):format(step.check),
            ("  skip %s"):format(label),
            ("elif { %s; } >/dev/null 2>&1; then"):format(step.needs),
            ('  echo -e "\\$ %s"'):format(step.run),
            ("  if %s; then ok %s; else fail %s; fi"):format(step.run, label, label),
            "else",
            ("  fail %s"):format(sq(step.label .. " (prerequisites missing)")),
            "fi",
            "echo",
        })
        step_idx = step_idx + 1
    end

    vim.list_extend(L, {
        'echo -e "${C_CYAN}┌──────────────────────────────────────────────────────────────────┐${C_RESET}"',
        'echo -e "${C_CYAN}│${C_RESET}   ${C_BOLD}SUMMARY${C_RESET}                                                        ${C_CYAN}│${C_RESET}"',
        'echo -e "${C_CYAN}├──────────────────────────────────────────────────────────────────┤${C_RESET}"',
        'for res in "${RESULTS[@]}"; do',
        '  echo -e "${C_CYAN}│${C_RESET} $res"',
        "done",
        'echo -e "${C_CYAN}│${C_RESET}"',
        'if [ "$FAILED" -eq 0 ]; then',
        '  echo -e "${C_CYAN}│${C_RESET}   ${C_GREEN}✓ Installation completed successfully!${C_RESET}"',
        "else",
        '  echo -e "${C_CYAN}│${C_RESET}   ${C_RED}✗ Some steps failed. You can re-run with :SysDepsInstall${C_RESET}"',
        "fi",
        'echo -e "${C_CYAN}│${C_RESET}"',
        'echo -e "${C_CYAN}└──────────────────────────────────────────────────────────────────┘${C_RESET}"',
        "echo",
        'read -rp "Press [ENTER] to return to Neovim... " _',
        "exit $FAILED",
    })
    return L
end

--------------------------------------------------------------------------------
-- Professional ASCII Float UI
--------------------------------------------------------------------------------

local function get_panel_dimensions()
    local w = math.min(108, math.max(76, math.floor(vim.o.columns * 0.90)))
    local h = math.min(34, math.max(22, math.floor(vim.o.lines * 0.85)))
    local row = math.max(0, math.floor((vim.o.lines - h) / 2) - 1)
    local col = math.max(0, math.floor((vim.o.columns - w) / 2))
    return { width = w, height = h, row = row, col = col }
end

--- Attach auto-resize listener so floating windows stay centered on VimResized
local function attach_resize_autocmd(win, buf)
    local resize_id = vim.api.nvim_create_autocmd("VimResized", {
        callback = function()
            if not vim.api.nvim_win_is_valid(win) then
                return true
            end
            local d = get_panel_dimensions()
            pcall(vim.api.nvim_win_set_config, win, {
                relative = "editor",
                width = d.width,
                height = d.height,
                row = d.row,
                col = d.col,
            })
        end,
    })
    vim.api.nvim_create_autocmd("BufWipeout", {
        buf = buf,
        once = true,
        callback = function()
            pcall(vim.api.nvim_del_autocmd, resize_id)
        end,
    })
end

--- Open a floating window with sharp single borders, title, footer, and cursor placement
local function open_float(lines, title, footer, keymaps, hl_spans, cursor_row)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"

    local dims = get_panel_dimensions()

    local win_opts = {
        relative = "editor",
        width = dims.width,
        height = dims.height,
        row = dims.row,
        col = dims.col,
        style = "minimal",
        border = "single",
    }
    if title and title ~= "" then
        win_opts.title = " " .. title .. " "
        win_opts.title_pos = "center"
    end
    if footer and footer ~= "" then
        win_opts.footer = " " .. footer .. " "
        win_opts.footer_pos = "right"
    end

    local win = vim.api.nvim_open_win(buf, true, win_opts)
    vim.wo[win].cursorline = true
    vim.wo[win].wrap = false
    attach_resize_autocmd(win, buf)

    if cursor_row and cursor_row > 0 and cursor_row <= #lines then
        pcall(vim.api.nvim_win_set_cursor, win, { cursor_row, 4 })
    end

    -- Apply extmark highlights if provided
    if hl_spans then
        for _, s in ipairs(hl_spans) do
            pcall(vim.api.nvim_buf_set_extmark, buf, NS_ID, s.line, s.col_start, {
                end_col = s.col_end,
                hl_group = s.hl,
            })
        end
    end

    local function close()
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
    end

    for lhs, fn in pairs(keymaps) do
        vim.keymap.set("n", lhs, function()
            fn(close, win)
        end, { buf = buf, nowait = true, silent = true })
    end

    return close
end

--- Render UI content and track highlights
local function render_ui(status, mode)
    local lines = {}
    local hl_spans = {}
    local line_to_item = {}
    local first_missing_line = nil
    local first_item_line = nil

    local function add(str)
        table.insert(lines, str)
        return #lines - 1 -- 0-indexed line number
    end

    local function add_hl(line_idx, col_start, col_end, hl)
        table.insert(hl_spans, {
            line = line_idx,
            col_start = col_start,
            col_end = col_end,
            hl = hl,
        })
    end

    if mode == "prompt" then
        add("")
        local l_head = add("  Some development dependencies are missing on your system.")
        add_hl(l_head, 2, #lines[l_head + 1], "Title")
        add("")

        if #status.missing > 0 then
            local l_grp = add("  PACKAGES (pacman)")
            add_hl(l_grp, 2, #lines[l_grp + 1], "Special")
            for _, it in ipairs(status.missing) do
                local item_line = string.format("    ✗  %-28s %s", it.label, it.pkg)
                local l_idx = add(item_line)
                add_hl(l_idx, 4, 7, "DiagnosticError")
                add_hl(l_idx, 7, 35, "Normal")
                add_hl(l_idx, 35, #item_line, "Comment")
            end
            add("")
        end

        if #status.pending > 0 then
            local l_grp = add("  POST-INSTALL STEPS")
            add_hl(l_grp, 2, #lines[l_grp + 1], "Special")
            for _, it in ipairs(status.pending) do
                local item_line =
                    string.format("    ✗  %-28s %s", it.label, it.run or "configure")
                local l_idx = add(item_line)
                add_hl(l_idx, 4, 7, "DiagnosticError")
                add_hl(l_idx, 7, 35, "Normal")
                add_hl(l_idx, 35, #item_line, "Comment")
            end
            add("")
        end
    else
        -- Detailed report mode (:SysDepsCheck)
        -- Line 1: Header
        local status_head = string.format("  System Deps Status: %d/%d", status.ready, status.total)
        local l_head = add(status_head)
        add_hl(l_head, 2, 22, "Title")
        local stat_hl = status.ready == status.total and "DiagnosticOk" or "DiagnosticWarn"
        add_hl(l_head, 22, #status_head, stat_hl)

        -- Line 2: Empty
        add("")

        -- Line 3: Action Buttons
        local act_line = "  [i] install    [I] install all    [y] yank cmd"
        local l_act = add(act_line)
        add_hl(l_act, 2, 5, "Special")
        add_hl(l_act, 17, 20, "Special")
        add_hl(l_act, 36, 39, "Special")

        -- Line 4: Empty
        add("")

        local tiers_info = {
            { key = "core", title = "CORE TOOLCHAIN" },
            { key = "lang", title = "LANGUAGE RUNTIMES" },
            { key = "optional", title = "OPTIONAL TOOLS" },
        }

        local first_sec = true
        for _, t in ipairs(tiers_info) do
            local items = vim.tbl_filter(function(r)
                return r.item.tier == t.key
            end, status.deps)
            if #items > 0 then
                local hdr_line
                if first_sec then
                    hdr_line = string.format("  %-37s %-23s %s", t.title, "STATUS", "VERSION")
                    first_sec = false
                else
                    hdr_line = "  " .. t.title
                end
                local l_thdr = add(hdr_line)
                add_hl(l_thdr, 2, 2 + #t.title, "Title")
                if hdr_line:find("STATUS") then
                    add_hl(l_thdr, 40, 46, "Comment")
                    add_hl(l_thdr, 64, 71, "Comment")
                end

                for _, r in ipairs(items) do
                    local chk = r.ok and "x" or " "
                    local status_str = r.ok and "[installed]" or "[not installed]"
                    local ver_str = (r.ok and r.ver) and r.ver or ""
                    local row_line = string.format(
                        "    [%s] %-31s %-23s %s",
                        chk,
                        r.item.label,
                        status_str,
                        ver_str
                    )
                    row_line = row_line:gsub("%s+$", "")
                    local l_idx = add(row_line)

                    local row_1idx = l_idx + 1
                    line_to_item[row_1idx] = { kind = "pkg", item = r.item, ok = r.ok }
                    if not first_item_line then
                        first_item_line = row_1idx
                    end
                    if not r.ok and not first_missing_line then
                        first_missing_line = row_1idx
                    end

                    local chk_hl = r.ok and "DiagnosticOk" or "DiagnosticWarn"
                    add_hl(l_idx, 5, 6, chk_hl)
                    local st_hl = r.ok and "DiagnosticOk" or "DiagnosticError"
                    add_hl(l_idx, 39, 39 + #status_str, st_hl)
                    if #ver_str > 0 then
                        add_hl(l_idx, 63, 63 + #ver_str, "Comment")
                    end
                end
                add("")
            end
        end

        -- POST-INSTALL STEPS
        if #status.steps > 0 then
            local l_hdr = add("  POST-INSTALL STEPS")
            add_hl(l_hdr, 2, 2 + 18, "Title")
            for _, r in ipairs(status.steps) do
                local chk = r.ok and "x" or " "
                local status_str = r.ok and "[installed]" or "[not installed]"
                local ver_str = (r.ok and r.ver) and r.ver or ""
                local row_line =
                    string.format("    [%s] %-31s %-23s %s", chk, r.item.label, status_str, ver_str)
                row_line = row_line:gsub("%s+$", "")
                local l_idx = add(row_line)

                local row_1idx = l_idx + 1
                line_to_item[row_1idx] = { kind = "step", item = r.item, ok = r.ok }
                if not r.ok and not first_missing_line then
                    first_missing_line = row_1idx
                end

                local chk_hl = r.ok and "DiagnosticOk" or "DiagnosticWarn"
                add_hl(l_idx, 5, 6, chk_hl)
                local st_hl = r.ok and "DiagnosticOk" or "DiagnosticError"
                add_hl(l_idx, 39, 39 + #status_str, st_hl)
                if #ver_str > 0 then
                    add_hl(l_idx, 63, 63 + #ver_str, "Comment")
                end
            end
            add("")
        end

        -- MANUAL / EXTERNAL
        if #status.manual > 0 then
            local l_hdr = add("  MANUAL / EXTERNAL (Not installed automatically)")
            add_hl(l_hdr, 2, #lines[l_hdr + 1], "Comment")
            for _, r in ipairs(status.manual) do
                local chk = r.ok and "x" or " "
                local status_col = r.ok and "[installed]" or r.item.hint
                local ver_str = (r.ok and r.ver) and r.ver or ""
                local row_line
                if r.ok then
                    row_line = string.format(
                        "    [%s] %-31s %-23s %s",
                        chk,
                        r.item.label,
                        status_col,
                        ver_str
                    )
                else
                    row_line = string.format("    [%s] %-31s %s", chk, r.item.label, status_col)
                end
                row_line = row_line:gsub("%s+$", "")
                local l_idx = add(row_line)

                local row_1idx = l_idx + 1
                line_to_item[row_1idx] = { kind = "manual", item = r.item, ok = r.ok }

                local chk_hl = r.ok and "DiagnosticOk" or "Comment"
                add_hl(l_idx, 5, 6, chk_hl)
                if r.ok then
                    add_hl(l_idx, 39, 50, "DiagnosticOk")
                    if #ver_str > 0 then
                        add_hl(l_idx, 63, 63 + #ver_str, "Comment")
                    end
                else
                    add_hl(l_idx, 39, #row_line, "Comment")
                end
            end
        end
    end

    return lines, hl_spans, line_to_item, (first_missing_line or first_item_line or 1)
end

--------------------------------------------------------------------------------
-- Interactive Terminal Installer
--------------------------------------------------------------------------------

--- Actions executed after installer finishes to rebuild plugins that failed earlier
local function post_install_rebuild(status)
    local was_missing = {}
    for _, it in ipairs(status.missing or {}) do
        was_missing[it.id] = true
    end

    M.get_status(function(now)
        local still = {}
        for _, it in ipairs(now.missing or {}) do
            still[it.id] = true
        end

        -- Rebuild LuaSnip jsregexp if make was installed
        if was_missing.make and not still.make then
            pcall(vim.cmd, "Lazy build LuaSnip")
        end

        -- Re-run Treesitter parser installation if C compiler was installed
        if was_missing.cc and not still.cc then
            local langs = {}
            local ok, plugin_mod = pcall(require, "lazy.core.plugin")
            local ok2, cfg = pcall(require, "lazy.core.config")
            if ok and ok2 and cfg.plugins["nvim-treesitter"] then
                local ok3, o =
                    pcall(plugin_mod.values, cfg.plugins["nvim-treesitter"], "opts", false)
                if ok3 and type(o) == "table" then
                    langs = o.ensure_installed or {}
                end
            end
            if #langs > 0 then
                pcall(vim.cmd, "TSInstall " .. table.concat(langs, " "))
            end
        end
    end)
end

function M.run_installer(status, on_done)
    local pf = M.preflight()
    if not (pf.pacman and pf.sudo) then
        vim.notify(
            "pacman/sudo not available — please install dependencies manually.",
            vim.log.levels.WARN,
            { title = "sysdeps" }
        )
        return
    end

    local path = vim.fn.tempname() .. ".sh"
    vim.fn.writefile(M.build_script(status), path)

    local buf = vim.api.nvim_create_buf(false, true)
    local dims = get_panel_dimensions()
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = dims.width,
        height = dims.height,
        row = dims.row,
        col = dims.col,
        style = "minimal",
        border = "single",
        title = " System Dependency Installer ",
        title_pos = "center",
    })
    attach_resize_autocmd(win, buf)

    vim.fn.jobstart({ "bash", path }, {
        term = true,
        on_exit = function(_, code)
            vim.schedule(function()
                if vim.api.nvim_win_is_valid(win) then
                    vim.api.nvim_win_close(win, true)
                end
                if vim.api.nvim_buf_is_valid(buf) then
                    vim.api.nvim_buf_delete(buf, { force = true })
                end
                pcall(os.remove, path)
                vim.cmd("stopinsert")
                if code == 0 then
                    vim.notify(
                        "System dependencies installed successfully ✓",
                        vim.log.levels.INFO,
                        { title = "sysdeps" }
                    )
                else
                    vim.notify(
                        ("Installation finished with errors (exit code %d). Re-run with :SysDepsInstall"):format(
                            code
                        ),
                        vim.log.levels.WARN,
                        { title = "sysdeps" }
                    )
                end
                post_install_rebuild(status)
                if on_done then
                    on_done()
                end
            end)
        end,
    })
    vim.cmd("startinsert")
end

--- Show floating dialog (prompt or report)
local function show_dialog(status, mode)
    local pf = M.preflight()
    local lines, hl_spans, line_to_item, default_cursor_row = render_ui(status, mode)

    local keys = {}

    if mode == "prompt" then
        keys = {
            q = function(close)
                snooze(status.signature)
                close()
            end,
            ["<Esc>"] = function(close)
                snooze(status.signature)
                close()
            end,
            ["?"] = function(close)
                close()
                M.check()
            end,
            i = function(close)
                if not (pf.pacman and pf.sudo) then
                    vim.notify(
                        "pacman/sudo not available",
                        vim.log.levels.WARN,
                        { title = "sysdeps" }
                    )
                    return
                end
                close()
                M.run_installer(status, function()
                    M.check()
                end)
            end,
        }
        keys["<CR>"] = keys.i
        open_float(
            lines,
            "System Dependencies",
            "[i] Install  [<Esc>] Skip for 24h  [?] Details",
            keys,
            hl_spans,
            1
        )
    else
        -- mode == "report" (:SysDepsCheck)
        keys = {
            ["<Esc>"] = function(close)
                close()
            end,
            q = function(close)
                close()
            end,
            r = function(close)
                close()
                M.check()
            end,
            y = function(_, win)
                local row = vim.api.nvim_win_get_cursor(win)[1]
                local target = line_to_item[row]
                if not target then
                    vim.notify(
                        "Move cursor to an item to yank its command",
                        vim.log.levels.INFO,
                        { title = "sysdeps" }
                    )
                    return
                end
                local cmd_str
                if target.kind == "pkg" then
                    cmd_str = "sudo pacman -Syu --needed " .. target.item.pkg
                elseif target.kind == "step" then
                    cmd_str = target.item.run
                elseif target.kind == "manual" then
                    cmd_str = target.item.hint
                end
                if cmd_str and cmd_str ~= "" then
                    pcall(vim.fn.setreg, "+", cmd_str)
                    pcall(vim.fn.setreg, '"', cmd_str)
                    vim.notify("Yanked: " .. cmd_str, vim.log.levels.INFO, { title = "sysdeps" })
                end
            end,
            i = function(close, win)
                local cursor = vim.api.nvim_win_get_cursor(win)
                local row = cursor[1]
                local target = line_to_item[row]
                if not target then
                    vim.notify(
                        "Move cursor to an item to install",
                        vim.log.levels.INFO,
                        { title = "sysdeps" }
                    )
                    return
                end
                if target.kind == "manual" then
                    vim.notify(
                        "Manual installation required: "
                            .. (target.item.hint or "see documentation"),
                        vim.log.levels.INFO,
                        { title = "sysdeps" }
                    )
                    return
                end
                if target.ok then
                    vim.notify(
                        target.item.label .. " is already installed ✓",
                        vim.log.levels.INFO,
                        { title = "sysdeps" }
                    )
                    return
                end
                if not (pf.pacman and pf.sudo) then
                    vim.notify(
                        "pacman/sudo not available",
                        vim.log.levels.WARN,
                        { title = "sysdeps" }
                    )
                    return
                end

                close()
                local single_status = {
                    pkgs = target.kind == "pkg" and { target.item.pkg } or {},
                    pending = target.kind == "step" and { target.item } or {},
                    missing = target.kind == "pkg" and { target.item } or {},
                }
                M.run_installer(single_status, function()
                    M.check()
                end)
            end,
            I = function(close)
                if not status.needs_action then
                    vim.notify(
                        "All dependencies are already installed ✓",
                        vim.log.levels.INFO,
                        { title = "sysdeps" }
                    )
                    return
                end
                if not (pf.pacman and pf.sudo) then
                    vim.notify(
                        "pacman/sudo not available",
                        vim.log.levels.WARN,
                        { title = "sysdeps" }
                    )
                    return
                end

                close()
                local all_status = {
                    pkgs = vim.deepcopy(status.pkgs),
                    pending = vim.deepcopy(status.pending),
                    missing = vim.deepcopy(status.missing),
                }
                M.run_installer(all_status, function()
                    M.check()
                end)
            end,
        }
        keys["<CR>"] = keys.i

        open_float(
            lines,
            nil,
            "[r] refresh ── [<Esc>] exit",
            keys,
            hl_spans,
            default_cursor_row
        )
    end
end

--------------------------------------------------------------------------------
-- Public Commands, Healthcheck & Lifecycle
--------------------------------------------------------------------------------

function M.check_health()
    local health = vim.health
    health.start("sysdeps: System Development Dependencies")
    local st = M.get_status_sync({ all = true, manual = true })
    if not st then
        health.error("Timed out checking system dependencies")
        return
    end

    for _, r in ipairs(st.deps) do
        local msg = string.format(
            "%s (%s)%s",
            r.item.label,
            r.item.pkg,
            r.ver and (" — v" .. r.ver) or ""
        )
        if r.ok then
            health.ok(msg)
        elseif r.item.tier == "optional" then
            health.warn(msg .. " [missing optional]")
        else
            health.error(msg .. " [missing]")
        end
    end

    for _, r in ipairs(st.steps) do
        local msg = r.item.label .. (r.ver and (" — v" .. r.ver) or "")
        if r.ok then
            health.ok(msg)
        else
            health.warn(msg .. " [pending: " .. (r.item.run or "") .. "]")
        end
    end

    for _, r in ipairs(st.manual) do
        local msg = r.item.label .. (r.ver and (" — v" .. r.ver) or "")
        if r.ok then
            health.ok(msg)
        else
            health.info(msg .. " [manual: " .. (r.item.hint or "") .. "]")
        end
    end
end

function M.check()
    M.get_status(function(status)
        show_dialog(status, "report")
    end, { all = true, manual = true })
end

function M.install(all)
    M.get_status(function(status)
        if not status.needs_action then
            vim.notify(
                "All dependencies are already installed ✓",
                vim.log.levels.INFO,
                { title = "sysdeps" }
            )
            return
        end
        M.run_installer(status, function()
            M.check()
        end)
    end, { all = all })
end

--- Automatic non-intrusive startup check
function M.auto_check()
    if vim.g.sysdeps_disable or #vim.api.nvim_list_uis() == 0 then
        return
    end

    M.get_status(function(status)
        if not status.needs_action or is_snoozed(status.signature) then
            return
        end

        local pf = M.preflight()
        if not (pf.pacman and pf.sudo) then
            local names = {}
            for _, it in ipairs(status.missing) do
                table.insert(names, it.label)
            end
            vim.notify(
                "Missing system dependencies (pacman/sudo unavailable): "
                    .. table.concat(names, ", "),
                vim.log.levels.WARN,
                { title = "sysdeps" }
            )
            return
        end

        if vim.g.sysdeps_auto_popup then
            show_dialog(status, "prompt")
        else
            local names = {}
            for _, it in ipairs(status.missing) do
                table.insert(names, it.label)
            end
            if #names > 0 then
                vim.notify(
                    "Sysdeps: "
                        .. #names
                        .. " dependensi sistem belum terpasang ("
                        .. table.concat(names, ", ")
                        .. "). Jalankan :SysDepsCheck atau ~/.config/nvim/bootstrap.sh",
                    vim.log.levels.INFO,
                    { title = "sysdeps" }
                )
            end
        end
    end)
end

-- User Commands
vim.api.nvim_create_user_command("SysDepsCheck", function()
    M.check()
end, { desc = "Show system development dependencies status" })

vim.api.nvim_create_user_command("SysDepsInstall", function(args)
    M.install(args.args == "all")
end, {
    nargs = "?",
    complete = function()
        return { "all" }
    end,
    desc = "Install missing system dependencies via pacman and rustup",
})

-- On-demand only (run :SysDepsCheck or :SysDepsInstall manually)

M.render_ui = render_ui

return M
