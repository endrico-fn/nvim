return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },

    keys = {
        {
            "<leader>ma",
            function()
                local harpoon = require("harpoon")
                harpoon:list():add()
                local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:.")
                vim.notify("Ditambahkan: " .. file, vim.log.levels.INFO, { title = "Harpoon" })
            end,
            desc = "Harpoon: Add file",
        },
        {
            "<leader>mr",
            function()
                local harpoon = require("harpoon")
                harpoon:list():remove()
                local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:.")
                vim.notify("Dihapus: " .. file, vim.log.levels.WARN, { title = "Harpoon" })
            end,
            desc = "Harpoon: Remove file",
        },
        {
            "<leader>mm",
            function()
                require("harpoon").ui:toggle_quick_menu(require("harpoon"):list())
            end,
            desc = "Harpoon: Quick Menu",
        },
        {
            "<leader>mf",
            function()
                local harpoon = require("harpoon")
                local items = {}
                for i, item in ipairs(harpoon:list().items) do
                    if item and item.value and item.value ~= "" then
                        table.insert(items, {
                            idx = i,
                            file = item.value,
                            text = string.format("%d: %s", i, item.value),
                        })
                    end
                end
                if #items == 0 then
                    vim.notify("Harpoon list kosong", vim.log.levels.INFO, { title = "Harpoon" })
                    return
                end
                if _G.Snacks and Snacks.picker then
                    Snacks.picker({
                        title = "Harpoon Files",
                        items = items,
                        format = "file",
                    })
                else
                    harpoon.ui:toggle_quick_menu(harpoon:list())
                end
            end,
            desc = "Harpoon: Picker",
        },
        {
            "<leader>mc",
            function()
                require("harpoon"):list():clear()
                vim.notify("List dikosongkan", vim.log.levels.INFO, { title = "Harpoon" })
            end,
            desc = "Harpoon: Clear list",
        },
        {
            "[H",
            function()
                require("harpoon"):list():prev()
            end,
            desc = "Harpoon: Prev file",
        },
        {
            "]H",
            function()
                require("harpoon"):list():next()
            end,
            desc = "Harpoon: Next file",
        },
        {
            "<leader>1",
            function()
                require("harpoon"):list():select(1)
            end,
            desc = "Harpoon: File 1",
        },
        {
            "<leader>2",
            function()
                require("harpoon"):list():select(2)
            end,
            desc = "Harpoon: File 2",
        },
        {
            "<leader>3",
            function()
                require("harpoon"):list():select(3)
            end,
            desc = "Harpoon: File 3",
        },
        {
            "<leader>4",
            function()
                require("harpoon"):list():select(4)
            end,
            desc = "Harpoon: File 4",
        },
        {
            "<leader>5",
            function()
                require("harpoon"):list():select(5)
            end,
            desc = "Harpoon: File 5",
        },
        {
            "<leader>6",
            function()
                require("harpoon"):list():select(6)
            end,
            desc = "Harpoon: File 6",
        },
        {
            "<leader>7",
            function()
                require("harpoon"):list():select(7)
            end,
            desc = "Harpoon: File 7",
        },
        {
            "<leader>8",
            function()
                require("harpoon"):list():select(8)
            end,
            desc = "Harpoon: File 8",
        },
        {
            "<leader>9",
            function()
                require("harpoon"):list():select(9)
            end,
            desc = "Harpoon: File 9",
        },
    },

    opts = {
        settings = {
            save_on_toggle = true,
            sync_on_ui_close = true,
            key = function()
                local fname = vim.api.nvim_buf_get_name(0)
                return require("core.root").root_dir(fname) or vim.uv.cwd()
            end,
        },
    },
}
