require 'config.util_find_func'
require 'config.util_go_snip'
local ls = require 'luasnip'
local c = ls.choice_node
local d = ls.dynamic_node
local i = ls.insert_node
local s = ls.snippet
local f = ls.function_node
local t = ls.text_node
local fmta = require('luasnip.extras.fmt').fmta
local extras = require 'luasnip.extras'
local rep = extras.rep

ls.add_snippets('go', {
  s(
    'efi', -- error func if
    fmta(
      [[
        <choiceNode> <funcName>(<args>)
        if err != nil {
            return <dynamicRet>
        }
        <finish>
      ]],
      {
        choiceNode = c(3, {
          fmta([[<res>, err := ]], { res = i(1, 'res') }),
          t 'err = ',
          t 'err := ',
        }),
        funcName = i(1, 'funcName'),
        args = i(2, ''),
        dynamicRet = d(4, Go_ret_vals, { 1 }),
        finish = i(0),
      }
    )
  ),
})

ls.add_snippets('go', {
  s(
    'ife',
    fmta(
      [[
        if err != nil {
            return <dynamicRet>
        }
        <finish>
      ]],
      {
        dynamicRet = d(1, Go_ret_vals_nearest_func_decl, {}),
        finish = i(0),
      }
    )
  ),
})

ls.add_snippets('go', {
  s(
    'ifa',
    fmta(
      [[
      if err != nil{
        log.Fatalf("failed to <finish>
      }
      ]],
      {
        finish = i(0),
      }
    )
  ),
})

ls.add_snippets('go', {
  s(
    'efa', -- error fatal
    fmta(
      [[
        <choiceNode> <funcName>(<args>)
        if err != nil {
            log.Fatalf("failed to <processedFuncName>, err: %v", err)
        }
        <finish>
      ]],
      {
        choiceNode = c(3, {
          fmta([[<res>, err := ]], { res = i(1, 'res') }),
          t 'err = ',
          t 'err := ',
        }),
        funcName = i(1, 'funcName'),
        args = i(2, 'args'),
        processedFuncName = f(GetLastFuncName , { 1 }),
        finish = i(0),
      }
    )
  ),
})
