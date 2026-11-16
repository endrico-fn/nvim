local M = {}

M.bg = "#000000"
M.fg = "#ffffff"

local function rgb(hex)
    return { tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16) }
end

function M.blend(foreground, alpha, background)
    alpha = type(alpha) == "string" and (tonumber(alpha, 16) / 0xff) or alpha
    local bg = rgb(background)
    local fg = rgb(foreground)
    local blend = function(i)
        local ret = (alpha * fg[i] + ((1 - alpha) * bg[i]))
        return math.floor(math.min(math.max(0, ret), 255) + 0.5)
    end
    return string.format("#%02x%02x%02x", blend(1), blend(2), blend(3))
end

function M.blend_bg(hex, amount, bg)
    return M.blend(hex, amount, bg or M.bg)
end

function M.blend_fg(hex, amount, fg)
    return M.blend(hex, amount, fg or M.fg)
end

function M.brighten(color, lightness_amount, saturation_amount)
    lightness_amount = lightness_amount or 0.05
    saturation_amount = saturation_amount or 0.2
    local hsluv = require("theme.cryptnight.hsluv")
    local hsl = hsluv.hex_to_hsluv(color)
    hsl[3] = math.min(hsl[3] + (lightness_amount * 100), 100)
    hsl[2] = math.min(hsl[2] + (saturation_amount * 100), 100)
    return hsluv.hsluv_to_hex(hsl)
end

function M.darken(hex, amount, bg)
    return M.blend(hex, amount, bg or M.bg)
end

function M.lighten(hex, amount, fg)
    return M.blend(hex, amount, fg or M.fg)
end

function M.desaturate(color, amount)
    local hsluv = require("theme.cryptnight.hsluv")
    local hsl = hsluv.hex_to_hsluv(color)
    hsl[2] = math.max(hsl[2] - (amount * 100), 0)
    return hsluv.hsluv_to_hex(hsl)
end

function M.invert(color)
    if type(color) == "table" then
        for k, v in pairs(color) do
            color[k] = M.invert(v)
        end
    elseif type(color) == "string" then
        local hsluv = require("theme.cryptnight.hsluv")
        if color ~= "NONE" then
            local hsl = hsluv.hex_to_hsluv(color)
            hsl[3] = 100 - hsl[3]
            return hsluv.hsluv_to_hex(hsl)
        end
    end
    return color
end

function M.resolve(groups)
    for _, hl in pairs(groups) do
        if type(hl.style) == "table" then
            for k, v in pairs(hl.style) do
                hl[k] = v
            end
            hl.style = nil
        end
    end
    return groups
end

function M.template(str, table)
    return (
        str:gsub("($%b{})", function(w)
            return vim.tbl_get(table, unpack(vim.split(w:sub(3, -2), ".", { plain = true }))) or w
        end)
    )
end

M.cache = {}

function M.cache.file(key)
    return vim.fn.stdpath("cache") .. "/cryptnight-" .. key .. ".json"
end

function M.cache.read(key)
    local ok, ret = pcall(function()
        return vim.json.decode(
            M.read(M.cache.file(key)),
            { luanil = { object = true, array = true } }
        )
    end)
    return ok and ret or nil
end

function M.cache.write(key, data)
    pcall(M.write, M.cache.file(key), vim.json.encode(data))
end

function M.cache.clear()
    for _, style in ipairs({ "storm", "neutral" }) do
        vim.uv.fs_unlink(M.cache.file(style))
    end
end

function M.read(file)
    local fd = assert(io.open(file, "r"))
    local data = fd:read("*a")
    fd:close()
    return data
end

function M.write(file, contents)
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":h"), "p")
    local fd = assert(io.open(file, "w+"))
    fd:write(contents)
    fd:close()
end

return M
