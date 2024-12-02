local ls = require 'luasnip'
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

ls.add_snippets('go', {
  s('winb', {
    t '//go:build windows',
    t { '', '' }, -- Line break with tab indentation
    t { '', 'package ' }, -- Static text for the return statement
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
  s('fn', {
    t 'func ',
    i(1, 'name'),
    t '(',
    i(2),
    t ') ',
    i(3, 'returnType'),
    t { ' {', '\t' },
    i(0),
    t { '', '}' },
  }),
})

ls.add_snippets('go', {
  s('strf', {
    t 'func (',
    i(1, 'receiver'),
    t ' ',
    i(2, 'Type'),
    t ') String() string {',
    t { '', '\t' }, -- Indentation for the method body
    i(0), -- Placeholder to start writing the method body
    t { '', '}' },
  }),
})
