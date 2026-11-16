return {
    "stevearc/overseer.nvim",
    cmd = {
        "OverseerRun",
        "OverseerToggle",
        "OverseerTaskAction",
        "OverseerBuild",
        "OverseerClearCache",
    },
    keys = {
        { "<leader>or", "<cmd>OverseerRun<cr>", desc = "Run Task" },
        { "<leader>ot", "<cmd>OverseerToggle<cr>", desc = "Task List" },
        { "<leader>oa", "<cmd>OverseerTaskAction<cr>", desc = "Task Action" },
        { "<leader>ob", "<cmd>OverseerBuild<cr>", desc = "Build Project" },
        { "<leader>oc", "<cmd>OverseerClearCache<cr>", desc = "Clear Task Cache" },
    },
    opts = {
        task_list = {
            max_history = 10,
            default_detail = 1,
            direction = "bottom",
            height = 12,
            border = "single",
            keymaps = {
                ["<C-j>"] = false,
                ["<C-k>"] = false,
            },
        },
        form = {
            win_opts = { border = "single" },
        },
    },
}
