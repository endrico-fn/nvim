# nvim

Konfigurasi Neovim modern berbasis **Neovim 0.12+** yang dioptimalkan untuk standar API native (`vim._core.ui2`, `vim.lsp.config`/`enable`, `after/lsp/`, `after/ftplugin/`), manajemen tooling otomatis via **Mason**, serta keamanan sesi root/sudo di **Arch Linux**.

## Fitur Utama

- **Arsitektur Native Neovim 0.12:** Tanpa wrapper LSP usang (`on_new_config` / legacy `lspconfig.setup`). Seluruh 28 konfigurasi server berada di `after/lsp/` dan perilaku spesifik bahasa berada di `after/ftplugin/`.
- **Auto-Provisioning Penuh via Mason:** `mason.nvim`, `mason-lspconfig.nvim`, dan `nvim-treesitter` otomatis mengunduh LSP server, formatter, linter, debug adapter (DAP), serta parser Treesitter yang terkonfigurasi.
- **UI Ringan Tanpa Bloat:** Memanfaatkan `vim._core.ui2` bawaan + `snacks.nvim` (picker, explorer, notifier + `LspProgress`, zen, image, terminal, dashboard), `lualine.nvim`, `bufferline.nvim` (`showtabline=1` semantics), `aerial.nvim`, dan `which-key.nvim`.
- **Tema Custom `cryptnight`:** Dukungan highlight group Neovim 0.12 lengkap dengan dua varian — `cryptnight-storm` (`#0c0e0e`, default) dan `cryptnight-neutral` (`#141414`).
- **Ekosistem Bahasa Lengkap (Tanpa Pembatasan Kemampuan):**
  - **Python:** Default `basedpyright` (`workspace` indexing & full analysis) + `ruff`, mendukung toggle instan ke `ty` (`:PyLspToggle` / `<leader>ky`) serta pemilih virtualenv `uv`/`.venv` (`<leader>kv` / `:VenvSelect`).
  - **TypeScript & Web:** `vtsls` + mode hybrid `vue_ls` (`@vue/typescript-plugin`), deteksi TypeScript >= 7 (`tsc --lsp` / `tsgo`), dukungan `astro`, `svelte`, `tailwindcss` + native `vim.lsp.document_color` & class sorting (`<leader>cs`).
  - **Rust, Go, C/C++, Zig:** `rustaceanvim` (full feature/cache priming & code lens) + `crates.nvim`, `gopls` + `nvim-dap-go` (`gomodifytags`/`gotests`/`impl`), `clangd` + `clangd_extensions`, `zls`, serta debugging via `nvim-dap` & `neotest`.
  - **SQL & Notes:** `vim-dadbod-ui`, `sqls`, deteksi biner SQLite (`:SQLiteOpen`, `:SQLiteExec`, `<leader>D*`), serta `render-markdown.nvim` & `obsidian.nvim`.
- **Keamanan & Isolasi Root (`sudoedit`):** Deteksi `SUDO_USER` / `uid == 0` mem-bypass plugin (`lazy.nvim`), mematikan `exrc`, `modeline`, `undofile`, `shada`, dan `clipboard`, serta mengaktifkan `secure = true` lewat `sudoedit.lua`.

## Struktur Direktori

```text
~/.config/nvim/
├── init.lua                # Guard root/sudo, PATH, loader, config & tema
├── sudoedit.lua            # Profil terisolasi & aman untuk sesi sudo/root
├── stylua.toml             # Konfigurasi formatter Lua (4 spasi, width 100)
├── colors/                 # Entry point colorscheme (storm & neutral)
├── after/
│   ├── lsp/                # 28 konfigurasi server LSP native (vim.lsp.Config)
│   └── ftplugin/           # 19 konfigurasi & keymap buffer-local per filetype
├── lua/
│   ├── config/             # options, keymaps, autocmds, lsp, lazy, health (:checkhealth config)
│   ├── util/               # root, python (venv/ty toggle), ts (TS7 & Tailwind sort)
│   ├── plugins/            # 8 cluster: ui, treesitter, editor, completion, lsp, git, debug-test, extras
│   ├── overseer/           # Template task runner (go, python, rust/tauri, zig)
│   └── theme/cryptnight/   # Palet, highlight groups 0.12, dan tema lualine
└── luasnippets/            # Snippet Lua custom (go, python, typescript)
```

## Keymap Ringkas

Leader: `<Space>` · LocalLeader: `,` · Gerak bawaan Vim (`-`, `|`, `gr`, `[c`, `<Tab>`) tetap utuh.

| Kategori | Keymap | Aksi |
| --- | --- | --- |
| **Files & UI** | `<leader>e` / `<leader>E` | Explorer float / sidebar (`Snacks.explorer`) |
| | `<leader>ff` / `<leader>sg` | Find files / Live grep (`Snacks.picker`) |
| | `<leader>w-` / `<leader>w\|` | Horizontal / vertical split |
| | `<A-j>` / `<A-k>` | Pindah baris / seleksi atas-bawah |
| | `<leader>uu` | Native `:Undotree` |
| **LSP (0.12 + Custom)** | `gd` / `gD` / `K` / `<C-s>` | Definition / Declaration / Hover / Insert Signature Help |
| | `grr` / `gri` / `grt` / `gO` | References / Implementation / Type Def / Symbols |
| | `grn` / `gra` / `grx` | Rename (`:IncRename`) / Code Action / Run CodeLens |
| | `<leader>ca` / `<leader>cf` / `<leader>cH` | Code Action / Format (`conform`) / Toggle Inlay Hints |
| | `<leader>uc` / `<leader>ul` / `<leader>ut` | Toggle LSP Color / CodeLens / Typos LSP |
| **Per-Bahasa** | `<leader>kv` / `<leader>ky` | *(Python)* Pilih virtualenv / Toggle `basedpyright` <-> `ty` |
| | `<leader>cs` | *(Web/CSS)* Urutkan class Tailwind CSS |
| | `<leader>kTa` / `<leader>kG` / `<leader>ki` | *(Go)* Struct tags / `gotests` / `impl` |
| | `<leader>kr` / `<leader>kt` / `<leader>ke` | *(Rust)* Runnables / Testables / Explain Error |
| **Git, Test & DB** | `<leader>gg` / `<leader>gd` / `<leader>gD` | LazyGit / Picker Diff / Diff vs `HEAD~1` |
| | `<leader>tr` / `<leader>dn` / `<F5>` | Neotest Nearest / Debug Nearest Test / DAP Continue |
| | `<leader>Du` / `<leader>Do` / `<leader>De` | Dadbod UI / Open SQLite / Exec SQLite query |

## Instalasi

Prasyarat minimal: **Neovim >= 0.12.0**, `git`, dan tool dasar (`curl`, `unzip`, `tar`, `gcc`/`clang`, `node`/`npm`, `python3`) agar Mason & Treesitter dapat mengunduh serta membangun paket secara otomatis.

```bash
git clone https://github.com/endrico-fn/nvim.git ~/.config/nvim
nvim
```

Saat pertama kali dibuka, `lazy.nvim`, `mason.nvim`, `mason-lspconfig.nvim`, dan `nvim-treesitter` otomatis mengunduh seluruh plugin, LSP server, formatter, linter, debugger, dan parser. Jalankan `:checkhealth` kapan saja untuk verifikasi.
