local buf = vim.api.nvim_get_current_buf()
local opts = { buf = buf, silent = true, noremap = true }

local function map(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, vim.tbl_extend("force", opts, { desc = desc }))
end

map("<leader>kv", function()
    require("util.python").select_venv()
end, "Python: Select VirtualEnv (uv/snacks)")

map("<leader>ky", function()
    require("util.python").toggle_typechecker()
end, "Python: Toggle Typechecker (basedpyright <-> ty)")

map("<localleader>dt", function()
    require("dap-python").test_method()
end, "Python: Debug Test Method")

map("<localleader>dc", function()
    require("dap-python").test_class()
end, "Python: Debug Test Class")

map("<leader>cO", function()
    vim.lsp.buf.code_action({
        apply = true,
        context = { only = { "source.organizeImports.ruff" }, diagnostics = {} },
    })
end, "Python: Organize Imports (ruff)")

map("<leader>cF", function()
    vim.lsp.buf.code_action({
        apply = true,
        context = { only = { "source.fixAll.ruff" }, diagnostics = {} },
    })
end, "Python: Fix All (ruff)")
