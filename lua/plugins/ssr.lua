return {
    "cshuaimin/ssr.nvim",
    keys = {
        {
            "<leader>rS",
            function()
                require("ssr").open()
            end,
            mode = { "n", "x" },
            desc = "Replace (Structured)",
        },
    },
    config = true,
}
