local ls = require 'luasnip'
local i = ls.insert_node
local s = ls.snippet
local fmta = require('luasnip.extras.fmt').fmta
local f = ls.function_node

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
