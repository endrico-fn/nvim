return {
    "folke/flash.nvim",
    keys = {
        { "gs", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash Jump" },
        { "gS", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
        { "r", mode = "o", function() require("flash").remote() end, desc = "Flash Remote" },
        { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Flash Treesitter Search" },
        { "<C-f>", mode = "c", function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
    opts = {
        jump = {
            nohlsearch = true,
        },
        label = {
            uppercase = false,
            exclude = "hjkliardc",
            rainbow = {
                enabled = true,
            },
        },
        modes = {
            char = {
                multi_line = false,
                autohide = true,
                highlight = { backdrop = false },
            },
        },
        remote_op = {
            restore = true,
        },
    },
}
