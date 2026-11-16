if vim.bo[0].buftype == "" then
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
end
vim.opt_local.conceallevel = 2
