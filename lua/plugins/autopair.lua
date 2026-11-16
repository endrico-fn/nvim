return {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
        check_ts = true,
        fast_wrap = {
            highlight = "PmenuSel",
            highlight_grey = "LineNr",
        },
    },
}
