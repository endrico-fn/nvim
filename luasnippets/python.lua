local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt
local rep = require("luasnip.extras").rep

return {
	-- if __name__ == "__main__":
	s("ifmain", fmt([[
def main() -> None:
    {}

if __name__ == "__main__":
    main()
]], { i(1, "pass") })),

	-- Typed Function
	s("def", fmt([[
def {}({}) -> {}:
    """{}"""
    {}
]], { i(1, "name"), i(2, "args"), i(3, "None"), i(4, "Description"), i(5, "pass") })),

	-- Class Method
	s("defm", fmt([[
def {}(self, {}) -> {}:
    {}
]], { i(1, "name"), i(2, "args"), i(3, "None"), i(4, "pass") })),

	-- Try Except
	s("tryc", fmt([[
try:
    {}
except {} as e:
    logger.error(f"Error: {{e}}")
    {}
]], { i(1, "pass"), i(2, "Exception"), i(3, "raise") })),

	-- Dataclass
	s("dclass", fmt([[
from dataclasses import dataclass

@dataclass
class {}:
    {}: {}
]], { i(1, "Name"), i(2, "field"), i(3, "str") })),
}
