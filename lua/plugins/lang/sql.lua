-- sql.lua — merged sqls + sqlite (ex-sqlite.lua) single source
-- SQLite: filetype .db/.sqlite via header check, :SQLiteOpen/:SQLiteExec, sqls dynamic connection

local M = {}

function M.is_available()
	return vim.fn.executable("sqlite3") == 1
end

function M.connection_string(dbpath)
	return "sqlite://" .. vim.fn.fnamemodify(dbpath, ":p")
end

function M.open(dbpath)
	if not M.is_available() then
		vim.notify("sqlite3 CLI tidak ditemukan.", vim.log.levels.ERROR)
		return
	end
	dbpath = dbpath or vim.api.nvim_buf_get_name(0)
	if dbpath == "" then
		vim.notify("Tidak ada file database yang terbuka.", vim.log.levels.WARN)
		return
	end
	dbpath = vim.fn.fnamemodify(dbpath, ":p")
	local ok, handle = pcall(vim.uv.fs_open, dbpath, "r", 438)
	if not ok or not handle then
		vim.notify("File tidak ditemukan: " .. dbpath, vim.log.levels.ERROR)
		return
	end
	local header = vim.uv.fs_read(handle, 16, 0)
	vim.uv.fs_close(handle)
	if not header or not header:find("^SQLite format 3") then
		vim.notify("File bukan SQLite database.", vim.log.levels.WARN)
		return
	end
	if vim.fn.exists(":DBUIToggle") == 2 then
		vim.cmd("DBUI")
		vim.defer_fn(function()
			vim.b.dadbod_connection = M.connection_string(dbpath)
			vim.notify("SQLite: " .. vim.fn.fnamemodify(dbpath, ":t") .. " — siap", vim.log.levels.INFO)
		end, 200)
	else
		vim.notify("Gunakan :DB " .. M.connection_string(dbpath), vim.log.levels.INFO)
	end
end

function M.detect()
	local name = vim.api.nvim_buf_get_name(0)
	if name == "" then
		return false
	end
	local ok, handle = pcall(vim.uv.fs_open, name, "r", 438)
	if not ok or not handle then
		return false
	end
	local header = vim.uv.fs_read(handle, 16, 0)
	vim.uv.fs_close(handle)
	return header and header:find("^SQLite format 3") ~= nil
end

local function is_sqlite(path)
	local ok, handle = pcall(vim.uv.fs_open, path, "r", 438)
	if not ok or not handle then
		return false
	end
	local header = vim.uv.fs_read(handle, 16, 0)
	vim.uv.fs_close(handle)
	return header and header:find("^SQLite format 3") ~= nil
end

local function setup_filetype()
	vim.filetype.add({
		extension = {
			db = "sqlite",
			sqlite = "sqlite",
			sqlite3 = "sqlite",
			sqlitedb = "sqlite",
		},
		filename = {
			["database.sqlite"] = "sqlite",
			["data.db"] = "sqlite",
		},
	})
	local group = vim.api.nvim_create_augroup("sqlite_detect", { clear = true })
	vim.api.nvim_create_autocmd("BufReadPost", {
		group = group,
		pattern = { "*.db", "*.sqlite", "*.sqlite3", "*.sqlitedb" },
		callback = function(args)
			local buf = args.buf
			local path = vim.api.nvim_buf_get_name(buf)
			if not is_sqlite(path) then
				return
			end
			vim.bo[buf].filetype = "sql"
			vim.b[buf].disable_autoformat = true
			vim.b[buf].sqlite_path = path
			vim.defer_fn(function()
				local clients = vim.lsp.get_clients({ name = "sqls", bufnr = buf })
				if #clients > 0 then
					for _, client in ipairs(clients) do
						client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
							sqls = {
								connections = {
									{
										alias = vim.fn.fnamemodify(path, ":t"),
										driver = "sqlite3",
										dataSourceName = path,
									},
								},
							},
						})
						client:notify("workspace/didChangeConfiguration", { settings = client.settings })
					end
				end
			end, 150)
			vim.defer_fn(function()
				local name = vim.fn.fnamemodify(path, ":t")
				vim.notify(
					name .. " — SQLite database.\n:SQLiteOpen   browse di dadbod-ui\n:SQLiteExec   query cepat",
					vim.log.levels.INFO,
					{ title = "SQLite", timeout = 5000 }
				)
			end, 100)
		end,
	})
end

local function setup_tools()
	vim.api.nvim_create_user_command("SQLiteOpen", function(args)
		if args.args and args.args ~= "" then
			M.open(args.args)
		elseif M.detect() then
			M.open()
		else
			local p = vim.fn.input("SQLite database: ", vim.fn.getcwd() .. "/", "file")
			if p ~= "" then
				M.open(p)
			end
		end
	end, { nargs = "?", complete = "file", desc = "Open SQLite database in dadbod-ui" })

	vim.api.nvim_create_user_command("SQLiteExec", function(args)
		if args.args == "" then
			vim.notify("Usage: SQLiteExec <query>", vim.log.levels.ERROR)
			return
		end
		local dbpath = vim.api.nvim_buf_get_name(0)
		if not M.detect() then
			vim.notify("Buffer ini bukan SQLite database.", vim.log.levels.WARN)
			return
		end
		local result = vim.fn.system({ "sqlite3", "-header", "-column", dbpath, args.args })
		if vim.v.shell_error ~= 0 then
			vim.notify("SQLite error: " .. result, vim.log.levels.ERROR)
			return
		end
		vim.cmd("new")
		vim.api.nvim_buf_set_name(0, "sqlite://output")
		vim.bo.buftype = "nofile"
		vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(result, "\n", { plain = true }))
		vim.bo.filetype = "sql"
		vim.bo.modified = false
	end, { nargs = 1, complete = "command", desc = "Execute SQL on current SQLite database" })

	vim.keymap.set("n", "<leader>oS", function()
		local p = vim.fn.input("SQLite database: ", vim.fn.getcwd() .. "/", "file")
		if p ~= "" then
			M.open(p)
		end
	end, { desc = "SQLite: Open Database" })

	vim.keymap.set("n", "<leader>oD", function()
		if M.detect() then
			M.open()
		else
			vim.notify("Bukan SQLite database.", vim.log.levels.WARN)
		end
	end, { desc = "SQLite: Open Current Buffer" })
end

return {
	{
		"tpope/vim-dadbod",
		cmd = "DB",
		init = function()
			setup_filetype()
			setup_tools()
		end,
	},
	{
		"kristijanhusak/vim-dadbod-ui",
		cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
		dependencies = { "tpope/vim-dadbod" },
		keys = {
			{ "<leader>D", "<cmd>DBUIToggle<cr>", desc = "Toggle Database UI" },
		},
		init = function()
			local data_path = vim.fn.stdpath("data")
			vim.g.db_ui_auto_execute_table_helpers = 1
			vim.g.db_ui_save_location = data_path .. "/dadbod_ui"
			vim.g.db_ui_show_database_icon = 0
			vim.g.db_ui_tmp_query_location = data_path .. "/dadbod_ui/tmp"
			vim.g.db_ui_use_nerd_fonts = 0
			vim.g.db_ui_use_nvim_notify = 1
			vim.g.db_ui_execute_on_save = 0
		end,
	},
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			opts.servers = opts.servers or {}
			opts.servers.sqls = vim.tbl_deep_extend("force", opts.servers.sqls or {}, {
				on_new_config = function(new_config, _)
					local buf = vim.api.nvim_get_current_buf()
					if not buf or not vim.api.nvim_buf_is_valid(buf) then
						return
					end
					local dbpath = vim.b[buf].sqlite_path or vim.api.nvim_buf_get_name(buf)
					if dbpath == "" then
						return
					end
					local is_sqlite_ext = vim.endswith(dbpath, ".db")
						or vim.endswith(dbpath, ".sqlite")
						or vim.endswith(dbpath, ".sqlite3")
						or vim.endswith(dbpath, ".sqlitedb")
					if not is_sqlite_ext then
						return
					end
					if not is_sqlite(dbpath) then
						return
					end
					new_config.settings = new_config.settings or {}
					new_config.settings.sqls = new_config.settings.sqls or {}
					new_config.settings.sqls.connections = {
						{
							alias = vim.fn.fnamemodify(dbpath, ":t"),
							driver = "sqlite3",
							dataSourceName = dbpath,
						},
					}
				end,
			})
		end,
	},
}
