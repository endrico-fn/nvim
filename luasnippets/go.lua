local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

return {
	-- Main + func dasar
	s("main", fmt("package main\n\nimport \"fmt\"\n\nfunc main() {{\n\t{}\n}}", { i(0) })),
	s("func", fmt("func {}({}) {} {{\n\t{}\n}}", { i(1, "name"), i(2, ""), i(3, ""), i(0) })),
	s("meth", fmt("func ({} {}) {}({}) {} {{\n\t{}\n}}", { i(1, "r"), i(2, "Type"), i(3, "name"), i(4, ""), i(5, ""), i(0) })),

	-- Error handling idiomatik
	s("ife", fmt("if err != nil {{\n\t{}\n}}", { i(0, "return err") })),
	s("ifew", fmt('if err != nil {{\n\treturn fmt.Errorf("{}: %w", err)\n}}', { i(1, "context") })),

	-- Struct + interface
	s("struct", fmt("type {} struct {{\n\t{}\n}}", { i(1, "Name"), i(0) })),
	s("iface", fmt("type {} interface {{\n\t{}\n}}", { i(1, "Name"), i(0) })),

	-- Goroutine / channel / context
	s("go", fmt("go func() {{\n\t{}\n}}()", { i(0) })),
	s("chan", fmt("ch := make(chan {}, {})\n{}", { i(1, "int"), i(2, "0"), i(0) })),
	s("ctx", fmt("ctx, cancel := context.WithTimeout(context.Background(), {})\ndefer cancel()\n{}", { i(1, "5*time.Second"), i(0) })),

	-- Test + bench + example (hemat: tanpa testify, stdlib saja)
	s("test", fmt("func Test{}(t *testing.T) {{\n\t{}\n}}", { i(1, "Name"), i(0) })),
	s(
		"testable",
		fmt(
			[[
func Test{}(t *testing.T) {{
	tests := []struct {{
		name {}
		want {}
	}}{{
		{{"case1", "want1"}},
	}}
	for _, tt := range tests {{
		t.Run(tt.name, func(t *testing.T) {{
			{}
		}})
	}}
}}
]],
			{ i(1, "Name"), i(2, "string"), i(3, "string"), i(0) }
		)
	),
	s("bench", fmt("func Benchmark{}(b *testing.B) {{\n\tfor i := 0; i < b.N; i++ {{\n\t\t{}\n\t}}\n}}", { i(1, "Name"), i(0) })),

	-- Import block
	s("imp", fmt('import (\n\t"{}"\n)', { i(1, "fmt") })),
}
