local ls = require 'luasnip'
local s = ls.snippet
local t = ls.text_node
local c = ls.choice_node
local i = ls.insert_node
local f = ls.function_node
local extras = require 'luasnip.extras'
local rep = extras.rep
local fmt = require('luasnip.extras.fmt').fmt

ls.add_snippets('go', {
  s('winb', {
    t { '//go:build windows', '', 'package ' },
    i(0),
  }),
})

ls.add_snippets('go', {
  s('ifnil', {
    t 'if err != nil {',
    t { '', '\t' }, -- Line break with tab indentation
    t 'return nil, err', -- Static text for the return statement
    t { '', '}' }, -- Closing brace on a new line
  }),
})

ls.add_snippets('go', {
  s('iferr', {
    t 'if err != nil {',
    t { '', '\t' }, -- Line break with tab indentation
    t 'return err', -- Static text for the return statement
    t { '', '}' }, -- Closing brace on a new line
  }),
})

ls.add_snippets('go', {
  s('iffat', {
    t 'if err != nil {',
    t { '', '\t' }, -- Line break with tab indentation
    t 'log.Fatal(err)', -- Static text for the return statement
    t { '', '}' }, -- Closing brace on a new line
  }),
})

ls.add_snippets('go', {
  s(
    'fn',
    fmt(
      [[
         func {}({}) {} {{
             {}
         }}
      ]],
      {
        i(1, 'funcName'),
        i(2, ''),
        i(3, 'returnType'),
        i(0),
      }
    )
  ),
})

ls.add_snippets('go', {
  s(
    'efi',
    fmt(
      [[
    {}, err := {}({})
    if err != nil {{
      return nil, fmt.Errorf("failed to {}, err: %v", err)
    }}
    {}
    ]],
      {
        i(1, ''),
        i(2, 'funcName'),
        i(3, 'args'),
        rep(2),
        i(0),
      }
    )
  ),
})

ls.add_snippets('go', {
  s(
    'gt',
    fmt(
      [[
    func Test_{}(t *testing.T) {{
        {}
    }}
    ]],
      {
        i(1, 'name'),
        i(0),
      }
    )
  ),
})

ls.add_snippets('go', {
  s(
    'trig',
    c(1, {
      t 'Ugh boring, a text node',
      i(nil, 'At least I can edit something now...'),
      f(function()
        return 'Still only counts as text!!'
      end, {}),
    })
  ),
})

ls.add_snippets('go', {
  s('strf', {
    t 'func (',
    f(function(args)
      -- Get the input and lowercase the first character
      local input = args[1][1] or ''
      local lower = input:sub(1, 1):lower() .. input:sub(2)
      print(lower)
      return lower
    end, { 1 }),
    t ' ',
    i(1, 'Type'), -- Input node for the type
    t ') String() string {',
    t { '', '\t' }, -- Indentation for the method body
    i(0), -- Placeholder to start writing the method body
    t { '', '}' },
  }),
})
