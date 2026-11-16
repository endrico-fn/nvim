return {
    "danymat/neogen",
    cmd = "Neogen",
    keys = {
        {
            "<leader>cN",
            function()
                require("neogen").generate()
            end,
            desc = "Generate Annotations",
        },
    },
    opts = {
        languages = {
            rust = {
                template = { annotation_convention = "rustdoc" },
            },
        },
    },
}
