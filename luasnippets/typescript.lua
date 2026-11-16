local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt
local rep = require("luasnip.extras").rep

return {
    -- Console log variable (smart)
    s("con", fmt([[console.log('{} =', {});]], { i(1, "var"), rep(1) })),

    -- Async Arrow Function
    s(
        "afn",
        fmt(
            [[
const {} = async ({}) => {{
	{}
}};
]],
            { i(1, "name"), i(2, "params"), i(3, "// TODO") }
        )
    ),

    -- Interface
    s(
        "inter",
        fmt(
            [[
export interface {} {{
	{}
}}
]],
            { i(1, "Name"), i(2, "prop: string;") }
        )
    ),

    -- Try Catch block
    s(
        "tryc",
        fmt(
            [[
try {{
	{}
}} catch (error) {{
	console.error('{} error:', error);
	{}
}}
]],
            { i(1, "// code"), i(2, "Action"), i(3, "throw error;") }
        )
    ),

    -- SvelteKit Server Load Function (Bonus for your stack)
    s(
        "skload",
        fmt(
            [[
import type {{ PageServerLoad }} from './$types';

export const load: PageServerLoad = async ({{ params, fetch }}) => {{
	{}
	return {{
		{}: {}
	}};
}};
]],
            { i(1, "// fetch data"), i(2, "key"), i(3, "value") }
        )
    ),
}
