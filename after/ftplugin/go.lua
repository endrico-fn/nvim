local buf = vim.api.nvim_get_current_buf()
local opts = { buf = buf, silent = true, noremap = true }

local function map(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, vim.tbl_extend("force", opts, { desc = desc }))
end

local function run_gomodifytags(flag, prompt_label, action_verb)
    if vim.fn.executable("gomodifytags") == 0 then
        vim.notify("gomodifytags tidak ditemukan. Install via Mason.", vim.log.levels.ERROR, {
            title = "Go Tags",
        })
        return
    end
    local file = vim.api.nvim_buf_get_name(buf)
    if file == "" then
        vim.notify("Buffer belum disimpan ke file", vim.log.levels.WARN, { title = "Go Tags" })
        return
    end
    local tag = vim.fn.input(prompt_label .. " (default: json): ")
    if tag == "" then
        tag = "json"
    end
    local line = vim.api.nvim_win_get_cursor(0)[1]
    vim.system(
        { "gomodifytags", "-file", file, "-line", tostring(line), flag, tag, "-w" },
        { text = true },
        function(out)
            vim.schedule(function()
                if out.code == 0 then
                    vim.cmd("edit!")
                    vim.notify(
                        action_verb .. " `" .. tag .. "` tag on struct",
                        vim.log.levels.INFO,
                        { title = "Go Tags" }
                    )
                else
                    vim.notify(
                        "gomodifytags gagal:\n" .. (out.stderr ~= "" and out.stderr or out.stdout),
                        vim.log.levels.ERROR,
                        { title = "Go Tags" }
                    )
                end
            end)
        end
    )
end

map("<leader>cO", function()
    vim.lsp.buf.code_action({
        context = { only = { "source.organizeImports" } },
        apply = true,
    })
    local clients = vim.lsp.get_clients({ name = "gopls", bufnr = buf })
    if clients[1] then
        clients[1]:exec_cmd({ command = "gopls.tidy" })
    end
    vim.notify("go mod tidy done", vim.log.levels.INFO, { title = "Go" })
end, "Go: Tidy imports + mod")

map("<leader>cF", function()
    vim.lsp.buf.code_action({
        context = { only = { "source.fixAll" } },
        apply = true,
    })
end, "Go: Fix all (gopls)")

map("<leader>kL", function()
    vim.lsp.codelens.enable(true, { bufnr = buf })
    vim.schedule(function()
        vim.lsp.codelens.run()
    end)
end, "Go: Run Code Lens")

map("<leader>kTa", function()
    run_gomodifytags("-add-tags", "Tag name", "Added")
end, "Go: Add struct tags")

map("<leader>kTr", function()
    run_gomodifytags("-remove-tags", "Tag name to remove", "Removed")
end, "Go: Remove struct tags")

map("<leader>kG", function()
    if vim.fn.executable("gotests") == 0 then
        vim.notify("gotests tidak ditemukan. Install via Mason.", vim.log.levels.ERROR, {
            title = "Go Tests",
        })
        return
    end
    local file = vim.api.nvim_buf_get_name(buf)
    if file == "" then
        vim.notify("Buffer belum disimpan ke file", vim.log.levels.WARN, { title = "Go Tests" })
        return
    end
    local func = vim.fn.expand("<cword>")

    local function run_all()
        vim.system({ "gotests", "-w", "-all", file }, { text = true }, function(all_out)
            vim.schedule(function()
                if all_out.code == 0 then
                    vim.notify("Generated unit tests for all functions", vim.log.levels.INFO, {
                        title = "Go Tests",
                    })
                else
                    vim.notify(
                        "gotests gagal:\n"
                            .. (all_out.stderr ~= "" and all_out.stderr or all_out.stdout),
                        vim.log.levels.ERROR,
                        { title = "Go Tests" }
                    )
                end
            end)
        end)
    end

    vim.system(
        { "gotests", "-w", "-only", "^" .. func .. "$", file },
        { text = true },
        function(out)
            vim.schedule(function()
                if out.code == 0 then
                    vim.notify("Generated unit tests for " .. func, vim.log.levels.INFO, {
                        title = "Go Tests",
                    })
                else
                    run_all()
                end
            end)
        end
    )
end, "Go: Generate unit tests (gotests)")

map("<leader>ki", function()
    if vim.fn.executable("impl") == 0 then
        vim.notify("impl tidak ditemukan. Install via Mason.", vim.log.levels.ERROR, {
            title = "Go Impl",
        })
        return
    end
    local recv = vim.fn.input("Receiver (e.g. 'f *Foo'): ")
    if recv == "" then
        return
    end
    local iface = vim.fn.input("Interface (e.g. 'io.Reader'): ")
    if iface == "" then
        return
    end
    vim.system({ "impl", recv, iface }, { text = true }, function(out)
        vim.schedule(function()
            if out.code == 0 and out.stdout ~= "" then
                local lines = vim.split(out.stdout, "\n", { plain = true })
                local row = vim.api.nvim_win_get_cursor(0)[1]
                vim.api.nvim_buf_set_lines(buf, row, row, false, lines)
                vim.notify("Implemented interface stubs", vim.log.levels.INFO, { title = "Go Impl" })
            else
                vim.notify(
                    "impl gagal:\n" .. (out.stderr ~= "" and out.stderr or out.stdout),
                    vim.log.levels.ERROR,
                    { title = "Go Impl" }
                )
            end
        end)
    end)
end, "Go: Implement interface (impl)")
