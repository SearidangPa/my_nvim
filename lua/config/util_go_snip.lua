local ls = require 'luasnip'
local s = ls.snippet
local i = ls.insert_node
local extras = require 'luasnip.extras'
local rep = extras.rep
local fmta = require('luasnip.extras.fmt').fmta

ls.add_snippets('go', {
  s(
    'cli',
    fmta(
      [[
//go:build windows

package cli

func init() {
	var <flag_var>
	<api1>InvokeStr := "<cmd_invoke_str>"
	<api2>Cmd := &cobra.Command{
		Use:   <apiInvokeStr>InvokeStr,
		Short: "<short_desc>",
	}
	rootCmd.AddCommand(<apiAddCmd>Cmd)
	logging.IniLog()

	<api3>Cmd.Flags().StringVarP(&fp, "path", "p", "", "path of the placeholder to query info")
	<api4>Cmd.Flags().StringVarP(&newParentUUIDstr, "new-parent-uuid", "d", "", "new parent uuid")

	markFlagsRequired(<api5>Cmd, "path")
	<api6>Cmd.Run = func(cmd *cobra.Command, args []string) {
		err := <api7>CLI(fp, newParentUUIDstr)
		logRes(fp, err)
	}
}

func <api7>CLI(<fn_args>) error {
      <finish>
}
      ]],
      {
        api1 = i(1),
        api2 = rep(1),
        api3 = rep(1),
        api4 = rep(1),
        api5 = rep(1),
        api6 = rep(1),
        api7 = rep(1),
        apiAddCmd = rep(1),
        apiInvokeStr = rep(1),

        cmd_invoke_str = i(2, 'cmd_invoke_str'),
        short_desc = i(3, 'short_desc'),
        flag_var = i(4),
        fn_args = i(5),
        finish = i(0),
      }
    )
  ),
})
