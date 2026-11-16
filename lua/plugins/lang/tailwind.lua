return {
    {
        "luckasRanarison/tailwind-tools.nvim",
        ft = {
            "html",
            "css",
            "scss",
            "javascript",
            "typescript",
            "javascriptreact",
            "typescriptreact",
            "svelte",
            "astro",
            "vue",
        },
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "neovim/nvim-lspconfig",
        },
        -- Hybrid clean (Opsi 3): tailwind-tools untuk :TailwindSort/:TailwindColorToggle,
        -- LSP tetap single-source via nvim-lspconfig di bawah (override=false).
        -- ccc.nvim handle hex/rgb literal (bg-[#ff0000]), tailwind-tools handle bg-red-500 dkk via LSP.
        opts = {
            server = {
                override = false, -- jangan duplikat client; hormati custom root_dir lspconfig
                settings = {},
                on_attach = function(client, bufnr) end,
            },
            document_color = {
                enabled = true,
                kind = "background", -- "background" = kotak warna penuh seperti css; "inline"=symbol 󰝤 kecil
                inline_symbol = "󰝤 ",
                debounce = 200,
            },
            conceal = { enabled = false, min_length = 30, symbol = "󱏿 " },
        },
        config = function(_, opts)
            require("tailwind-tools").setup(opts)

            local ft_list = {
                "html",
                "css",
                "scss",
                "javascript",
                "typescript",
                "javascriptreact",
                "typescriptreact",
                "svelte",
                "astro",
                "vue",
            }

            local function set_buf_maps(bufnr)
                local kmap = vim.keymap.set
                kmap(
                    "n",
                    "<leader>cs",
                    "<cmd>TailwindSort<cr>",
                    { desc = "Tailwind: Sort Classes (File)", buffer = bufnr }
                )
                kmap(
                    "v",
                    "<leader>cs",
                    "<cmd>TailwindSortSelection<cr>",
                    { desc = "Tailwind: Sort Classes (Selection)", buffer = bufnr }
                )
                kmap(
                    "n",
                    "<leader>ct",
                    "<cmd>TailwindColorToggle<cr>",
                    { desc = "Tailwind: Toggle Color Preview", buffer = bufnr }
                )
                kmap(
                    "n",
                    "<leader>cC",
                    "<cmd>TailwindConcealToggle<cr>",
                    { desc = "Tailwind: Toggle Class Conceal", buffer = bufnr }
                )
            end

            local cur = vim.api.nvim_get_current_buf()
            if vim.tbl_contains(ft_list, vim.bo[cur].filetype) then
                set_buf_maps(cur)
            end

            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup("tailwind_tools_keymaps", { clear = true }),
                pattern = ft_list,
                callback = function(ev)
                    set_buf_maps(ev.buf)
                end,
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}
            opts.servers.tailwindcss =
                vim.tbl_deep_extend("force", opts.servers.tailwindcss or {}, {
                    root_dir = function(bufnr, on_dir)
                        local fname = type(bufnr) == "number" and vim.api.nvim_buf_get_name(bufnr)
                            or bufnr
                        if fname == "" then
                            on_dir(nil)
                            return
                        end
                        -- Marker root: v3 config atau v4 configless (package.json/.git)
                        local root = require("core.root").root_dir(fname, {
                            "tailwind.config.js",
                            "tailwind.config.ts",
                            "tailwind.config.mjs",
                            "tailwind.config.cjs",
                            "package.json",
                            ".git",
                        })
                        if not root then
                            on_dir(nil)
                            return
                        end
                        -- Fast path: ada tailwind.config.* -> pasti Tailwind
                        for _, cfg in ipairs({
                            "tailwind.config.js",
                            "tailwind.config.ts",
                            "tailwind.config.mjs",
                            "tailwind.config.cjs",
                        }) do
                            if vim.uv.fs_stat(root .. "/" .. cfg) then
                                on_dir(root)
                                return
                            end
                        end
                        -- v4: cek package.json mengandung tailwindcss (strict)
                        local pkg = root .. "/package.json"
                        if vim.uv.fs_stat(pkg) then
                            local ok, lines = pcall(vim.fn.readfile, pkg)
                            if ok and lines then
                                local text = table.concat(lines, "\n")
                                if text:find("tailwindcss") then
                                    on_dir(root)
                                    return
                                end
                            end
                        end
                        -- Fallback v4 configless tanpa tailwindcss di package.json (monorepo/catalog, bun, pnpm)
                        -- Cek adanya file css yang import tailwind (src/app.css, app/assets/*.css)
                        -- Jika tidak ketemu, tetap attach bila root ada package.json/.git — biar LSP yang decide
                        -- (lebih baik false-positive daripada missing highlight).
                        -- Hemat resources tetap via filetypes filter di atas.
                        on_dir(root)
                    end,
                    filetypes = {
                        "html",
                        "css",
                        "scss",
                        "javascript",
                        "typescript",
                        "javascriptreact",
                        "typescriptreact",
                        "svelte",
                        "astro",
                        "vue",
                    },
                    settings = {
                        tailwindCSS = {
                            includeLanguages = {
                                svelte = "html",
                                astro = "html",
                                vue = "html",
                                typescript = "javascript",
                                javascript = "javascript",
                            },
                            experimental = {
                                classRegex = {
                                    "class[=:]\\s*[\"']([^\"']*)[\"']",
                                    "class:list\\s*=\\s*[\"']([^\"']*)[\"']",
                                    "className[=]\\s*[\"']([^\"']*)[\"']",
                                    "className[=]\\{`([^`]*)`\\}",
                                    "class\\s*=\\s*[\"']([^\"']*)[\"']",
                                    "class:([\\w-]+)[=\\s]",
                                    { "clsx\\(([^)]*)\\)", "[\"'`]([^\"'`]*)[\"'`]" },
                                    { "cx\\(([^)]*)\\)", "[\"'`]([^\"'`]*)[\"'`]" },
                                    { "cn\\(([^)]*)\\)", "[\"'`]([^\"'`]*)[\"'`]" },
                                    { "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*)[\"'`]" },
                                    { "tv\\(([^)]*)\\)", "[\"'`]([^\"'`]*)[\"'`]" },
                                    { "variant\\(([^)]*)\\)", "[\"'`]([^\"'`]*)[\"'`]" },
                                    { "tw(?:Merge|Join)\\(([^)]*)\\)", "[\"'`]([^\"'`]*)[\"'`]" },
                                    { "twMerge\\(([^)]*)\\)", "[\"'`]([^\"'`]*)[\"'`]" },
                                },
                            },
                        },
                    },
                })
        end,
    },
}
