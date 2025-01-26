local ls = require 'luasnip'
local i = ls.insert_node
local s = ls.snippet
local fmta = require('luasnip.extras.fmt').fmta
local c = ls.choice_node

ls.add_snippets('go', {
  s(
    'tn',
    fmta(
      [[
          func Test_<Name>(t *testing.T) {
                  <finish>
          }
    ]],
      {
        Name = i(1, 'Name'),
        finish = i(0),
      }
    )
  ),
})

ls.add_snippets('go', {
  s(
    'tfn',
    fmta(
      [[
        func <funcName>(t *testing.T, <args>) {
              <finish>
        }
      ]],
      {
        funcName = i(1, 'funcName'),
        args = i(2, 'args'),
        finish = i(0),
      }
    )
  ),
})

ls.add_snippets('go', {
  s(
    'ne', -- no error
    fmta(
      [[
          <choiceNode>
          require.NoError(t, err)
          <finish>
      ]],
      {
        choiceNode = c(1, {
          fmta([[<val>, err := <func>]], { val = i(2, 'val'), func = i(1, 'func') }),
          fmta([[err = <func>]], { func = i(1, 'func') }),
          fmta([[err := <func>]], { func = i(1, 'func') }),
        }),
        finish = i(0),
      }
    )
  ),
})
