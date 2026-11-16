local M = {}

function M.get(_, _)
	return {
		HarpoonWindow   = { link = "NormalFloat" },
		HarpoonBorder   = { link = "FloatBorder" },
		HarpoonTitle    = { link = "FloatTitle" },
		HarpoonNormal   = { link = "NormalFloat" },
	}
end

return M
