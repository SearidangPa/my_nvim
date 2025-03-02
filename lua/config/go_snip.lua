require 'config.util_find_func'
require 'config.util_go_snip'
local ls = require 'luasnip'
local c = ls.choice_node
local d = ls.dynamic_node
local i = ls.insert_node
local s = ls.snippet
local f = ls.function_node
local t = ls.text_node
local extras = require 'luasnip.extras'
local rep = extras.rep

local fmta = require('luasnip.extras.fmt').fmta

--- === snip if ===
if vim.fn.has 'win' == 1 then
  ls.add_snippets('go', {
    s(
      'rif', -- error func if
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
          dynamicRet = d(4, Go_ret_vals, { { 1 } }),
          finish = i(0),
        }
      )
    ),
  })
else
  ls.add_snippets('go', {
    s(
      'rif', -- error func if
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
end

ls.add_snippets('go', {
  s(
    'ife',
    fmta(
      [[
        if err != nil {
            return <funcName>
        }
        <finish>
      ]],
      {
        funcName = d(1, Go_ret_vals_nearest_func_decl, {}),
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
    'rfa', -- error fatal
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
        args = i(2),
        processedFuncName = f(GetLastFuncName, { 1 }),
        finish = i(0),
      }
    )
  ),
})

--- === snip func ===
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
        inst = f(GetInstName, { 1 }),
        finish = i(0),
      }
    )
  ),
})

--- === snip at packages level ===
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
		<cmd>CLI(path)
	}
}

func <cmd>CLI(path string){
      <finish>
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

--- === snip test ===
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
        func <funcName>(t *testing.T, <finish>) {
        }
      ]],
      {
        funcName = i(1, 'funcName'),
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

ls.add_snippets('go', {
  s(
    'at', -- annotation test
    fmta(
      [[
        tests <testPurpose>
        // setup: <setup>
        // assert that: <condition>
      ]],
      {
        testPurpose = i(1),
        setup = i(2),
        condition = i(3),
      }
    )
  ),
})

local lg_choice_node_1 = {
  fmta(
    [[
    logEntry := logging.UserField(<userField>).WithFields(log.Fields{
      "<fields>": <values>, <finish>}
  ]],
    {
      userField = i(1),
      fields = f(GetLastFuncName, { 2 }),
      values = i(2),
      finish = i(0),
    }
  ),
}

ls.add_snippets('go', {
  s(
    'lg', -- trigger word
    fmta(
      [[
        <choiceNode>
      ]],
      {
        choiceNode = c(1, {
          lg_choice_node_1,
        }),
      }
    )
  ),
})
