local M = {}

--- Default LSP servers auto-enabled when matching filetypes open.
--- Note:
---   - `rust_analyzer` is intentionally omitted (managed by `rustaceanvim`)
---   - `ty` is intentionally omitted by default (toggle via `:PyLspToggle`)
---   - `typos_lsp` is intentionally omitted by default (toggle via `<leader>ut`)
M.servers = {
    "astro",
    "basedpyright",
    "bashls",
    "biome",
    "buf_ls",
    "clangd",
    "cssls",
    "dockerls",
    "emmet_language_server",
    "eslint",
    "gopls",
    "html",
    "jsonls",
    "lua_ls",
    "marksman",
    "ruff",
    "sqls",
    "svelte",
    "systemd_lsp",
    "tailwindcss",
    "taplo",
    "tsc",
    "vtsls",
    "vue_ls",
    "yamlls",
    "zls",
}

local diag_icons = {
    [vim.diagnostic.severity.ERROR] = "󰅚 ",
    [vim.diagnostic.severity.WARN] = "󰀪 ",
    [vim.diagnostic.severity.INFO] = "󰋽 ",
    [vim.diagnostic.severity.HINT] = "󰌶 ",
}

local diag_hl = {
    [vim.diagnostic.severity.ERROR] = "DiagnosticError",
    [vim.diagnostic.severity.WARN] = "DiagnosticWarn",
    [vim.diagnostic.severity.INFO] = "DiagnosticInfo",
    [vim.diagnostic.severity.HINT] = "DiagnosticHint",
}

local lsp_msg_level = {
    [1] = vim.log.levels.ERROR,
    [2] = vim.log.levels.WARN,
    [3] = vim.log.levels.INFO,
    [4] = vim.log.levels.DEBUG,
}

local lsp_log_level = vim.tbl_extend("force", {}, lsp_msg_level, {
    [4] = vim.log.levels.TRACE,
})

--- Execute a workspace command via the first LSP client matching `opts.filter`.
---@param opts { filter?: string, command: string, arguments?: any[], open?: boolean, title?: string }
function M.execute(opts)
    local filter = opts.filter
    local clients
    if filter then
        clients = vim.lsp.get_clients({ name = filter, bufnr = 0 })
        if #clients == 0 then
            clients = vim.lsp.get_clients({ name = filter })
        end
    else
        clients = vim.lsp.get_clients({ bufnr = 0 })
        if #clients == 0 then
            clients = vim.lsp.get_clients()
        end
    end

    local client
    for _, c in ipairs(clients) do
        if c.server_capabilities.executeCommandProvider then
            client = c
            break
        end
    end
    client = client or clients[1]
    if not client then
        return
    end

    if opts.open then
        client:request("workspace/executeCommand", {
            command = opts.command,
            arguments = opts.arguments,
        }, function(err, result)
            if not err and result and opts.title then
                vim.notify(opts.title .. " completed", vim.log.levels.INFO)
            end
        end)
    else
        client:exec_cmd({
            command = opts.command,
            arguments = opts.arguments,
        })
    end
end

--- Returns a callable that triggers a scoped LSP code action by kind.
---@param kind string
---@return fun()
function M.code_action_by_kind(kind)
    return function()
        local params = vim.lsp.util.make_range_params(0, "utf-16")
        params.context = {
            diagnostics = vim.diagnostic.get(0),
            only = { kind },
            triggerKind = 2,
        }
        vim.lsp.buf.code_action(params)
    end
end

M["source.organizeImports"] = M.code_action_by_kind("source.organizeImports")
M["source.addMissingImports.ts"] = M.code_action_by_kind("source.addMissingImports.ts")
M["source.fixAll.ts"] = M.code_action_by_kind("source.fixAll.ts")

local function build_capabilities()
    -- Mirrors blink.cmp's advertised completion capabilities statically so
    -- blink.cmp stays lazy-loaded until InsertEnter/CmdlineEnter.
    local caps = vim.tbl_deep_extend("force", vim.lsp.protocol.make_client_capabilities(), {
        textDocument = {
            completion = {
                completionItem = {
                    snippetSupport = true,
                    commitCharactersSupport = false,
                    documentationFormat = { "markdown", "plaintext" },
                    deprecatedSupport = true,
                    preselectSupport = false,
                    tagSupport = { valueSet = { 1 } },
                    insertReplaceSupport = true,
                    resolveSupport = {
                        properties = {
                            "documentation",
                            "detail",
                            "additionalTextEdits",
                            "command",
                            "data",
                        },
                    },
                    insertTextModeSupport = { valueSet = { 1 } },
                    labelDetailsSupport = true,
                },
                completionList = {
                    itemDefaults = {
                        "commitCharacters",
                        "editRange",
                        "insertTextFormat",
                        "insertTextMode",
                        "data",
                    },
                },
                contextSupport = true,
                insertTextMode = 1,
            },
            foldingRange = {
                dynamicRegistration = false,
                lineFoldingOnly = true,
            },
        },
    })
    return caps
end

local function setup_diagnostics()
    vim.diagnostic.config({
        update_in_insert = false,
        severity_sort = true,
        underline = { severity = { min = vim.diagnostic.severity.WARN } },
        signs = { text = diag_icons },
        virtual_text = {
            source = "if_many",
            spacing = 4,
            prefix = "●",
        },
        float = {
            source = true,
            focusable = false,
            header = { "󰀦  Diagnostics", "DiagnosticInfo" },
            prefix = function(diag)
                return diag_icons[diag.severity] or "● ", diag_hl[diag.severity]
            end,
        },
        jump = {
            on_jump = function(diag, bufnr)
                if not diag then
                    return
                end
                vim.diagnostic.open_float({
                    bufnr = bufnr,
                    scope = "cursor",
                    focus = false,
                })
            end,
        },
    })
end

local function setup_lsp_progress()
    local progress = vim.defaulttable()
    vim.api.nvim_create_autocmd("LspProgress", {
        group = vim.api.nvim_create_augroup("user_lsp_progress", { clear = true }),
        callback = function(ev)
            local client = vim.lsp.get_client_by_id(ev.data.client_id)
            local value = ev.data.params.value
            if not client or type(value) ~= "table" then
                return
            end
            local p = progress[client.id]

            for i = 1, #p + 1 do
                if i == #p + 1 or p[i].token == ev.data.params.token then
                    p[i] = {
                        token = ev.data.params.token,
                        msg = ("[%3d%%] %s%s"):format(
                            value.kind == "end" and 100 or value.percentage or 100,
                            value.title or "",
                            value.message and (" **%s**"):format(value.message) or ""
                        ),
                        done = value.kind == "end",
                    }
                    break
                end
            end

            local msg = {}
            progress[client.id] = vim.tbl_filter(function(v)
                return table.insert(msg, v.msg) or not v.done
            end, p)

            local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
            vim.notify(table.concat(msg, "\n"), vim.log.levels.INFO, {
                id = "lsp_progress",
                title = client.name,
                opts = function(notif)
                    notif.icon = #progress[client.id] == 0 and " "
                        or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
                end,
            })
        end,
    })
end

local function setup_attach_keymaps()
    vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_attach_universal", { clear = true }),
        callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if not client then
                return
            end
            local bufnr = args.buf

            local function map(mode, lhs, rhs, desc, method, extra)
                if method and not client:supports_method(method, bufnr) then
                    return
                end
                local opts = vim.tbl_extend("force", {
                    buf = bufnr,
                    desc = "LSP: " .. desc,
                    silent = true,
                    noremap = true,
                }, extra or {})
                vim.keymap.set(mode, lhs, rhs, opts)
            end

            -- Navigation & native 0.12 gr* standards (NO "gr" collision)
            map("n", "gd", vim.lsp.buf.definition, "Go to Definition", "textDocument/definition")
            map("n", "gD", vim.lsp.buf.declaration, "Go to Declaration", "textDocument/declaration")
            map("n", "grr", function()
                if _G.Snacks and Snacks.picker then
                    Snacks.picker.lsp_references()
                else
                    vim.lsp.buf.references()
                end
            end, "References", "textDocument/references")
            map("n", "gri", function()
                if _G.Snacks and Snacks.picker then
                    Snacks.picker.lsp_implementations()
                else
                    vim.lsp.buf.implementation()
                end
            end, "Implementation", "textDocument/implementation")
            map("n", "grt", vim.lsp.buf.type_definition, "Type Definition", "textDocument/typeDefinition")
            map("n", "gO", function()
                if _G.Snacks and Snacks.picker then
                    Snacks.picker.lsp_symbols()
                else
                    vim.lsp.buf.document_symbol()
                end
            end, "Document Symbols", "textDocument/documentSymbol")
            map("n", "grn", function()
                return ":IncRename " .. vim.fn.expand("<cword>")
            end, "Rename Symbol", "textDocument/rename", { expr = true })
            map({ "n", "x" }, "gra", vim.lsp.buf.code_action, "Code Action", "textDocument/codeAction")
            map("n", "grx", vim.lsp.codelens.run, "Run CodeLens", "textDocument/codeLens")

            -- Documentation & Signature Help (native Insert <C-s>)
            map("n", "K", vim.lsp.buf.hover, "Hover", "textDocument/hover")
            map("n", "gK", vim.lsp.buf.signature_help, "Signature Help", "textDocument/signatureHelp")
            map("i", "<C-s>", vim.lsp.buf.signature_help, "Signature Help (insert)", "textDocument/signatureHelp")

            -- <leader>c* Code Actions, Refactor, Formatting, Diagnostics & Hints
            map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code Action", "textDocument/codeAction")
            map("n", "<leader>cr", function()
                return ":IncRename " .. vim.fn.expand("<cword>")
            end, "Rename Symbol", "textDocument/rename", { expr = true })
            map({ "n", "v" }, "<leader>cf", function()
                require("conform").format({ bufnr = bufnr })
            end, "Format Buffer or Selection")
            map("n", "<leader>cd", vim.diagnostic.open_float, "Line Diagnostics")
            map("n", "<leader>cS", vim.lsp.buf.workspace_symbol, "Workspace Symbols", "workspace/symbol")
            map("n", "<leader>cE", function()
                vim.lsp.buf.code_action({
                    context = { only = { "refactor.extract" } },
                    apply = true,
                })
            end, "Extract (refactor)", "textDocument/codeAction")
            map("n", "<leader>cI", function()
                vim.lsp.buf.code_action({
                    context = { only = { "refactor.inline" } },
                    apply = true,
                })
            end, "Inline (refactor)", "textDocument/codeAction")
            map("n", "<leader>cH", function()
                if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= "" then
                    return
                end
                vim.lsp.inlay_hint.enable(
                    not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }),
                    { bufnr = bufnr }
                )
            end, "Toggle Inlay Hints", "textDocument/inlayHint")
            map("n", "<leader>ul", function()
                local next_state = not vim.lsp.codelens.is_enabled({ bufnr = bufnr })
                vim.lsp.codelens.enable(next_state, { bufnr = bufnr })
                vim.notify(
                    "CodeLens: " .. (next_state and "ON" or "OFF"),
                    vim.log.levels.INFO,
                    { title = "LSP" }
                )
            end, "Toggle CodeLens", "textDocument/codeLens")
        end,
    })
end

local function setup_global_toggles()
    vim.keymap.set("n", "<leader>uc", function()
        local next_state = not vim.lsp.document_color.is_enabled()
        vim.lsp.document_color.enable(next_state, nil, { style = "background" })
        vim.notify(
            "LSP Document Color: " .. (next_state and "ON" or "OFF"),
            vim.log.levels.INFO,
            { title = "UI" }
        )
    end, { desc = "Toggle LSP Document Colors" })

    vim.keymap.set("n", "<leader>ut", function()
        if not vim.lsp.config.typos_lsp then
            pcall(require, "nvim-lspconfig")
        end
        local next_state = not vim.lsp.is_enabled("typos_lsp")
        vim.lsp.enable("typos_lsp", next_state)
        vim.notify(
            "Typos LSP: " .. (next_state and "ON" or "OFF"),
            next_state and vim.log.levels.INFO or vim.log.levels.WARN,
            { title = "UI" }
        )
    end, { desc = "Toggle Typos (Spell LSP)" })
end

--- Enables all default LSP servers configured in `after/lsp/`.
--- Safe to invoke after `nvim-lspconfig` is added to `runtimepath`.
function M.enable()
    for _, server in ipairs(M.servers) do
        vim.lsp.enable(server)
    end
end

function M.setup()
    setup_diagnostics()
    setup_lsp_progress()
    setup_attach_keymaps()
    setup_global_toggles()

    vim.lsp.document_color.enable(true, nil, { style = "background" })
    if vim.lsp.linked_editing_range then
        pcall(vim.lsp.linked_editing_range.enable, true)
    end

    vim.lsp.config("*", {
        capabilities = build_capabilities(),
        handlers = {
            ["window/showMessage"] = function(_, result, ctx)
                local client = vim.lsp.get_client_by_id(ctx.client_id)
                vim.notify(
                    result.message,
                    lsp_msg_level[result.type] or vim.log.levels.INFO,
                    { title = client and client.name or "LSP" }
                )
            end,
            ["window/logMessage"] = function(_, result, ctx)
                local level = lsp_log_level[result.type] or vim.log.levels.TRACE
                if level >= vim.log.levels.WARN then
                    local client = vim.lsp.get_client_by_id(ctx.client_id)
                    vim.notify(result.message, level, {
                        title = (client and client.name or "LSP") .. " [log]",
                    })
                end
            end,
        },
    })
end

return M
