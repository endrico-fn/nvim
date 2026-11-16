local buf = vim.api.nvim_get_current_buf()
if vim.fs.basename(vim.api.nvim_buf_get_name(buf)) ~= "Cargo.toml" then
    return
end

local function cmap(lhs, method, desc)
    vim.keymap.set("n", lhs, function()
        require("crates")[method]()
    end, { buf = buf, silent = true, noremap = true, desc = desc })
end

cmap("<leader>kcu", "update_crate", "crates: Update Crate")
cmap("<leader>kcC", "upgrade_crate", "crates: Upgrade Crate")
cmap("<leader>kcx", "expand_plain_crate_to_inline_table", "crates: Expand Crate to Inline Table")
cmap("<leader>kcp", "show_popup", "crates: Show Popup")
cmap("<leader>kcf", "show_features_popup", "crates: Show Features")
cmap("<leader>kcd", "show_dependencies_popup", "crates: Show Dependencies")
cmap("<leader>kct", "toggle", "crates: Toggle Feature")
cmap("<leader>kcr", "reload", "crates: Reload Crates")
