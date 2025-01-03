local ls = require 'luasnip'
local c = ls.choice_node
local f = ls.function_node
local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node
local extras = require 'luasnip.extras'
local rep = extras.rep
local fmta = require('luasnip.extras.fmt').fmta

local function kebabToCamelCase(args)
  local input = args[1][1]
  print('input' .. input)
  local parts = vim.split(input, '-', { plain = true })
  for index = 2, #parts do
    parts[index] = parts[index]:sub(1, 1):upper() .. parts[index]:sub(2)
  end
  return table.concat(parts, '')
end

local function parseJoin(args)
  local input = args[1][1]
  local parts = vim.split(input, '-', { plain = true })
  return table.concat(parts, ' ')
end

ls.add_snippets('go', {
  s(
    'iffat',
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
    'cli',
    fmta(
      [[
//go:build windows

package cli

import (
    log "github.com/sirupsen/logrus"
)

func init() {
	var <flag_var>, userID string
	<apiInvoke>InvokeStr := "<cmd_invoke_str>"
	<apiInit>Cmd := &cobra.Command{
		Use:   <apiUse>InvokeStr,
		Short: "<short_desc>",
	}
	rootCmd.AddCommand(<apiAddCmd>Cmd)
	logging.IniLog()

	<apiFlag>Cmd.Flags().StringVarP(&userID, "user", "u", "", "user id")

	markFlagsRequired(<apiMarkFlag>Cmd, <requiredFlag>)
	<apiRun>Cmd.Run = func(_ *cobra.Command, _ []string) {
		<apiCall>CLI(<fn_args_call>)
	}
}

func <apiImplement>CLI(<fn_args>) {
      <choiceNode>
      if err != nil {
          log.Fatalf(<errFmt>)
      }
      <finish>
}
      ]],
      {
        apiInvoke = c(2, {
          f(kebabToCamelCase, { 1 }),
          i(2, ''),
        }),
        apiInit = rep(2),
        apiUse = rep(2),
        apiAddCmd = rep(2),
        apiFlag = rep(2),
        apiMarkFlag = rep(2),
        apiRun = rep(2),
        apiCall = rep(2),
        apiImplement = rep(2),

        cmd_invoke_str = i(1, 'cmd_invoke_str'),
        short_desc = c(3, {
          f(parseJoin, { 1 }),
          i(1, 'short_desc'),
        }),
        flag_var = i(4),
        requiredFlag = i(5),

        choiceNode = c(6, {
          fmta([[<val>, err := <funcName>]], { val = i(1, 'val'), funcName = i(2, 'funcName') }),
          fmta([[err := <funcName>]], { funcName = i(1, 'funcName') }),
        }),
        fn_args = i(7),
        fn_args_call = i(8),
        errFmt = i(9),
        finish = i(0),
      }
    )
  ),
})

ls.add_snippets('go', {
  s(
    'ef', -- error fatal
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
    'test_new',
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
    'test_init_file',
    fmta(
      [[
          func Test_<Name>(t *testing.T) {
                  tr := initTestResource(t, withConnectSyncRoot())
                  defer tr.cleanUp()
                  f1 := "file1.txt"
                  fp := filepath.Join(tr.syncRootPath, f1)
                  entryUUID := createAFilePlaceholderUnderRoot(tr, t, f1)
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
    'test_fn',
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
    'ne', -- no error
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
