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

local function strip_parentheses_and_content(args)
  local func_name = args[1][1] -- Get the text from the first input node
  return func_name:gsub('%b()', '') -- Remove everything inside balanced parentheses and the parentheses themselves
end

ls.add_snippets('go', {
  s(
    'efi',
    fmt(
      [[
        {}, err := {}
        if err != nil {{
          return nil, fmt.Errorf("failed to {}, err: %v", err)
        }}
        {}
      ]],
      {
        i(1, 'resultName'),
        i(2, 'funcName'),
        f(strip_parentheses_and_content, { 2 }),
        i(0),
      }
    )
  ),
})

ls.add_snippets('go', {
  s(
    'tne', -- test no error
    fmt(
      [[
        {}, err := {}
        require.NoError(t, err)
        {}
      ]],
      {
        i(1, 'resultName'),
        i(2, 'funcName'),
        i(0),
      }
    )
  ),
})

ls.add_snippets('go', {
  s(
    'test',
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
  s('strf', {
    t 'func (',
    f(function(args)
      -- Get the input and lowercase the first character
      local input = args[1][1] or ''
      local lower = input:sub(1, 1):lower() .. input:sub(2)
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
