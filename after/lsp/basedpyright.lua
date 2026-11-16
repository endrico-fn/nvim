local function strip_funcs(t)
    if type(t) ~= "table" then
        return
    end
    for k, v in pairs(t) do
        if type(v) == "function" then
            t[k] = nil
        elseif type(v) == "table" then
            strip_funcs(v)
        end
    end
end

---@type vim.lsp.Config
return {
    root_markers = {
        "pyproject.toml",
        "uv.lock",
        ".python-version",
        "setup.py",
        "setup.cfg",
        "requirements.txt",
        "Pipfile",
        "pyrightconfig.json",
        ".git",
    },
    before_init = function(_, config)
        strip_funcs(config.settings)
        config.settings = config.settings or {}
        config.settings.python = config.settings.python or {}
        config.settings.python.pythonPath = require("util.python").get_python_path()
    end,
    settings = {
        basedpyright = {
            disableOrganizeImports = true,
            analysis = {
                typeCheckingMode = "standard",
                autoImportCompletions = true,
                autoSearchPaths = true,
                diagnosticMode = "openFilesOnly",
                indexing = false,
                inlayHints = {
                    variableTypes = true,
                    functionReturnTypes = true,
                    parameterNames = "all",
                    callArgumentNames = false,
                },
                diagnosticSeverityOverrides = {
                    reportAny = "warning",
                    reportUnknownVariableType = "warning",
                    reportUnknownMemberType = "warning",
                    reportUnknownParameterType = "warning",
                    reportMissingTypeStubs = "none",
                    reportPrivateUsage = "none",
                    reportUnusedClass = "none",
                    reportUnusedFunction = "none",
                    reportUnusedVariable = "none",
                    reportUnusedImport = "none",
                    reportUnnecessaryTypeIgnoreComment = "warning",
                },
                exclude = {
                    "**/.git",
                    "**/__pycache__",
                    "**/.pytest_cache",
                    "**/.mypy_cache",
                    "**/.ruff_cache",
                    "**/.venv",
                    "**/venv",
                    "**/env",
                    "**/build",
                    "**/dist",
                    "**/node_modules",
                    "**/.uv",
                    "**/__pypackages__",
                    "**/.direnv",
                },
                ignore = { "**/migrations" },
            },
        },
    },
}
