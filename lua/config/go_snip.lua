require 'config.util_find_func'
require 'config.util_go_snip'
local ls = require 'luasnip'
local c = ls.choice_node
local d = ls.dynamic_node
local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet
local t = ls.text_node
local fmta = require('luasnip.extras.fmt').fmta
local extras = require 'luasnip.extras'
local rep = extras.rep

ls.add_snippets('go', {
  s(
    'efi', -- error return
    fmta(
      [[
        <choiceNode> <funcName>(<args>)
        if err != nil {
            return <dynamicRet>
        }
      ]],
      {
        choiceNode = c(3, {
          fmta([[<res>, err := ]], { res = i(1, 'res') }),
          t 'err = ',
          t 'err := ',
        }),
        funcName = i(1, 'funcName'),
        args = i(2, 'args'),
        dynamicRet = d(4, Go_ret_vals, { 1 }),
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
      ]],
      {
        dynamicRet = d(1, Go_ret_vals_nearest_func_decl, {}),
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
        processedFuncName = GetLastFuncName { i(1, 'funcName') },
        finish = i(0),
      }
    )
  ),
})

ls.add_snippets('go', {
  s(
    'fn',
    fmta(
      [[
        func <funcName>(<args>) <choiceNode> {
              <body>
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
        body = i(0),
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
                  <body>
          }
      ]],
      {
        Type = i(1, 'Type'),
        inst = f(LowerFirst, { 1 }),
        body = i(0),
      }
    )
  ),
})

ls.add_snippets('go', {
  s(
    'tn',
    fmta(
      [[
          func Test_<Name>(t *testing.T) {
                  <body>
          }
    ]],
      {
        Name = i(1, 'Name'),
        body = i(0),
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
              <body>
        }
      ]],
      {
        funcName = i(1, 'funcName'),
        args = i(2, 'args'),
        body = i(0),
      }
    )
  ),
})

ls.add_snippets('go', {
  s(
    'ene', -- no error
    fmta(
      [[
          <choiceNode>
          require.NoError(t, err)
          <finish>
      ]],
      {
        choiceNode = c(1, {
          fmta([[<val>, err := <funcName>(<args>)]], { val = i(1, 'val'), funcName = i(2, 'funcName'), args = i(3, 'args') }),
          fmta([[err = <funcName>(<args>)]], { funcName = i(1, 'funcName'), args = i(2, 'args') }),
          fmta([[err := <funcName>(<args>)]], { funcName = i(1, 'funcName'), args = i(2, 'args') }),
        }),
        finish = i(0),
      }
    )
  ),
})

ls.add_snippets('go', {
  s(
    'wb',
    fmta(
      [[
            //go:build windows

            package <finish>
        ]],
      {
        finish = i(0),
      }
    )
  ),
})

ls.add_snippets('go', {
  s(
    'cli',
    fmta(
      [[
//go:build windows

package cli

import (
    log "github.com/sirupsen/logrus"
)

func init() {
	var path string
	<cmd>InvokeStr := "<cmd_invoke_str>"
	<cmd>Cmd := &cobra.Command{
		Use:   <cmd>InvokeStr,
		Short: "<short_desc>",
	}
	rootCmd.AddCommand(<cmd>Cmd)
	logging.IniLog()

	<cmd>Cmd.Flags().StringVarP(&path, pathKey, "p", "", "<flag_desc>")

	markFlagsRequired(<cmd>Cmd, pathKey)
	<cmd>Cmd.Run = func(_ *cobra.Command, _ []string) {
		<cmd>CLI()
	}
}

func <cmd>CLI(<finish>
}
      ]],
      {
        cmd_invoke_str = i(1, 'cmd_invoke_str'),
        cmd = f(KebabToCamelCase, { 1 }),
        short_desc = f(ReplaceDashWithSpace, { 1 }),
        flag_desc = i(2, 'flag_description'),
        finish = i(0),
      }
    )
  ),
})
