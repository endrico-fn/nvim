local buf = vim.api.nvim_get_current_buf()
local ts = require("util.ts")
ts.setup_tailwind_ftplugin(buf)

vim.keymap.set("n", "<leader>cW", function()
    local fname = vim.api.nvim_buf_get_name(buf)
    if fname == "" or vim.bo[buf].filetype ~= "svelte" then
        vim.notify("Bukan buffer Svelte.", vim.log.levels.WARN, { title = "Svelte" })
        return
    end

    local code = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
    local script = [[
import { compile } from 'svelte/compiler';
let input = '';
process.stdin.on('data', chunk => { input += chunk; });
process.stdin.on('end', () => {
    try {
        const res = compile(input, { filename: process.argv[1] || 'Component.svelte', generate: 'client' });
        process.stdout.write(res.js.code);
    } catch (e) {
        process.stderr.write(e.message || String(e));
        process.exit(1);
    }
});
]]
    local basename = vim.fn.fnamemodify(fname, ":t")
    local root = vim.fs.root(fname, { "package.json", ".git" }) or vim.fn.getcwd()

    vim.system({ "node", "--input-type=module", "-e", script, basename }, {
        stdin = code,
        cwd = root,
    }, function(res)
        vim.schedule(function()
            if res.code ~= 0 then
                vim.notify(
                    "Kompilasi Svelte gagal:\n" .. (res.stderr or ""),
                    vim.log.levels.ERROR,
                    { title = "Svelte Compiler" }
                )
                return
            end

            vim.cmd("vsplit")
            local new_buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_set_current_buf(new_buf)
            vim.bo[new_buf].buftype = "nofile"
            vim.bo[new_buf].filetype = "javascript"
            vim.api.nvim_buf_set_name(new_buf, basename .. " (compiled.js)")
            local lines = vim.split(res.stdout, "\n", { plain = true })
            vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, lines)
        end)
    end)
end, { buf = buf, silent = true, noremap = true, desc = "Svelte: Show Compiled JS" })
