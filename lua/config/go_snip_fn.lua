local ls = require 'luasnip'
local i = ls.insert_node
local s = ls.snippet
local c = ls.choice_node
local f = ls.function_node
local t = ls.text_node
local fmta = require('luasnip.extras.fmt').fmta
local extras = require 'luasnip.extras'
local rep = extras.rep

ls.add_snippets('go', {
  s(
    'fn',
    fmta(
      [[
        func <funcName>(<args>) <choiceNode> {
              <finish>
        }
      ]],
      {
        funcName = i(1, 'funcName'),
        args = i(2, 'args'),
        choiceNode = c(3, {
          t 'error',
          t ' ',
          i(nil, 'returnType'),
        }),
        finish = i(0),
      }
    )
  ),
})

ls.add_snippets('go', {
  s(
    'strf',
    fmta(
      [[
          func (<inst> *<Type>) String() string {
                  <finish>
          }
      ]],
      {
        Type = i(1, 'Type'),
        inst = f(LowerFirst, { 1 }),
        finish = i(0),
      }
    )
  ),
})
