local ls = require 'luasnip'
local fmt = require('luasnip.extras.fmt').fmt
local i = ls.insert_node

ls.add_snippets('markdown', {
  ls.snippet(
    'dp',
    fmt(
      [[
    <details\>
      <summary>{sum}</summary>
      {finish}
    </details>
    ]],
      {
        sum = i(1, 'Summary'),
        finish = i(0),
      }
    )
  ),
})
