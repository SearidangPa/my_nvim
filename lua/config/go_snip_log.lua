local ls = require 'luasnip'
local i = ls.insert_node
local s = ls.snippet
local fmta = require('luasnip.extras.fmt').fmta
local extras = require 'luasnip.extras'
local rep = extras.rep

ls.add_snippets('go', {
  s(
    'lg2',
    fmta(
      [[
        logEntry := log.WithFields(log.Fields{"<key1>": <val1>, "<key2>": <val2>})
        <finish>
      ]],
      {
        val1 = i(1, ''),
        key1 = rep(1),
        val2 = i(2, ''),
        key2 = rep(2),
        finish = i(0),
      }
    )
  ),
})
