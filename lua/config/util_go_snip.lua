local ls = require 'luasnip'
local c = ls.choice_node
local f = ls.function_node
local s = ls.snippet
local i = ls.insert_node
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

local function reverseAndJoin(args)
  local input = args[1][1]
  local parts = vim.split(input, '-', { plain = true })
  local reversedParts = {}
  for i = #parts, 1, -1 do
    table.insert(reversedParts, parts[i])
  end
  return table.concat(reversedParts, ' ')
end

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
	<apiRun>Cmd.Run = func(cmd *cobra.Command, args []string) {
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
          f(reverseAndJoin, { 1 }),
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
